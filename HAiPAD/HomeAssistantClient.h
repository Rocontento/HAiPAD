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
- (void)homeAssistantClient:(HomeAssistantClient *)client serviceCallDidSucceedForEntity:(NSString *)entityId;
- (void)homeAssistantClient:(HomeAssistantClient *)client serviceCallDidFailForEntity:(NSString *)entityId withError:(NSError *)error;
@end

@interface HomeAssistantClient : NSObject

@property (nonatomic, weak) id<HomeAssistantClientDelegate> delegate;
@property (nonatomic, strong) NSString *baseURL;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, assign) BOOL autoRefreshEnabled;
@property (nonatomic, assign) NSTimeInterval autoRefreshInterval;
@property (nonatomic, readonly) BOOL isWebSocketConnected;
@property (nonatomic, assign) NSTimeInterval webSocketReconnectDelay;

+ (instancetype)sharedClient;

- (void)connectWithBaseURL:(NSString *)baseURL accessToken:(NSString *)accessToken;
- (void)disconnect;
- (void)fetchStates;
- (void)callService:(NSString *)domain service:(NSString *)service entityId:(NSString *)entityId;
- (void)callClimateService:(NSString *)service entityId:(NSString *)entityId temperature:(float)temperature;

// Real-time updates
- (void)startAutoRefresh;
- (void)stopAutoRefresh;
- (void)connectWebSocket;
- (void)disconnectWebSocket;
- (BOOL)isWebSocketAvailable;

@end