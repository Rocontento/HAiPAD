//
//  HomeAssistantClient.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "HomeAssistantClient.h"

@interface HomeAssistantClient () <NSURLSessionWebSocketDelegate>
@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSURLSession *webSocketSession;
@property (nonatomic, strong) NSURLSessionWebSocketTask *webSocketTask;
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
        _autoRefreshInterval = 2.0; // Default 2 seconds for fast updates
        _websocketId = 1;
        _entitiesState = [NSMutableDictionary dictionary];
        
        // Create WebSocket session
        NSURLSessionConfiguration *wsConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        _webSocketSession = [NSURLSession sessionWithConfiguration:wsConfig delegate:self delegateQueue:nil];
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
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self fetchStates];
                });
            });
        }];
        
        [task resume];
    }
}

#pragma mark - Real-time Updates

- (void)startRealTimeUpdates {
    // Try WebSocket first for best real-time performance
    [self connectWebSocket];
    
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
    if (self.webSocketTask) {
        return; // Already connecting or connected
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
}

- (void)disconnectWebSocket {
    if (self.webSocketTask) {
        [self.webSocketTask cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure reason:nil];
        self.webSocketTask = nil;
    }
    self.webSocketConnected = NO;
    
    // Stop reconnection timer
    if (self.reconnectTimer) {
        [self.reconnectTimer invalidate];
        self.reconnectTimer = nil;
    }
}

- (void)receiveWebSocketMessage {
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

- (void)subscribeToStateChanges {
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

#pragma mark - NSURLSessionWebSocketDelegate

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didOpenWithProtocol:(NSString *)protocol {
    NSLog(@"WebSocket connected");
}

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(NSData *)reason {
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

- (void)reconnectWebSocket:(NSTimer *)timer {
    self.reconnectTimer = nil;
    if (self.isConnected) {
        [self connectWebSocket];
    }
}

@end