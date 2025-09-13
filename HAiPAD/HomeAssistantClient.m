//
//  HomeAssistantClient.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "HomeAssistantClient.h"

@interface HomeAssistantClient ()
@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, assign) BOOL isConnected;
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
                    if ([self.delegate respondsToSelector:@selector(homeAssistantClient:didReceiveStates:)]) {
                        [self.delegate homeAssistantClient:self didReceiveStates:states];
                    }
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
                // Refresh states after service call
                [self fetchStates];
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
                // Refresh states after service call
                [self fetchStates];
            });
        }];
        
        [task resume];
    }
}

@end