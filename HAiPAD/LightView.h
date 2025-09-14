//
//  LightView.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "BaseEntityView.h"

@interface LightView : BaseEntityView

@property (nonatomic, strong) UISwitch *toggleSwitch;
@property (nonatomic, strong) UISlider *brightnessSlider;
@property (nonatomic, strong) UIView *colorPreview;
@property (nonatomic, strong) UILabel *brightnessLabel;

@end