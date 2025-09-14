//
//  BinarySensorView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "BinarySensorView.h"
#import "UIColor+HAiPAD.h"

@implementation BinarySensorView

- (void)setupEntitySpecificUI {
    // Create status indicator (colored dot)
    self.statusIndicator = [[UIView alloc] init];
    self.statusIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusIndicator.layer.cornerRadius = 8.0;
    self.statusIndicator.layer.borderWidth = 2.0;
    [self.cardContainer addSubview:self.statusIndicator];
    
    // Create status icon
    self.statusIcon = [[UIImageView alloc] init];
    self.statusIcon.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.cardContainer addSubview:self.statusIcon];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Status indicator in top-right
        [self.statusIndicator.topAnchor constraintEqualToAnchor:self.cardContainer.topAnchor constant:12],
        [self.statusIndicator.trailingAnchor constraintEqualToAnchor:self.cardContainer.trailingAnchor constant:-12],
        [self.statusIndicator.widthAnchor constraintEqualToConstant:16],
        [self.statusIndicator.heightAnchor constraintEqualToConstant:16],
        
        // Status icon in center
        [self.statusIcon.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.statusIcon.centerYAnchor constraintEqualToAnchor:self.cardContainer.centerYAnchor constant:-8],
        [self.statusIcon.widthAnchor constraintEqualToConstant:40],
        [self.statusIcon.heightAnchor constraintEqualToConstant:40]
    ]];
}

- (void)updateWithEntity:(NSDictionary *)entity {
    [super updateWithEntity:entity];
    
    NSString *state = [self state];
    NSString *deviceClass = [self attributes][@"device_class"];
    BOOL isOn = [state isEqualToString:@"on"];
    
    // Update status indicator
    if (isOn) {
        self.statusIndicator.backgroundColor = [self activeColorForDeviceClass:deviceClass];
        self.statusIndicator.layer.borderColor = [self activeColorForDeviceClass:deviceClass].CGColor;
    } else {
        self.statusIndicator.backgroundColor = [UIColor lightGrayColor];
        self.statusIndicator.layer.borderColor = [UIColor lightGrayColor].CGColor;
    }
    
    // Update icon
    UIImage *icon = [self iconForDeviceClass:deviceClass isOn:isOn];
    self.statusIcon.image = icon;
    self.statusIcon.tintColor = isOn ? [self activeColorForDeviceClass:deviceClass] : [UIColor grayColor];
    
    // Update state label
    self.stateLabel.text = [self formatStateForDeviceClass:deviceClass state:state];
}

- (UIColor *)activeColorForDeviceClass:(NSString *)deviceClass {
    if ([deviceClass isEqualToString:@"motion"]) {
        return [UIColor ha_systemOrangeColor];
    } else if ([deviceClass isEqualToString:@"door"] || [deviceClass isEqualToString:@"window"]) {
        return [UIColor ha_systemBlueColor];
    } else if ([deviceClass isEqualToString:@"smoke"] || [deviceClass isEqualToString:@"gas"]) {
        return [UIColor ha_systemRedColor];
    } else if ([deviceClass isEqualToString:@"moisture"]) {
        return [UIColor ha_systemBlueColor];
    } else if ([deviceClass isEqualToString:@"occupancy"] || [deviceClass isEqualToString:@"presence"]) {
        return [UIColor ha_systemGreenColor];
    } else if ([deviceClass isEqualToString:@"light"]) {
        return [UIColor ha_systemYellowColor];
    }
    return [UIColor ha_systemGrayColor];
}

- (UIImage *)iconForDeviceClass:(NSString *)deviceClass isOn:(BOOL)isOn {
    if ([deviceClass isEqualToString:@"motion"]) {
        return [self createMotionIcon:isOn];
    } else if ([deviceClass isEqualToString:@"door"]) {
        return [self createDoorIcon:isOn];
    } else if ([deviceClass isEqualToString:@"window"]) {
        return [self createWindowIcon:isOn];
    } else if ([deviceClass isEqualToString:@"smoke"]) {
        return [self createSmokeIcon:isOn];
    } else if ([deviceClass isEqualToString:@"moisture"]) {
        return [self createMoistureIcon:isOn];
    } else if ([deviceClass isEqualToString:@"occupancy"] || [deviceClass isEqualToString:@"presence"]) {
        return [self createPresenceIcon:isOn];
    }
    return [self createGenericIcon:isOn];
}

- (NSString *)formatStateForDeviceClass:(NSString *)deviceClass state:(NSString *)state {
    BOOL isOn = [state isEqualToString:@"on"];
    
    if ([deviceClass isEqualToString:@"motion"]) {
        return isOn ? @"Motion" : @"Clear";
    } else if ([deviceClass isEqualToString:@"door"]) {
        return isOn ? @"Open" : @"Closed";
    } else if ([deviceClass isEqualToString:@"window"]) {
        return isOn ? @"Open" : @"Closed";
    } else if ([deviceClass isEqualToString:@"smoke"]) {
        return isOn ? @"Detected" : @"Clear";
    } else if ([deviceClass isEqualToString:@"moisture"]) {
        return isOn ? @"Wet" : @"Dry";
    } else if ([deviceClass isEqualToString:@"occupancy"] || [deviceClass isEqualToString:@"presence"]) {
        return isOn ? @"Occupied" : @"Empty";
    }
    return isOn ? @"On" : @"Off";
}

- (UIColor *)colorForEntityState {
    NSString *state = [self state];
    NSString *deviceClass = [self attributes][@"device_class"];
    BOOL isOn = [state isEqualToString:@"on"];
    
    if (isOn) {
        UIColor *activeColor = [self activeColorForDeviceClass:deviceClass];
        // Create a light tinted background
        CGFloat red, green, blue, alpha;
        [activeColor getRed:&red green:&green blue:&blue alpha:&alpha];
        return [UIColor colorWithRed:red * 0.1 + 0.9 green:green * 0.1 + 0.9 blue:blue * 0.1 + 0.9 alpha:1.0];
    }
    
    return [UIColor colorWithWhite:0.98 alpha:1.0];
}

#pragma mark - Icon Creation Methods

- (UIImage *)createMotionIcon:(BOOL)isOn {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *color = isOn ? [UIColor ha_systemOrangeColor] : [UIColor grayColor];
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 3.0);
    
    // Draw running person icon
    // Head
    CGContextAddEllipseInRect(context, CGRectMake(15, 8, 8, 8));
    CGContextStrokePath(context);
    
    // Body
    CGContextMoveToPoint(context, 19, 16);
    CGContextAddLineToPoint(context, 19, 25);
    CGContextStrokePath(context);
    
    // Arms
    CGContextMoveToPoint(context, 19, 20);
    CGContextAddLineToPoint(context, 12, 18);
    CGContextMoveToPoint(context, 19, 20);
    CGContextAddLineToPoint(context, 26, 22);
    CGContextStrokePath(context);
    
    // Legs
    CGContextMoveToPoint(context, 19, 25);
    CGContextAddLineToPoint(context, 14, 32);
    CGContextMoveToPoint(context, 19, 25);
    CGContextAddLineToPoint(context, 24, 32);
    CGContextStrokePath(context);
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

- (UIImage *)createDoorIcon:(BOOL)isOn {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *color = isOn ? [UIColor ha_systemBlueColor] : [UIColor grayColor];
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 3.0);
    
    if (isOn) {
        // Open door - angled
        CGContextMoveToPoint(context, 12, 10);
        CGContextAddLineToPoint(context, 18, 12);
        CGContextAddLineToPoint(context, 18, 30);
        CGContextAddLineToPoint(context, 12, 28);
        CGContextClosePath(context);
        CGContextStrokePath(context);
        
        // Door handle
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillEllipseInRect(context, CGRectMake(14, 19, 2, 2));
    } else {
        // Closed door
        CGContextMoveToPoint(context, 15, 10);
        CGContextAddLineToPoint(context, 25, 10);
        CGContextAddLineToPoint(context, 25, 30);
        CGContextAddLineToPoint(context, 15, 30);
        CGContextClosePath(context);
        CGContextStrokePath(context);
        
        // Door handle
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillEllipseInRect(context, CGRectMake(22, 19, 2, 2));
    }
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

- (UIImage *)createWindowIcon:(BOOL)isOn {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *color = isOn ? [UIColor ha_systemBlueColor] : [UIColor grayColor];
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    // Window frame
    CGContextAddRect(context, CGRectMake(12, 12, 16, 16));
    CGContextStrokePath(context);
    
    // Window divider
    CGContextMoveToPoint(context, 20, 12);
    CGContextAddLineToPoint(context, 20, 28);
    CGContextMoveToPoint(context, 12, 20);
    CGContextAddLineToPoint(context, 28, 20);
    CGContextStrokePath(context);
    
    if (isOn) {
        // Open window indicator - small gap
        CGContextSetLineWidth(context, 4.0);
        CGContextSetStrokeColorWithColor(context, [UIColor ha_systemBlueColor].CGColor);
        CGContextMoveToPoint(context, 28, 12);
        CGContextAddLineToPoint(context, 30, 10);
        CGContextStrokePath(context);
    }
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

- (UIImage *)createSmokeIcon:(BOOL)isOn {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *color = isOn ? [UIColor ha_systemRedColor] : [UIColor grayColor];
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    // Smoke detector base
    CGContextAddEllipseInRect(context, CGRectMake(8, 15, 24, 10));
    CGContextStrokePath(context);
    
    if (isOn) {
        // Smoke waves
        CGContextSetLineWidth(context, 1.5);
        for (int i = 0; i < 3; i++) {
            CGFloat y = 8 + i * 3;
            CGContextMoveToPoint(context, 16 + i * 2, y);
            CGContextAddQuadCurveToPoint(context, 20 + i * 2, y - 2, 24 + i * 2, y);
            CGContextStrokePath(context);
        }
    }
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

- (UIImage *)createMoistureIcon:(BOOL)isOn {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *color = isOn ? [UIColor ha_systemBlueColor] : [UIColor grayColor];
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    // Water drop shape
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 20, 10);
    CGPathAddCurveToPoint(path, NULL, 14, 16, 14, 22, 14, 26);
    CGPathAddCurveToPoint(path, NULL, 14, 30, 17, 32, 20, 32);
    CGPathAddCurveToPoint(path, NULL, 23, 32, 26, 30, 26, 26);
    CGPathAddCurveToPoint(path, NULL, 26, 22, 26, 16, 20, 10);
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    CGPathRelease(path);
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

- (UIImage *)createPresenceIcon:(BOOL)isOn {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *color = isOn ? [UIColor ha_systemGreenColor] : [UIColor grayColor];
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 3.0);
    
    // Person icon
    // Head
    CGContextAddEllipseInRect(context, CGRectMake(16, 8, 8, 8));
    CGContextStrokePath(context);
    
    // Body
    CGContextMoveToPoint(context, 20, 16);
    CGContextAddLineToPoint(context, 20, 26);
    CGContextStrokePath(context);
    
    // Arms
    CGContextMoveToPoint(context, 20, 20);
    CGContextAddLineToPoint(context, 14, 22);
    CGContextMoveToPoint(context, 20, 20);
    CGContextAddLineToPoint(context, 26, 22);
    CGContextStrokePath(context);
    
    // Legs
    CGContextMoveToPoint(context, 20, 26);
    CGContextAddLineToPoint(context, 16, 32);
    CGContextMoveToPoint(context, 20, 26);
    CGContextAddLineToPoint(context, 24, 32);
    CGContextStrokePath(context);
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

- (UIImage *)createGenericIcon:(BOOL)isOn {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *color = isOn ? [UIColor ha_systemGrayColor] : [UIColor lightGrayColor];
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    // Simple circle
    CGContextFillEllipseInRect(context, CGRectMake(15, 15, 10, 10));
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

@end