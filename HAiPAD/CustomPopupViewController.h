//
//  CustomPopupViewController.h
//  HAiPAD
//
//  Custom popup view controller to replace system dialogs
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CustomPopupType) {
    CustomPopupTypeInfo,
    CustomPopupTypeClimateControl,
    CustomPopupTypeCoverControl,
    CustomPopupTypeLockControl,
    CustomPopupTypeSensorInfo
};

typedef NS_ENUM(NSInteger, CustomPopupButtonStyle) {
    CustomPopupButtonStylePrimary,
    CustomPopupButtonStyleSecondary,
    CustomPopupButtonStyleCancel
};

@interface CustomPopupViewController : UIViewController

@property (nonatomic, strong) NSDictionary *entity;
@property (nonatomic, assign) CustomPopupType popupType;
@property (nonatomic, copy) void(^actionHandler)(NSString *action, NSDictionary *parameters);

+ (instancetype)popupWithEntity:(NSDictionary *)entity 
                           type:(CustomPopupType)type 
                  actionHandler:(void(^)(NSString *action, NSDictionary *parameters))actionHandler;

- (void)presentFromViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)dismissAnimated:(BOOL)animated completion:(void(^)(void))completion;

@end