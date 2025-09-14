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
@property (nonatomic, assign) NSTimeInterval webSocketReconnectDelay;
@property (nonatomic, assign) NSInteger reconnectAttempts;
@property (nonatomic, strong) NSTimer *heartbeatTimer;
@property (nonatomic, assign) BOOL awaitingHeartbeatResponse;
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
        
        // Load refresh interval from user defaults with faster default
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _autoRefreshInterval = [defaults doubleForKey:@"ha_auto_refresh_interval"];
        if (_autoRefreshInterval <= 0) {
            _autoRefreshInterval = 1.0; // Faster default: 1 second for better responsiveness
        }
        
        _websocketId = 1;
        _entitiesState = [NSMutableDictionary dictionary];
        _webSocketReconnectDelay = 1.0; // Start with 1 second delay
        _reconnectAttempts = 0;
        _awaitingHeartbeatResponse = NO;
        
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
    
    // Stop heartbeat
    [self stopWebSocketHeartbeat];
    
    // Disconnect WebSocket
    [self disconnectWebSocket];
    
    self.isConnected = NO;
    if ([self.delegate respondsToSelector:@selector(homeAssistantClientDidDisconnect:)]) {
        [self.delegate homeAssistantClientDidDisconnect:self];
    }
}

- (BOOL)isWebSocketConnected {
    return self.webSocketConnected;
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
        NSError *error = [NSError errorWithDomain:@"HomeAssistantError" 
                                             code:-1 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Not connected to Home Assistant"}];
        if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
            [self.delegate homeAssistantClient:self didFailWithError:error];
        }
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
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                
                if (error) {
                    NSLog(@"Service call failed for %@.%@ on %@: %@", domain, service, entityId, error.localizedDescription);
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
                        [self.delegate homeAssistantClient:self didFailWithError:error];
                    }
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:serviceCallDidFailForEntity:withError:)]) {
                        [self.delegate homeAssistantClient:self serviceCallDidFailForEntity:entityId withError:error];
                    }
                    return;
                }
                
                if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
                    NSLog(@"Service call failed with HTTP %ld for %@.%@ on %@", (long)httpResponse.statusCode, domain, service, entityId);
                    NSError *httpError = [NSError errorWithDomain:@"HomeAssistantError" 
                                                             code:httpResponse.statusCode 
                                                         userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Service call failed with HTTP %ld", (long)httpResponse.statusCode]}];
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
                        [self.delegate homeAssistantClient:self didFailWithError:httpError];
                    }
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:serviceCallDidFailForEntity:withError:)]) {
                        [self.delegate homeAssistantClient:self serviceCallDidFailForEntity:entityId withError:httpError];
                    }
                    return;
                }
                
                NSLog(@"Service call successful for %@.%@ on %@", domain, service, entityId);
                
                if ([self.delegate respondsToSelector:@selector(homeAssistantClient:serviceCallDidSucceedForEntity:)]) {
                    [self.delegate homeAssistantClient:self serviceCallDidSucceedForEntity:entityId];
                }
                
                // Refresh states after successful service call with shorter delay for better responsiveness
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self fetchStates];
                });
            });
        }];
        
        [task resume];
    } else {
        if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
            [self.delegate homeAssistantClient:self didFailWithError:jsonError];
        }
    }
}

- (void)callClimateService:(NSString *)service entityId:(NSString *)entityId temperature:(float)temperature {
    if (!self.isConnected) {
        NSError *error = [NSError errorWithDomain:@"HomeAssistantError" 
                                             code:-1 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Not connected to Home Assistant"}];
        if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
            [self.delegate homeAssistantClient:self didFailWithError:error];
        }
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
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                
                if (error) {
                    NSLog(@"Climate service call failed for %@ on %@: %@", service, entityId, error.localizedDescription);
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
                        [self.delegate homeAssistantClient:self didFailWithError:error];
                    }
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:serviceCallDidFailForEntity:withError:)]) {
                        [self.delegate homeAssistantClient:self serviceCallDidFailForEntity:entityId withError:error];
                    }
                    return;
                }
                
                if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
                    NSLog(@"Climate service call failed with HTTP %ld for %@ on %@", (long)httpResponse.statusCode, service, entityId);
                    NSError *httpError = [NSError errorWithDomain:@"HomeAssistantError" 
                                                             code:httpResponse.statusCode 
                                                         userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Climate service call failed with HTTP %ld", (long)httpResponse.statusCode]}];
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
                        [self.delegate homeAssistantClient:self didFailWithError:httpError];
                    }
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:serviceCallDidFailForEntity:withError:)]) {
                        [self.delegate homeAssistantClient:self serviceCallDidFailForEntity:entityId withError:httpError];
                    }
                    return;
                }
                
                NSLog(@"Climate service call successful for %@ on %@", service, entityId);
                
                if ([self.delegate respondsToSelector:@selector(homeAssistantClient:serviceCallDidSucceedForEntity:)]) {
                    [self.delegate homeAssistantClient:self serviceCallDidSucceedForEntity:entityId];
                }
                
                // Refresh states after successful service call
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self fetchStates];
                });
            });
        }];
        
        [task resume];
    } else {
        if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didFailWithError:)]) {
            [self.delegate homeAssistantClient:self didFailWithError:jsonError];
        }
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
    if (self.isConnected) {
        // Only fetch via HTTP if WebSocket is not connected
        // This prevents redundant HTTP requests when WebSocket is working
        if (!self.webSocketConnected) {
            NSLog(@"Auto-refreshing via HTTP (WebSocket not connected)");
            [self fetchStates];
        } else {
            // WebSocket is connected, but we still do occasional HTTP polling 
            // to catch any missed updates (every 10th interval)
            static NSInteger pollCounter = 0;
            pollCounter++;
            if (pollCounter >= 10) {
                NSLog(@"Periodic HTTP state validation while WebSocket connected");
                [self fetchStates];
                pollCounter = 0;
            }
        }
    }
}

- (void)connectWebSocket {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        if (self.webSocketTask) {
            NSLog(@"WebSocket already connecting or connected");
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
        
        NSLog(@"Attempting WebSocket connection to: %@", wsURL);
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.timeoutInterval = 30.0; // Set connection timeout
        
        self.webSocketTask = [self.webSocketSession webSocketTaskWithRequest:request];
        [self.webSocketTask resume];
        
        // Start receiving messages
        [self receiveWebSocketMessage];
        
        // Reset reconnect attempts on successful connection attempt
        self.reconnectAttempts = 0;
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
    
    [self stopWebSocketHeartbeat];
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
    NSLog(@"WebSocket received message type: %@", type);
    
    if ([type isEqualToString:@"auth_required"]) {
        // Send authentication
        [self sendWebSocketAuth];
    } else if ([type isEqualToString:@"auth_ok"]) {
        // Authentication successful, subscribe to state changes
        NSLog(@"WebSocket authentication successful");
        self.webSocketConnected = YES;
        self.reconnectAttempts = 0; // Reset reconnect attempts
        self.webSocketReconnectDelay = 1.0; // Reset delay
        [self subscribeToStateChanges];
        [self startWebSocketHeartbeat];
    } else if ([type isEqualToString:@"auth_invalid"]) {
        NSLog(@"WebSocket authentication failed");
        [self disconnectWebSocket];
    } else if ([type isEqualToString:@"event"]) {
        [self handleStateChangeEvent:json];
    } else if ([type isEqualToString:@"pong"]) {
        // Handle heartbeat response
        self.awaitingHeartbeatResponse = NO;
        NSLog(@"WebSocket heartbeat pong received");
    } else if ([type isEqualToString:@"result"]) {
        // Handle subscription result
        NSLog(@"WebSocket subscription result: %@", json[@"success"] ? @"success" : @"failed");
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
        NSLog(@"WebSocket connected successfully");
    }
}

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(NSData *)reason {
    if (@available(iOS 13.0, *)) {
        NSString *reasonString = reason ? [[NSString alloc] initWithData:reason encoding:NSUTF8StringEncoding] : @"";
        NSLog(@"WebSocket disconnected with code: %ld, reason: %@", (long)closeCode, reasonString);
        
        [self stopWebSocketHeartbeat];
        self.webSocketConnected = NO;
        self.webSocketTask = nil;
        
        // Try to reconnect if we were previously connected and it wasn't a normal closure
        if (self.isConnected && closeCode != NSURLSessionWebSocketCloseCodeNormalClosure) {
            [self scheduleWebSocketReconnect];
        }
    }
}
#endif

- (void)scheduleWebSocketReconnect {
    // Stop any existing reconnect timer
    if (self.reconnectTimer) {
        [self.reconnectTimer invalidate];
        self.reconnectTimer = nil;
    }
    
    // Implement exponential backoff with jitter
    self.reconnectAttempts++;
    NSTimeInterval delay = MIN(self.webSocketReconnectDelay * pow(2, self.reconnectAttempts - 1), 30.0); // Max 30 seconds
    
    // Add jitter (±25%)
    NSTimeInterval jitter = delay * 0.25 * ((arc4random() % 200) - 100) / 100.0;
    delay += jitter;
    
    NSLog(@"Scheduling WebSocket reconnect in %.1f seconds (attempt %ld)", delay, (long)self.reconnectAttempts);
    
    self.reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                           target:self
                                                         selector:@selector(reconnectWebSocket:)
                                                         userInfo:nil
                                                          repeats:NO];
}

- (void)reconnectWebSocket:(NSTimer *)timer {
    self.reconnectTimer = nil;
    if (self.isConnected) {
        [self connectWebSocket];
    }
}

#pragma mark - WebSocket Heartbeat

- (void)startWebSocketHeartbeat {
    [self stopWebSocketHeartbeat];
    
    // Start heartbeat timer to send ping every 30 seconds
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                           target:self
                                                         selector:@selector(sendWebSocketHeartbeat:)
                                                         userInfo:nil
                                                          repeats:YES];
}

- (void)stopWebSocketHeartbeat {
    if (self.heartbeatTimer) {
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
    self.awaitingHeartbeatResponse = NO;
}

- (void)sendWebSocketHeartbeat:(NSTimer *)timer {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        if (!self.webSocketTask || !self.webSocketConnected) {
            [self stopWebSocketHeartbeat];
            return;
        }
        
        // Check if we're still waiting for a previous pong
        if (self.awaitingHeartbeatResponse) {
            NSLog(@"WebSocket heartbeat timeout - connection appears dead");
            [self handleWebSocketConnectionDead];
            return;
        }
        
        // Send ping
        NSDictionary *pingMessage = @{
            @"id": @(self.websocketId++),
            @"type": @"ping"
        };
        
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:pingMessage options:0 error:&error];
        if (!error) {
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSURLSessionWebSocketMessage *message = [[NSURLSessionWebSocketMessage alloc] initWithString:jsonString];
            
            self.awaitingHeartbeatResponse = YES;
            
            [self.webSocketTask sendMessage:message completionHandler:^(NSError *sendError) {
                if (sendError) {
                    NSLog(@"Failed to send heartbeat ping: %@", sendError.localizedDescription);
                    [self handleWebSocketConnectionDead];
                }
            }];
        }
    }
#endif
}

- (void)handleWebSocketConnectionDead {
    NSLog(@"WebSocket connection appears dead, initiating reconnection");
    [self disconnectWebSocket];
    
    // Trigger reconnection if we're still connected to HA
    if (self.isConnected) {
        [self scheduleWebSocketReconnect];
    }
}

@end