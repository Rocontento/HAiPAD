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
    
    // Create resize handle (iOS 18 style curved line)
    [self createResizeHandle];
}

- (void)createResizeHandle {
    self.resizeHandle = [[UIView alloc] init];
    self.resizeHandle.backgroundColor = [UIColor clearColor];
    self.resizeHandle.hidden = YES; // Initially hidden, shown only in edit mode
    [self.cardContainerView addSubview:self.resizeHandle];
    
    // Create the curved lines using CAShapeLayer (iOS 9.3.5 compatible)
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    
    // Create path for the resize handle (similar to iOS 18 widget resize handle)
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    // Draw three small curved lines in the bottom-right corner
    CGFloat lineLength = 8.0;
    CGFloat spacing = 3.0;
    CGFloat cornerOffset = 8.0;
    
    for (int i = 0; i < 3; i++) {
        CGFloat startX = lineLength - (i * spacing);
        CGFloat startY = (i * spacing);
        CGFloat endX = 0;
        CGFloat endY = startY + lineLength;
        
        [path moveToPoint:CGPointMake(startX, startY)];
        [path addLineToPoint:CGPointMake(endX, endY)];
    }
    
    shapeLayer.path = path.CGPath;
    shapeLayer.strokeColor = [UIColor colorWithWhite:0.6 alpha:1.0].CGColor;
    shapeLayer.lineWidth = 1.5;
    shapeLayer.lineCap = kCALineCapRound;
    
    [self.resizeHandle.layer addSublayer:shapeLayer];
    self.resizeHandle.tag = 999; // Tag to identify the shape layer
    
    // Add pan gesture recognizer for resizing
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleResizePan:)];
    [self.resizeHandle addGestureRecognizer:panGesture];
}

- (void)handleResizePan:(UIPanGestureRecognizer *)gesture {
    if ([self.delegate respondsToSelector:@selector(entityCardCell:didStartResizing:)] ||
        [self.delegate respondsToSelector:@selector(entityCardCell:didResize:)] ||
        [self.delegate respondsToSelector:@selector(entityCardCell:didEndResizing:)]) {
        
        switch (gesture.state) {
            case UIGestureRecognizerStateBegan:
                if ([self.delegate respondsToSelector:@selector(entityCardCell:didStartResizing:)]) {
                    [self.delegate entityCardCell:self didStartResizing:gesture];
                }
                break;
                
            case UIGestureRecognizerStateChanged:
                if ([self.delegate respondsToSelector:@selector(entityCardCell:didResize:)]) {
                    [self.delegate entityCardCell:self didResize:gesture];
                }
                break;
                
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateCancelled:
                if ([self.delegate respondsToSelector:@selector(entityCardCell:didEndResizing:)]) {
                    [self.delegate entityCardCell:self didEndResizing:gesture];
                }
                break;
                
            default:
                break;
        }
    }
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
    
    // Hide resize handle by default
    self.resizeHandle.hidden = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Position resize handle in bottom-right corner
    CGFloat handleSize = 20.0;
    CGFloat cornerOffset = 5.0;
    self.resizeHandle.frame = CGRectMake(
        self.cardContainerView.bounds.size.width - handleSize - cornerOffset,
        self.cardContainerView.bounds.size.height - handleSize - cornerOffset,
        handleSize,
        handleSize
    );
}

- (void)setEditingMode:(BOOL)editingMode {
    self.resizeHandle.hidden = !editingMode;
    
    if (editingMode) {
        // Add subtle highlight to indicate card is resizable
        self.cardContainerView.layer.borderWidth = 1.0;
        self.cardContainerView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.3].CGColor;
    } else {
        // Remove highlight
        self.cardContainerView.layer.borderWidth = 0.0;
        self.cardContainerView.layer.borderColor = [UIColor clearColor].CGColor;
    }
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

@end