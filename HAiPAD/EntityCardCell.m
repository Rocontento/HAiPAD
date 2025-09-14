//
//  EntityCardCell.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "EntityCardCell.h"

@implementation EntityCardCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Configure card appearance for iOS 9.3.5 compatibility
    self.cardContainerView.layer.cornerRadius = 8.0;
    self.cardContainerView.layer.masksToBounds = NO;
    
    // Add shadow (iOS 9.3.5 compatible)
    self.cardContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardContainerView.layer.shadowOffset = CGSizeMake(0, 2);
    self.cardContainerView.layer.shadowOpacity = 0.1;
    self.cardContainerView.layer.shadowRadius = 4.0;
    
    // Set background color
    self.cardContainerView.backgroundColor = [UIColor whiteColor];
    
    // Configure labels
    self.nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.stateLabel.font = [UIFont systemFontOfSize:14];
    self.stateLabel.textColor = [UIColor grayColor];
    
    // Configure info button
    self.infoButton.layer.cornerRadius = 10.0;
    self.infoButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    [self.infoButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    // Setup resize handles
    [self setupResizeHandles];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Reset to default appearance
    self.cardContainerView.backgroundColor = [UIColor whiteColor];
    self.cardContainerView.layer.borderWidth = 0.0;
    self.cardContainerView.layer.borderColor = [UIColor clearColor].CGColor;
    self.nameLabel.text = @"";
    self.stateLabel.text = @"";
    self.nameLabel.textColor = [UIColor darkTextColor];
}

- (void)configureWithEntity:(NSDictionary *)entity {
    NSString *entityId = entity[@"entity_id"];
    NSString *friendlyName = entity[@"attributes"][@"friendly_name"] ?: entityId;
    NSString *state = entity[@"state"];
    
    self.nameLabel.text = friendlyName;
    self.stateLabel.text = [self formatStateForEntity:entity];
    
    // Set card color based on entity type and state
    [self updateCardAppearanceForEntity:entity];
}

- (NSString *)formatStateForEntity:(NSDictionary *)entity {
    NSString *entityId = entity[@"entity_id"];
    NSString *state = entity[@"state"];
    
    if ([entityId hasPrefix:@"light."] || [entityId hasPrefix:@"switch."] || [entityId hasPrefix:@"fan."]) {
        return [state isEqualToString:@"on"] ? @"On" : @"Off";
    } else if ([entityId hasPrefix:@"binary_sensor."]) {
        return [state isEqualToString:@"on"] ? @"Detected" : @"Clear";
    } else if ([entityId hasPrefix:@"sensor."]) {
        NSString *unit = entity[@"attributes"][@"unit_of_measurement"];
        if (unit) {
            return [NSString stringWithFormat:@"%@ %@", state, unit];
        }
        return state;
    } else if ([entityId hasPrefix:@"climate."]) {
        NSNumber *currentTemp = entity[@"attributes"][@"current_temperature"];
        NSNumber *targetTemp = entity[@"attributes"][@"temperature"];
        NSString *unit = entity[@"attributes"][@"temperature_unit"] ?: @"°C";
        
        if (currentTemp && targetTemp) {
            return [NSString stringWithFormat:@"%.1f%@ → %.1f%@", 
                   currentTemp.floatValue, unit, targetTemp.floatValue, unit];
        } else if (currentTemp) {
            return [NSString stringWithFormat:@"%.1f%@", currentTemp.floatValue, unit];
        }
        return [state capitalizedString];
    } else if ([entityId hasPrefix:@"cover."]) {
        if ([state isEqualToString:@"open"]) {
            return @"Open";
        } else if ([state isEqualToString:@"closed"]) {
            return @"Closed";
        } else if ([state isEqualToString:@"opening"]) {
            return @"Opening...";
        } else if ([state isEqualToString:@"closing"]) {
            return @"Closing...";
        }
        return [state capitalizedString];
    } else if ([entityId hasPrefix:@"lock."]) {
        if ([state isEqualToString:@"locked"]) {
            return @"🔒 Locked";
        } else if ([state isEqualToString:@"unlocked"]) {
            return @"🔓 Unlocked";
        } else if ([state isEqualToString:@"locking"]) {
            return @"🔒 Locking...";
        } else if ([state isEqualToString:@"unlocking"]) {
            return @"🔓 Unlocking...";
        }
        return [state capitalizedString];
    }
    
    return [state capitalizedString];
}

- (void)updateCardAppearanceForEntity:(NSDictionary *)entity {
    NSString *entityId = entity[@"entity_id"];
    NSString *state = entity[@"state"];
    
    if ([entityId hasPrefix:@"light."]) {
        if ([state isEqualToString:@"on"]) {
            // Light is on - warm yellow background
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.8 alpha:1.0];
            self.nameLabel.textColor = [UIColor colorWithRed:0.8 green:0.6 blue:0.0 alpha:1.0];
            self.cardContainerView.layer.borderWidth = 2.0;
            self.cardContainerView.layer.borderColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0].CGColor;
        } else {
            // Light is off - default appearance
            self.cardContainerView.backgroundColor = [UIColor whiteColor];
            self.nameLabel.textColor = [UIColor darkTextColor];
            self.cardContainerView.layer.borderWidth = 0.0;
        }
    } else if ([entityId hasPrefix:@"switch."]) {
        if ([state isEqualToString:@"on"]) {
            // Switch is on - light blue background
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:0.9 green:0.95 blue:1.0 alpha:1.0];
            self.nameLabel.textColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
            self.cardContainerView.layer.borderWidth = 2.0;
            self.cardContainerView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.7 blue:1.0 alpha:1.0].CGColor;
        } else {
            // Switch is off - default appearance
            self.cardContainerView.backgroundColor = [UIColor whiteColor];
            self.nameLabel.textColor = [UIColor darkTextColor];
            self.cardContainerView.layer.borderWidth = 0.0;
        }
    } else if ([entityId hasPrefix:@"fan."]) {
        if ([state isEqualToString:@"on"]) {
            // Fan is on - light green background
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:0.9 green:1.0 blue:0.9 alpha:1.0];
            self.nameLabel.textColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.0 alpha:1.0];
            self.cardContainerView.layer.borderWidth = 2.0;
            self.cardContainerView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0].CGColor;
        } else {
            // Fan is off - default appearance
            self.cardContainerView.backgroundColor = [UIColor whiteColor];
            self.nameLabel.textColor = [UIColor darkTextColor];
            self.cardContainerView.layer.borderWidth = 0.0;
        }
    } else if ([entityId hasPrefix:@"climate."]) {
        // Climate - orange/red tint, always interactive
        if ([state isEqualToString:@"off"]) {
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
            self.nameLabel.textColor = [UIColor grayColor];
        } else {
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.9 alpha:1.0];
            self.nameLabel.textColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        }
        self.cardContainerView.layer.borderWidth = 1.0;
        self.cardContainerView.layer.borderColor = [UIColor colorWithRed:1.0 green:0.7 blue:0.3 alpha:1.0].CGColor;
    } else if ([entityId hasPrefix:@"cover."]) {
        // Cover - purple tint, interactive
        if ([state isEqualToString:@"open"]) {
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:0.95 green:0.9 blue:1.0 alpha:1.0];
            self.nameLabel.textColor = [UIColor colorWithRed:0.6 green:0.3 blue:0.9 alpha:1.0];
        } else if ([state isEqualToString:@"closed"]) {
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.95 alpha:1.0];
            self.nameLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.7 alpha:1.0];
        } else {
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:0.92 green:0.89 blue:0.97 alpha:1.0];
            self.nameLabel.textColor = [UIColor colorWithRed:0.55 green:0.4 blue:0.8 alpha:1.0];
        }
        self.cardContainerView.layer.borderWidth = 1.0;
        self.cardContainerView.layer.borderColor = [UIColor colorWithRed:0.7 green:0.5 blue:0.9 alpha:1.0].CGColor;
    } else if ([entityId hasPrefix:@"lock."]) {
        // Lock - red/green based on state, interactive
        if ([state isEqualToString:@"locked"]) {
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:0.9 green:1.0 blue:0.9 alpha:1.0];
            self.nameLabel.textColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.0 alpha:1.0];
            self.cardContainerView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0].CGColor;
        } else {
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:1.0 green:0.9 blue:0.9 alpha:1.0];
            self.nameLabel.textColor = [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0];
            self.cardContainerView.layer.borderColor = [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0].CGColor;
        }
        self.cardContainerView.layer.borderWidth = 2.0;
    } else if ([entityId hasPrefix:@"sensor."] || [entityId hasPrefix:@"binary_sensor."]) {
        // Sensors - light gray background, read-only
        self.cardContainerView.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];
        self.nameLabel.textColor = [UIColor darkTextColor];
        self.cardContainerView.layer.borderWidth = 0.0;
    } else {
        // Default appearance
        self.cardContainerView.backgroundColor = [UIColor whiteColor];
        self.nameLabel.textColor = [UIColor darkTextColor];
        self.cardContainerView.layer.borderWidth = 0.0;
    }
}

#pragma mark - Resize Handles Setup

- (void)setupResizeHandles {
    // Create resize handles with iOS 18 style
    CGFloat handleSize = 20.0;
    UIColor *handleColor = [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0]; // iOS blue
    
    // Bottom-right handle (primary resize handle)
    self.resizeHandleBottomRight = [[UIView alloc] initWithFrame:CGRectMake(0, 0, handleSize, handleSize)];
    self.resizeHandleBottomRight.backgroundColor = handleColor;
    self.resizeHandleBottomRight.layer.cornerRadius = handleSize / 2;
    self.resizeHandleBottomRight.layer.borderWidth = 2.0;
    self.resizeHandleBottomRight.layer.borderColor = [UIColor whiteColor].CGColor;
    self.resizeHandleBottomRight.hidden = YES; // Hidden by default
    [self.cardContainerView addSubview:self.resizeHandleBottomRight];
    
    // Top-left handle
    self.resizeHandleTopLeft = [[UIView alloc] initWithFrame:CGRectMake(0, 0, handleSize, handleSize)];
    self.resizeHandleTopLeft.backgroundColor = handleColor;
    self.resizeHandleTopLeft.layer.cornerRadius = handleSize / 2;
    self.resizeHandleTopLeft.layer.borderWidth = 2.0;
    self.resizeHandleTopLeft.layer.borderColor = [UIColor whiteColor].CGColor;
    self.resizeHandleTopLeft.hidden = YES;
    [self.cardContainerView addSubview:self.resizeHandleTopLeft];
    
    // Top-right handle
    self.resizeHandleTopRight = [[UIView alloc] initWithFrame:CGRectMake(0, 0, handleSize, handleSize)];
    self.resizeHandleTopRight.backgroundColor = handleColor;
    self.resizeHandleTopRight.layer.cornerRadius = handleSize / 2;
    self.resizeHandleTopRight.layer.borderWidth = 2.0;
    self.resizeHandleTopRight.layer.borderColor = [UIColor whiteColor].CGColor;
    self.resizeHandleTopRight.hidden = YES;
    [self.cardContainerView addSubview:self.resizeHandleTopRight];
    
    // Bottom-left handle
    self.resizeHandleBottomLeft = [[UIView alloc] initWithFrame:CGRectMake(0, 0, handleSize, handleSize)];
    self.resizeHandleBottomLeft.backgroundColor = handleColor;
    self.resizeHandleBottomLeft.layer.cornerRadius = handleSize / 2;
    self.resizeHandleBottomLeft.layer.borderWidth = 2.0;
    self.resizeHandleBottomLeft.layer.borderColor = [UIColor whiteColor].CGColor;
    self.resizeHandleBottomLeft.hidden = YES;
    [self.cardContainerView addSubview:self.resizeHandleBottomLeft];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Position resize handles at the corners
    CGFloat handleSize = 20.0;
    CGFloat offset = handleSize / 2;
    CGRect bounds = self.cardContainerView.bounds;
    
    // Position handles at corners
    self.resizeHandleTopLeft.center = CGPointMake(-offset, -offset);
    self.resizeHandleTopRight.center = CGPointMake(bounds.size.width + offset, -offset);
    self.resizeHandleBottomLeft.center = CGPointMake(-offset, bounds.size.height + offset);
    self.resizeHandleBottomRight.center = CGPointMake(bounds.size.width + offset, bounds.size.height + offset);
}

- (void)setEditModeEnabled:(BOOL)enabled animated:(BOOL)animated {
    if (_editModeEnabled == enabled) return;
    
    _editModeEnabled = enabled;
    
    // Show/hide resize handles
    void (^animationBlock)(void) = ^{
        self.resizeHandleBottomRight.alpha = enabled ? 1.0 : 0.0;
        self.resizeHandleTopLeft.alpha = enabled ? 1.0 : 0.0;
        self.resizeHandleTopRight.alpha = enabled ? 1.0 : 0.0;
        self.resizeHandleBottomLeft.alpha = enabled ? 1.0 : 0.0;
        
        // Add subtle border in edit mode
        if (enabled) {
            self.cardContainerView.layer.borderWidth = 1.0;
            self.cardContainerView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:0.3].CGColor;
        } else {
            // Only remove edit border, preserve entity state borders
            if (self.cardContainerView.layer.borderColor == [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:0.3].CGColor) {
                self.cardContainerView.layer.borderWidth = 0.0;
            }
        }
    };
    
    // Show/hide handles immediately
    self.resizeHandleBottomRight.hidden = !enabled;
    self.resizeHandleTopLeft.hidden = !enabled;
    self.resizeHandleTopRight.hidden = !enabled;
    self.resizeHandleBottomLeft.hidden = !enabled;
    
    if (animated) {
        // Set initial alpha for animation
        if (enabled) {
            self.resizeHandleBottomRight.alpha = 0.0;
            self.resizeHandleTopLeft.alpha = 0.0;
            self.resizeHandleTopRight.alpha = 0.0;
            self.resizeHandleBottomLeft.alpha = 0.0;
        }
        
        [UIView animateWithDuration:0.3 animations:animationBlock];
    } else {
        animationBlock();
    }
}

@end