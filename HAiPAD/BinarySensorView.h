//
//  BinarySensorView.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "BaseEntityView.h"

@interface BinarySensorView : BaseEntityView

@property (nonatomic, strong) UIImageView *statusIcon;
@property (nonatomic, strong) UIView *statusIndicator;

@end