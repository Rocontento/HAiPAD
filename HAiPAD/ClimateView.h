//
//  ClimateView.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "BaseEntityView.h"

@interface ClimateView : BaseEntityView

@property (nonatomic, strong) UIView *thermostatDial;
@property (nonatomic, strong) UILabel *currentTempLabel;
@property (nonatomic, strong) UILabel *targetTempLabel;
@property (nonatomic, strong) UILabel *modeLabel;
@property (nonatomic, strong) UIPanGestureRecognizer *dialGesture;

@property (nonatomic, assign) CGFloat minTemp;
@property (nonatomic, assign) CGFloat maxTemp;
@property (nonatomic, assign) CGFloat currentTemp;
@property (nonatomic, assign) CGFloat targetTemp;

@end