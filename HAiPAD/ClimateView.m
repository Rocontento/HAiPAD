//
//  ClimateView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "ClimateView.h"
#import "UIColor+HAiPAD.h"

@implementation ClimateView

- (void)setupEntitySpecificUI {
    // Set default temperature ranges
    self.minTemp = 10.0;
    self.maxTemp = 35.0;
    
    // Create thermostat dial container
    self.thermostatDial = [[UIView alloc] init];
    self.thermostatDial.translatesAutoresizingMaskIntoConstraints = NO;
    self.thermostatDial.backgroundColor = [UIColor clearColor];
    [self.cardContainer addSubview:self.thermostatDial];
    
    // Create current temperature label (center)
    self.currentTempLabel = [[UILabel alloc] init];
    self.currentTempLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.currentTempLabel.font = [UIFont systemFontOfSize:24];
    self.currentTempLabel.textColor = [UIColor darkTextColor];
    self.currentTempLabel.textAlignment = NSTextAlignmentCenter;
    self.currentTempLabel.text = @"--";
    [self.thermostatDial addSubview:self.currentTempLabel];
    
    // Create target temperature label (smaller, below current)
    self.targetTempLabel = [[UILabel alloc] init];
    self.targetTempLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.targetTempLabel.font = [UIFont systemFontOfSize:14];
    self.targetTempLabel.textColor = [UIColor ha_systemOrangeColor];
    self.targetTempLabel.textAlignment = NSTextAlignmentCenter;
    self.targetTempLabel.text = @"Target: --";
    [self.thermostatDial addSubview:self.targetTempLabel];
    
    // Create mode label
    self.modeLabel = [[UILabel alloc] init];
    self.modeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.modeLabel.font = [UIFont systemFontOfSize:10];
    self.modeLabel.textColor = [UIColor grayColor];
    self.modeLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardContainer addSubview:self.modeLabel];
    
    // Add pan gesture for temperature adjustment
    self.dialGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDialGesture:)];
    [self.thermostatDial addGestureRecognizer:self.dialGesture];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Thermostat dial - circular area
        [self.thermostatDial.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.thermostatDial.centerYAnchor constraintEqualToAnchor:self.cardContainer.centerYAnchor constant:-10],
        [self.thermostatDial.widthAnchor constraintEqualToConstant:100],
        [self.thermostatDial.heightAnchor constraintEqualToConstant:100],
        
        // Current temperature in center of dial
        [self.currentTempLabel.centerXAnchor constraintEqualToAnchor:self.thermostatDial.centerXAnchor],
        [self.currentTempLabel.centerYAnchor constraintEqualToAnchor:self.thermostatDial.centerYAnchor constant:-8],
        
        // Target temperature below current
        [self.targetTempLabel.centerXAnchor constraintEqualToAnchor:self.thermostatDial.centerXAnchor],
        [self.targetTempLabel.topAnchor constraintEqualToAnchor:self.currentTempLabel.bottomAnchor constant:4],
        
        // Mode label at bottom
        [self.modeLabel.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.modeLabel.bottomAnchor constraintEqualToAnchor:self.nameLabel.topAnchor constant:-4]
    ]];
}

- (void)updateWithEntity:(NSDictionary *)entity {
    [super updateWithEntity:entity];
    
    NSDictionary *attributes = [self attributes];
    NSString *state = [self state];
    
    // Update temperature values
    NSNumber *currentTempNum = attributes[@"current_temperature"];
    NSNumber *targetTempNum = attributes[@"temperature"];
    NSNumber *minTempNum = attributes[@"min_temp"];
    NSNumber *maxTempNum = attributes[@"max_temp"];
    NSString *tempUnit = attributes[@"temperature_unit"] ?: @"°C";
    
    if (currentTempNum) {
        self.currentTemp = currentTempNum.floatValue;
        self.currentTempLabel.text = [NSString stringWithFormat:@"%.1f%@", self.currentTemp, tempUnit];
    } else {
        self.currentTempLabel.text = @"--";
    }
    
    if (targetTempNum) {
        self.targetTemp = targetTempNum.floatValue;
        self.targetTempLabel.text = [NSString stringWithFormat:@"Target: %.1f%@", self.targetTemp, tempUnit];
    } else {
        self.targetTempLabel.text = @"Target: --";
    }
    
    if (minTempNum) self.minTemp = minTempNum.floatValue;
    if (maxTempNum) self.maxTemp = maxTempNum.floatValue;
    
    // Update mode
    NSString *mode = attributes[@"hvac_mode"] ?: state;
    self.modeLabel.text = [mode capitalizedString];
    
    // Update state label
    if ([state isEqualToString:@"off"]) {
        self.stateLabel.text = @"Off";
    } else if (currentTempNum && targetTempNum) {
        self.stateLabel.text = [NSString stringWithFormat:@"%.1f%@ → %.1f%@", 
                               self.currentTemp, tempUnit, self.targetTemp, tempUnit];
    } else {
        self.stateLabel.text = [state capitalizedString];
    }
    
    // Redraw the dial
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self drawThermostatDial];
}

- (void)drawThermostatDial {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return;
    
    CGRect dialFrame = self.thermostatDial.frame;
    CGPoint center = CGPointMake(CGRectGetMidX(dialFrame), CGRectGetMidY(dialFrame));
    CGFloat radius = MIN(dialFrame.size.width, dialFrame.size.height) / 2 - 10;
    
    // Convert to view coordinates
    center = [self convertPoint:center fromView:self.cardContainer];
    
    // Draw outer ring (background)
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.9 alpha:1.0].CGColor);
    CGContextSetLineWidth(context, 8.0);
    CGContextAddArc(context, center.x, center.y, radius, 0, 2 * M_PI, 0);
    CGContextStrokePath(context);
    
    // Calculate angles for temperature range
    CGFloat tempRange = self.maxTemp - self.minTemp;
    if (tempRange <= 0) return;
    
    // Draw target temperature arc
    if (self.targetTemp >= self.minTemp && self.targetTemp <= self.maxTemp) {
        CGFloat targetAngle = ((self.targetTemp - self.minTemp) / tempRange) * 2 * M_PI - M_PI_2;
        
        CGContextSetStrokeColorWithColor(context, [UIColor ha_systemOrangeColor].CGColor);
        CGContextSetLineWidth(context, 8.0);
        CGContextAddArc(context, center.x, center.y, radius, -M_PI_2, targetAngle, 0);
        CGContextStrokePath(context);
        
        // Draw target indicator
        CGFloat indicatorX = center.x + radius * cos(targetAngle);
        CGFloat indicatorY = center.y + radius * sin(targetAngle);
        
        CGContextSetFillColorWithColor(context, [UIColor ha_systemOrangeColor].CGColor);
        CGContextFillEllipseInRect(context, CGRectMake(indicatorX - 6, indicatorY - 6, 12, 12));
    }
    
    // Draw current temperature indicator
    if (self.currentTemp >= self.minTemp && self.currentTemp <= self.maxTemp) {
        CGFloat currentAngle = ((self.currentTemp - self.minTemp) / tempRange) * 2 * M_PI - M_PI_2;
        CGFloat indicatorX = center.x + (radius - 15) * cos(currentAngle);
        CGFloat indicatorY = center.y + (radius - 15) * sin(currentAngle);
        
        CGContextSetFillColorWithColor(context, [UIColor ha_systemBlueColor].CGColor);
        CGContextFillEllipseInRect(context, CGRectMake(indicatorX - 4, indicatorY - 4, 8, 8));
    }
}

- (UIColor *)colorForEntityState {
    NSString *state = [self state];
    if ([state isEqualToString:@"heat"]) {
        return [UIColor colorWithRed:1.0 green:0.95 blue:0.9 alpha:1.0]; // Warm color
    } else if ([state isEqualToString:@"cool"]) {
        return [UIColor colorWithRed:0.9 green:0.95 blue:1.0 alpha:1.0]; // Cool color
    } else if ([state isEqualToString:@"auto"]) {
        return [UIColor colorWithRed:0.95 green:1.0 blue:0.95 alpha:1.0]; // Neutral green
    } else if ([state isEqualToString:@"off"]) {
        return [UIColor colorWithWhite:0.95 alpha:1.0]; // Gray when off
    }
    return [UIColor whiteColor];
}

#pragma mark - Gesture Handling

- (void)handleDialGesture:(UIPanGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.thermostatDial];
    CGPoint center = CGPointMake(self.thermostatDial.bounds.size.width / 2, 
                                self.thermostatDial.bounds.size.height / 2);
    
    // Calculate angle from center
    CGFloat deltaX = location.x - center.x;
    CGFloat deltaY = location.y - center.y;
    CGFloat angle = atan2(deltaY, deltaX);
    
    // Normalize angle to 0-2π
    if (angle < 0) angle += 2 * M_PI;
    
    // Convert angle to temperature
    CGFloat tempRange = self.maxTemp - self.minTemp;
    CGFloat normalizedAngle = (angle + M_PI_2) / (2 * M_PI);
    if (normalizedAngle > 1.0) normalizedAngle -= 1.0;
    
    CGFloat newTargetTemp = self.minTemp + (normalizedAngle * tempRange);
    
    // Round to nearest 0.5 degree
    newTargetTemp = round(newTargetTemp * 2) / 2.0;
    
    // Clamp to valid range
    newTargetTemp = MAX(self.minTemp, MIN(self.maxTemp, newTargetTemp));
    
    if (gesture.state == UIGestureRecognizerStateChanged || gesture.state == UIGestureRecognizerStateEnded) {
        if (fabs(newTargetTemp - self.targetTemp) >= 0.5) {
            self.targetTemp = newTargetTemp;
            
            // Update label immediately for smooth feedback
            NSString *tempUnit = [self attributes][@"temperature_unit"] ?: @"°C";
            self.targetTempLabel.text = [NSString stringWithFormat:@"Target: %.1f%@", self.targetTemp, tempUnit];
            
            // Redraw the dial
            [self setNeedsDisplay];
            
            if (gesture.state == UIGestureRecognizerStateEnded) {
                // Send service call to Home Assistant
                NSDictionary *parameters = @{@"temperature": @(self.targetTemp)};
                
                if ([self.delegate respondsToSelector:@selector(entityView:didRequestServiceCall:service:entityId:parameters:)]) {
                    [self.delegate entityView:self didRequestServiceCall:@"climate" service:@"set_temperature" entityId:[self entityId] parameters:parameters];
                }
            }
        }
    }
}

@end