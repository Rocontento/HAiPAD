//
//  UIColor+HAiPAD.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "UIColor+HAiPAD.h"

@implementation UIColor (HAiPAD)

+ (UIColor *)ha_systemBlueColor {
    return [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0]; // iOS system blue
}

+ (UIColor *)ha_systemGreenColor {
    return [UIColor colorWithRed:0.204 green:0.780 blue:0.349 alpha:1.0]; // iOS system green
}

+ (UIColor *)ha_systemOrangeColor {
    return [UIColor colorWithRed:1.0 green:0.584 blue:0.0 alpha:1.0]; // iOS system orange
}

+ (UIColor *)ha_systemYellowColor {
    return [UIColor colorWithRed:1.0 green:0.800 blue:0.0 alpha:1.0]; // iOS system yellow
}

+ (UIColor *)ha_systemRedColor {
    return [UIColor colorWithRed:1.0 green:0.231 blue:0.188 alpha:1.0]; // iOS system red
}

+ (UIColor *)ha_systemPurpleColor {
    return [UIColor colorWithRed:0.686 green:0.322 blue:0.871 alpha:1.0]; // iOS system purple
}

+ (UIColor *)ha_systemGrayColor {
    return [UIColor colorWithRed:0.557 green:0.557 blue:0.576 alpha:1.0]; // iOS system gray
}

@end