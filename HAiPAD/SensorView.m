//
//  SensorView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "SensorView.h"
#import "UIColor+HAiPAD.h"

@implementation SensorView

- (void)setupEntitySpecificUI {
    // Create large value label
    self.valueLabel = [[UILabel alloc] init];
    self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.valueLabel.font = [UIFont systemFontOfSize:24];
    self.valueLabel.textColor = [UIColor darkTextColor];
    self.valueLabel.textAlignment = NSTextAlignmentCenter;
    self.valueLabel.numberOfLines = 1;
    self.valueLabel.adjustsFontSizeToFitWidth = YES;
    self.valueLabel.minimumScaleFactor = 0.5;
    [self.cardContainer addSubview:self.valueLabel];
    
    // Create unit label
    self.unitLabel = [[UILabel alloc] init];
    self.unitLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.unitLabel.font = [UIFont systemFontOfSize:14];
    self.unitLabel.textColor = [UIColor grayColor];
    self.unitLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardContainer addSubview:self.unitLabel];
    
    // Create icon view
    self.iconView = [[UIImageView alloc] init];
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconView.tintColor = [UIColor ha_systemBlueColor];
    [self.cardContainer addSubview:self.iconView];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Icon in top-right corner
        [self.iconView.topAnchor constraintEqualToAnchor:self.cardContainer.topAnchor constant:8],
        [self.iconView.trailingAnchor constraintEqualToAnchor:self.cardContainer.trailingAnchor constant:-8],
        [self.iconView.widthAnchor constraintEqualToConstant:20],
        [self.iconView.heightAnchor constraintEqualToConstant:20],
        
        // Value label in center
        [self.valueLabel.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.valueLabel.centerYAnchor constraintEqualToAnchor:self.cardContainer.centerYAnchor constant:-8],
        [self.valueLabel.leadingAnchor constraintEqualToAnchor:self.cardContainer.leadingAnchor constant:8],
        [self.valueLabel.trailingAnchor constraintEqualToAnchor:self.cardContainer.trailingAnchor constant:-8],
        
        // Unit label below value
        [self.unitLabel.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.unitLabel.topAnchor constraintEqualToAnchor:self.valueLabel.bottomAnchor constant:2]
    ]];
}

- (void)updateWithEntity:(NSDictionary *)entity {
    [super updateWithEntity:entity];
    
    NSString *state = [self state];
    NSString *unit = [self attributes][@"unit_of_measurement"];
    NSString *deviceClass = [self attributes][@"device_class"];
    
    // Format the value for display
    self.valueLabel.text = [self formatValue:state];
    self.unitLabel.text = unit ?: @"";
    
    // Set appropriate icon based on device class or unit
    UIImage *icon = [self iconForSensorType:deviceClass unit:unit];
    self.iconView.image = icon;
    
    // Color code based on device class
    UIColor *iconColor = [self colorForSensorType:deviceClass];
    self.iconView.tintColor = iconColor;
    
    // Update state label with formatted value and unit
    if (unit) {
        self.stateLabel.text = [NSString stringWithFormat:@"%@ %@", [self formatValue:state], unit];
    } else {
        self.stateLabel.text = [self formatValue:state];
    }
}

- (NSString *)formatValue:(NSString *)value {
    // Try to format numeric values nicely
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.maximumFractionDigits = 1;
    
    NSNumber *numericValue = [formatter numberFromString:value];
    if (numericValue) {
        return [formatter stringFromNumber:numericValue];
    }
    
    return value;
}

- (UIImage *)iconForSensorType:(NSString *)deviceClass unit:(NSString *)unit {
    // Return appropriate icon based on device class or unit
    if ([deviceClass isEqualToString:@"temperature"] || [unit hasSuffix:@"°C"] || [unit hasSuffix:@"°F"]) {
        return [self createThermometerIcon];
    } else if ([deviceClass isEqualToString:@"humidity"] || [unit isEqualToString:@"%"]) {
        return [self createHumidityIcon];
    } else if ([deviceClass isEqualToString:@"illuminance"] || [unit isEqualToString:@"lx"]) {
        return [self createLightIcon];
    } else if ([deviceClass isEqualToString:@"pressure"] || [unit isEqualToString:@"hPa"] || [unit isEqualToString:@"mbar"]) {
        return [self createPressureIcon];
    } else if ([deviceClass isEqualToString:@"power"] || [unit isEqualToString:@"W"]) {
        return [self createPowerIcon];
    } else if ([deviceClass isEqualToString:@"energy"] || [unit isEqualToString:@"kWh"]) {
        return [self createEnergyIcon];
    }
    
    return [self createGenericSensorIcon];
}

- (UIColor *)colorForSensorType:(NSString *)deviceClass {
    if ([deviceClass isEqualToString:@"temperature"]) {
        return [UIColor ha_systemOrangeColor];
    } else if ([deviceClass isEqualToString:@"humidity"]) {
        return [UIColor ha_systemBlueColor];
    } else if ([deviceClass isEqualToString:@"illuminance"]) {
        return [UIColor ha_systemYellowColor];
    } else if ([deviceClass isEqualToString:@"pressure"]) {
        return [UIColor ha_systemPurpleColor];
    } else if ([deviceClass isEqualToString:@"power"] || [deviceClass isEqualToString:@"energy"]) {
        return [UIColor ha_systemGreenColor];
    }
    
    return [UIColor ha_systemGrayColor];
}

- (UIColor *)colorForEntityState {
    return [UIColor colorWithWhite:0.98 alpha:1.0]; // Light gray for read-only sensors
}

#pragma mark - Icon Creation Methods

- (UIImage *)createThermometerIcon {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor ha_systemOrangeColor].CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(7, 13, 6, 6));
    CGContextFillRect(context, CGRectMake(9, 2, 2, 14));
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

- (UIImage *)createHumidityIcon {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor ha_systemBlueColor].CGColor);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 10, 2);
    CGPathAddCurveToPoint(path, NULL, 6, 6, 6, 10, 6, 14);
    CGPathAddCurveToPoint(path, NULL, 6, 16, 8, 18, 10, 18);
    CGPathAddCurveToPoint(path, NULL, 12, 18, 14, 16, 14, 14);
    CGPathAddCurveToPoint(path, NULL, 14, 10, 14, 6, 10, 2);
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    CGPathRelease(path);
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

- (UIImage *)createLightIcon {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor ha_systemYellowColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    // Draw sun rays
    for (int i = 0; i < 8; i++) {
        CGFloat angle = i * M_PI / 4;
        CGFloat x1 = 10 + cos(angle) * 6;
        CGFloat y1 = 10 + sin(angle) * 6;
        CGFloat x2 = 10 + cos(angle) * 8;
        CGFloat y2 = 10 + sin(angle) * 8;
        
        CGContextMoveToPoint(context, x1, y1);
        CGContextAddLineToPoint(context, x2, y2);
        CGContextStrokePath(context);
    }
    
    // Draw center circle
    CGContextSetFillColorWithColor(context, [UIColor ha_systemYellowColor].CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(7, 7, 6, 6));
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

- (UIImage *)createPressureIcon {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor ha_systemPurpleColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    // Draw gauge
    CGContextAddArc(context, 10, 10, 7, M_PI, 0, 0);
    CGContextStrokePath(context);
    
    // Draw needle
    CGContextMoveToPoint(context, 10, 10);
    CGContextAddLineToPoint(context, 14, 6);
    CGContextStrokePath(context);
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

- (UIImage *)createPowerIcon {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor ha_systemGreenColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    // Draw lightning bolt
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 12, 2);
    CGPathAddLineToPoint(path, NULL, 8, 10);
    CGPathAddLineToPoint(path, NULL, 12, 10);
    CGPathAddLineToPoint(path, NULL, 8, 18);
    CGPathAddLineToPoint(path, NULL, 12, 10);
    CGPathAddLineToPoint(path, NULL, 8, 10);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
    CGPathRelease(path);
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

- (UIImage *)createEnergyIcon {
    return [self createPowerIcon]; // Use same icon for energy
}

- (UIImage *)createGenericSensorIcon {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor ha_systemGrayColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    // Draw simple circle
    CGContextAddEllipseInRect(context, CGRectMake(6, 6, 8, 8));
    CGContextStrokePath(context);
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

@end