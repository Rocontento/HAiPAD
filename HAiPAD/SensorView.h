//
//  SensorView.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "BaseEntityView.h"

@interface SensorView : BaseEntityView

@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UILabel *unitLabel;
@property (nonatomic, strong) UIImageView *iconView;

@end