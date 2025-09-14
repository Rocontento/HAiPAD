//
//  BaseEntityView.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

@class BaseEntityView;

@protocol BaseEntityViewDelegate <NSObject>
@optional
- (void)entityView:(BaseEntityView *)view didTriggerAction:(NSString *)action withParameters:(NSDictionary *)parameters;
- (void)entityView:(BaseEntityView *)view didRequestServiceCall:(NSString *)domain service:(NSString *)service entityId:(NSString *)entityId parameters:(NSDictionary *)parameters;
@end

@interface BaseEntityView : UIView

@property (nonatomic, strong) NSDictionary *entity;
@property (nonatomic, weak) id<BaseEntityViewDelegate> delegate;
@property (nonatomic, strong) UIView *cardContainer;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *stateLabel;

// Designated initializer
- (instancetype)initWithFrame:(CGRect)frame entity:(NSDictionary *)entity;

// Abstract methods to be overridden by subclasses
- (void)setupCardAppearance;
- (void)setupEntitySpecificUI;
- (void)updateWithEntity:(NSDictionary *)entity;

// Utility methods
- (NSString *)friendlyName;
- (NSString *)entityId;
- (NSString *)state;
- (NSDictionary *)attributes;
- (UIColor *)colorForEntityState;
- (void)addCardShadow;

@end