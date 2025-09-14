//
//  HomeAssistantClient.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "HomeAssistantClient.h"

@interface HomeAssistantClient ()
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
<NSURLSessionWebSocketDelegate>
#endif
@property (nonatomic, strong) NSURLSession *urlSession;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
@property (nonatomic, strong) NSURLSession *webSocketSession;
@property (nonatomic, strong) NSURLSessionWebSocketTask *webSocketTask;
#endif
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) BOOL webSocketConnected;
@property (nonatomic, strong) NSTimer *autoRefreshTimer;
@property (nonatomic, strong) NSTimer *reconnectTimer;
@property (nonatomic, assign) NSInteger websocketId;
@property (nonatomic, strong) NSMutableDictionary *entitiesState;
@end

@implementation HomeAssistantClient

+ (instancetype)sharedClient {
    static HomeAssistantClient *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30.0;
        config.timeoutIntervalForResource = 60.0;
        _urlSession = [NSURLSession sessionWithConfiguration:config];
        _isConnected = NO;
        _webSocketConnected = NO;
        _autoRefreshEnabled = YES;
        
        // Load refresh interval from user defaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _autoRefreshInterval = [defaults doubleForKey:@"ha_auto_refresh_interval"];
        if (_autoRefreshInterval <= 0) {
            _autoRefreshInterval = 2.0; // Default 2 seconds for fast updates
        }
        
        _websocketId = 1;
        _entitiesState = [NSMutableDictionary dictionary];
        
        // Create WebSocket session only on iOS 13+
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
        if (@available(iOS 13.0, *)) {
            NSURLSessionConfiguration *wsConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            _webSocketSession = [NSURLSession sessionWithConfiguration:wsConfig delegate:self delegateQueue:nil];
        }
#endif
    }
    return self;
}

- (void)connectWithBaseURL:(NSString *)baseURL accessToken:(NSString *)accessToken {
    self.baseURL = baseURL;
    self.accessToken = accessToken;
    
    // Test connection by fetching states
    [self testConnection];
}

- (void)disconnect {
    // Stop auto refresh
    [self stopAutoRefresh];
    
    // Disconnect WebSocket
    [self disconnectWebSocket];
    
    self.isConnected = NO;
    if ([self.delegate respondsToSelector:@selector(homeAssistantClientDidDisconnect:)]) {
        [self.delegate homeAssistantClientDidDisconnect:self];
    }
}

- (void)testConnection {
    NSString *urlString = [NSString stringWithFormat:@"%@/api/states", self.baseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.isConnected = NO;
                if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
                    [self.delegate homeAssistantClient:self didFailWithError:error];
                }
                return;
            }
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                self.isConnected = YES;
                if ([self.delegate respondsToSelector:@selector(homeAssistantClientDidConnect:)]) {
                    [self.delegate homeAssistantClientDidConnect:self];
                }
                
                // Parse and deliver states
                NSError *jsonError;
                NSArray *states = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                if (!jsonError && [states isKindOfClass:[NSArray class]]) {
                    // Update internal state tracking
                    [self updateEntitiesState:states];
                    
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didReceiveStates:)]) {
                        [self.delegate homeAssistantClient:self didReceiveStates:states];
                    }
                    
                    // Start real-time updates
                    [self startRealTimeUpdates];
                }
            } else {
                self.isConnected = NO;
                NSError *httpError = [NSError errorWithDomain:@"HomeAssistantError" 
                                                         code:httpResponse.statusCode 
                                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP Error %ld", (long)httpResponse.statusCode]}];
                if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
                    [self.delegate homeAssistantClient:self didFailWithError:httpError];
                }
            }
        });
    }];
    
    [task resume];
}

- (void)fetchStates {
    if (!self.isConnected) {
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/api/states", self.baseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
                    [self.delegate homeAssistantClient:self didFailWithError:error];
                }
                return;
            }
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                NSError *jsonError;
                NSArray *states = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                if (!jsonError && [states isKindOfClass:[NSArray class]]) {
                    // Update internal state tracking
                    [self updateEntitiesState:states];
                    
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didReceiveStates:)]) {
                        [self.delegate homeAssistantClient:self didReceiveStates:states];
                    }
                }
            } else {
                NSError *httpError = [NSError errorWithDomain:@"HomeAssistantError" 
                                                         code:httpResponse.statusCode 
                                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP Error %ld", (long)httpResponse.statusCode]}];
                if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
                    [self.delegate homeAssistantClient:self didFailWithError:httpError];
                }
            }
        });
    }];
    
    [task resume];
}

- (void)callService:(NSString *)domain service:(NSString *)service entityId:(NSString *)entityId {
    if (!self.isConnected) {
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/api/services/%@/%@", self.baseURL, domain, service];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *requestBody = @{@"entity_id": entityId};
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:&jsonError];
    
    if (!jsonError) {
        [request setHTTPBody:jsonData];
        
        NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
                        [self.delegate homeAssistantClient:self didFailWithError:error];
                    }
                }
                // Refresh states after service call with a much shorter delay for better responsiveness
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([self serviceCallDelay] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self fetchStates];
                });
            });
        }];
        
        [task resume];
    }
}

- (void)callClimateService:(NSString *)service entityId:(NSString *)entityId temperature:(float)temperature {
    if (!self.isConnected) {
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/api/services/climate/%@", self.baseURL, service];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *requestBody = @{
        @"entity_id": entityId,
        @"temperature": @(temperature)
    };
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:&jsonError];
    
    if (!jsonError) {
        [request setHTTPBody:jsonData];
        
        NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
                        [self.delegate homeAssistantClient:self didFailWithError:error];
                    }
                }
                // Refresh states after service call with a much shorter delay for better responsiveness
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([self serviceCallDelay] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self fetchStates];
                });
            });
        }];
        
        [task resume];
    }
}

#pragma mark - Real-time Updates

- (void)startRealTimeUpdates {
    // Try WebSocket first for best real-time performance if enabled
    if ([self isWebSocketEnabled]) {
        [self connectWebSocket];
    }
    
    // Start auto refresh as fallback
    [self startAutoRefresh];
}

- (void)startAutoRefresh {
    if (!self.autoRefreshEnabled || self.autoRefreshTimer) {
        return;
    }
    
    self.autoRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.autoRefreshInterval
                                                             target:self
                                                           selector:@selector(autoRefreshTimerFired:)
                                                           userInfo:nil
                                                            repeats:YES];
}

- (void)stopAutoRefresh {
    if (self.autoRefreshTimer) {
        [self.autoRefreshTimer invalidate];
        self.autoRefreshTimer = nil;
    }
}

- (void)autoRefreshTimerFired:(NSTimer *)timer {
    if (self.isConnected && !self.webSocketConnected) {
        // Only fetch via HTTP if WebSocket is not connected
        [self fetchStates];
    }
}

- (void)connectWebSocket {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        if (self.webSocketTask) {
            return; // Already connecting or connected
        }
        
        if (!self.webSocketSession) {
            NSLog(@"WebSocket session not available");
            return;
        }
        
        // Try to construct WebSocket URL
        NSString *wsURL = [self.baseURL stringByReplacingOccurrencesOfString:@"http://" withString:@"ws://"];
        wsURL = [wsURL stringByReplacingOccurrencesOfString:@"https://" withString:@"wss://"];
        wsURL = [wsURL stringByAppendingString:@"/api/websocket"];
        
        NSURL *url = [NSURL URLWithString:wsURL];
        if (!url) {
            NSLog(@"Failed to create WebSocket URL from: %@", self.baseURL);
            return;
        }
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        self.webSocketTask = [self.webSocketSession webSocketTaskWithRequest:request];
        [self.webSocketTask resume];
        
        // Start receiving messages
        [self receiveWebSocketMessage];
    } else {
        NSLog(@"WebSocket not available on iOS < 13.0, using HTTP polling only");
    }
#else
    NSLog(@"WebSocket not available on iOS < 13.0, using HTTP polling only");
#endif
}

- (void)disconnectWebSocket {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        if (self.webSocketTask) {
            [self.webSocketTask cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure reason:nil];
            self.webSocketTask = nil;
        }
    }
#endif
    self.webSocketConnected = NO;
    
    // Stop reconnection timer
    if (self.reconnectTimer) {
        [self.reconnectTimer invalidate];
        self.reconnectTimer = nil;
    }
}

- (void)receiveWebSocketMessage {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        if (!self.webSocketTask) return;
        
        [self.webSocketTask receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage *message, NSError *error) {
            if (error) {
                NSLog(@"WebSocket receive error: %@", error.localizedDescription);
                return;
            }
            
            if (message.type == NSURLSessionWebSocketMessageTypeString) {
                [self handleWebSocketMessage:message.string];
            }
            
            // Continue receiving messages
            [self receiveWebSocketMessage];
        }];
    }
#endif
}

- (void)handleWebSocketMessage:(NSString *)message {
    NSError *error;
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error || !json) {
        NSLog(@"Failed to parse WebSocket message: %@", error.localizedDescription);
        return;
    }
    
    NSString *type = json[@"type"];
    
    if ([type isEqualToString:@"auth_required"]) {
        // Send authentication
        [self sendWebSocketAuth];
    } else if ([type isEqualToString:@"auth_ok"]) {
        // Authentication successful, subscribe to state changes
        self.webSocketConnected = YES;
        [self subscribeToStateChanges];
    } else if ([type isEqualToString:@"auth_invalid"]) {
        NSLog(@"WebSocket authentication failed");
        [self disconnectWebSocket];
    } else if ([type isEqualToString:@"event"]) {
        [self handleStateChangeEvent:json];
    }
}

- (void)sendWebSocketAuth {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        if (!self.webSocketTask) return;
        
        NSDictionary *authMessage = @{
            @"type": @"auth",
            @"access_token": self.accessToken
        };
        
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:authMessage options:0 error:&error];
        if (!error) {
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSURLSessionWebSocketMessage *message = [[NSURLSessionWebSocketMessage alloc] initWithString:jsonString];
            [self.webSocketTask sendMessage:message completionHandler:^(NSError *error) {
                if (error) {
                    NSLog(@"Failed to send auth message: %@", error.localizedDescription);
                }
            }];
        }
    }
#endif
}

- (void)subscribeToStateChanges {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        if (!self.webSocketTask) return;
        
        NSDictionary *subscribeMessage = @{
            @"id": @(self.websocketId++),
            @"type": @"subscribe_events",
            @"event_type": @"state_changed"
        };
        
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:subscribeMessage options:0 error:&error];
        if (!error) {
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSURLSessionWebSocketMessage *message = [[NSURLSessionWebSocketMessage alloc] initWithString:jsonString];
            [self.webSocketTask sendMessage:message completionHandler:^(NSError *error) {
                if (error) {
                    NSLog(@"Failed to send subscribe message: %@", error.localizedDescription);
                }
            }];
        }
    }
#endif
}

- (void)handleStateChangeEvent:(NSDictionary *)eventData {
    NSDictionary *event = eventData[@"event"];
    if (!event) return;
    
    NSDictionary *newState = event[@"data"][@"new_state"];
    if (!newState) return;
    
    // Update internal state tracking
    NSString *entityId = newState[@"entity_id"];
    if (entityId) {
        self.entitiesState[entityId] = newState;
        
        // Notify delegate of the individual state change
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didReceiveStateChange:)]) {
                [self.delegate homeAssistantClient:self didReceiveStateChange:newState];
            }
        });
    }
}

- (void)updateEntitiesState:(NSArray *)states {
    for (NSDictionary *state in states) {
        NSString *entityId = state[@"entity_id"];
        if (entityId) {
            self.entitiesState[entityId] = state;
        }
    }
}

- (NSTimeInterval)serviceCallDelay {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double delay = [defaults doubleForKey:@"ha_service_call_delay"];
    return (delay > 0) ? delay : 0.3; // Default 0.3 seconds
}

- (BOOL)isWebSocketEnabled {
    // First check if WebSocket APIs are available (iOS 13+)
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:@"ha_websocket_enabled"]) {
            return [defaults boolForKey:@"ha_websocket_enabled"];
        }
        return YES; // Default enabled on supported iOS versions
    }
#endif
    return NO; // WebSocket not available on iOS < 13
}

- (BOOL)isWebSocketAvailable {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        return YES;
    }
#endif
    return NO;
}

#pragma mark - NSURLSessionWebSocketDelegate

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didOpenWithProtocol:(NSString *)protocol {
    if (@available(iOS 13.0, *)) {
        NSLog(@"WebSocket connected");
    }
}

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(NSData *)reason {
    if (@available(iOS 13.0, *)) {
        NSLog(@"WebSocket disconnected with code: %ld", (long)closeCode);
        self.webSocketConnected = NO;
        self.webSocketTask = nil;
        
        // Try to reconnect after a delay if we were previously connected
        if (self.isConnected && closeCode != NSURLSessionWebSocketCloseCodeNormalClosure) {
            self.reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                   target:self
                                                                 selector:@selector(reconnectWebSocket:)
                                                                 userInfo:nil
                                                                  repeats:NO];
        }
    }
}
#endif

- (void)reconnectWebSocket:(NSTimer *)timer {
    self.reconnectTimer = nil;
    if (self.isConnected) {
        [self connectWebSocket];
    }
}

@end