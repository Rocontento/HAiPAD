//
//  HomeAssistantClient.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <Foundation/Foundation.h>

@class HomeAssistantClient;

@protocol HomeAssistantClientDelegate <NSObject>
@optional
- (void)homeAssistantClient:(HomeAssistantClient *)client didReceiveStates:(NSArray *)states;
- (void)homeAssistantClient:(HomeAssistantClient *)client didFailWithError:(NSError *)error;
- (void)homeAssistantClientDidConnect:(HomeAssistantClient *)client;
- (void)homeAssistantClientDidDisconnect:(HomeAssistantClient *)client;
- (void)homeAssistantClient:(HomeAssistantClient *)client didReceiveStateChange:(NSDictionary *)stateChange;
@end

@interface HomeAssistantClient : NSObject

@property (nonatomic, weak) id<HomeAssistantClientDelegate> delegate;
@property (nonatomic, strong) NSString *baseURL;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, assign) BOOL autoRefreshEnabled;
@property (nonatomic, assign) NSTimeInterval autoRefreshInterval;

+ (instancetype)sharedClient;

- (void)connectWithBaseURL:(NSString *)baseURL accessToken:(NSString *)accessToken;
- (void)disconnect;
- (void)fetchStates;
- (void)callService:(NSString *)domain service:(NSString *)service entityId:(NSString *)entityId;
- (void)callService:(NSString *)domain service:(NSString *)service entityId:(NSString *)entityId parameters:(NSDictionary *)parameters;
- (void)callClimateService:(NSString *)service entityId:(NSString *)entityId temperature:(float)temperature;
- (void)callLightService:(NSString *)service entityId:(NSString *)entityId parameters:(NSDictionary *)parameters;

// Real-time updates
- (void)startAutoRefresh;
- (void)stopAutoRefresh;
- (void)connectWebSocket;
- (void)disconnectWebSocket;
- (BOOL)isWebSocketAvailable;

@end