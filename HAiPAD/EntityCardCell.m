//
//  EntityCardCell.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "EntityCardCell.h"

@interface EntityCardCell ()
@property (nonatomic, strong) UIPanGestureRecognizer *resizeGesture;
@property (nonatomic, assign) CGPoint resizeStartSize;
@property (nonatomic, assign) CGPoint resizeStartPoint;
@end

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
    
    // Configure labels (iOS 9.3.5 compatible)
    self.nameLabel.font = [UIFont systemFontOfSize:16]; // UIFontWeightMedium not available in iOS 9.3.5
    self.stateLabel.font = [UIFont systemFontOfSize:14];
    self.stateLabel.textColor = [UIColor grayColor];
    
    // Configure info button
    self.infoButton.layer.cornerRadius = 10.0;
    self.infoButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    [self.infoButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    // Initialize properties
    self.gridSize = CGSizeMake(1, 1); // Default 1x1 grid size
    self.editingMode = NO;
    
    // Create resize handle
    [self createResizeHandle];
}

- (void)createResizeHandle {
    // Create resize handle view with improved appearance
    self.resizeHandle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
    self.resizeHandle.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.98];
    self.resizeHandle.layer.cornerRadius = 14.0;
    self.resizeHandle.layer.borderWidth = 1.0;
    self.resizeHandle.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:0.9].CGColor;
    
    // Add subtle shadow for depth
    self.resizeHandle.layer.shadowColor = [UIColor blackColor].CGColor;
    self.resizeHandle.layer.shadowOffset = CGSizeMake(0, 1);
    self.resizeHandle.layer.shadowOpacity = 0.15;
    self.resizeHandle.layer.shadowRadius = 2.0;
    
    self.resizeHandle.hidden = YES;
    
    // Add curved handle lines
    [self addResizeHandleIndicator];
    
    // Add to card container
    [self.cardContainerView addSubview:self.resizeHandle];
    
    // Position in bottom right corner with slight padding
    self.resizeHandle.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.resizeHandle.trailingAnchor constraintEqualToAnchor:self.cardContainerView.trailingAnchor constant:-2],
        [self.resizeHandle.bottomAnchor constraintEqualToAnchor:self.cardContainerView.bottomAnchor constant:-2],
        [self.resizeHandle.widthAnchor constraintEqualToConstant:28],
        [self.resizeHandle.heightAnchor constraintEqualToConstant:28]
    ]];
    
    // Add pan gesture for resizing
    self.resizeGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleResizeGesture:)];
    [self.resizeHandle addGestureRecognizer:self.resizeGesture];
}

- (void)addResizeHandleIndicator {
    // Create elegant curved corner handle similar to the reference image
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    // Create a smooth curved corner that starts from the center and curves outward
    // This creates a more elegant appearance similar to the reference image
    
    // Main curved line that flows from top-right to bottom-right corner
    [path moveToPoint:CGPointMake(12, 8)];
    [path addQuadCurveToPoint:CGPointMake(18, 12) controlPoint:CGPointMake(16, 9)];
    [path addQuadCurveToPoint:CGPointMake(16, 18) controlPoint:CGPointMake(19, 15)];
    
    // Add a second complementary curve for better visual balance
    [path moveToPoint:CGPointMake(8, 12)];
    [path addQuadCurveToPoint:CGPointMake(12, 16) controlPoint:CGPointMake(9, 15)];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = path.CGPath;
    shapeLayer.strokeColor = [UIColor colorWithWhite:0.5 alpha:0.8].CGColor;
    shapeLayer.lineWidth = 2.0;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.lineCap = kCALineCapRound;
    shapeLayer.lineJoin = kCALineJoinRound;
    
    [self.resizeHandle.layer addSublayer:shapeLayer];
}

- (void)handleResizeGesture:(UIPanGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.resizeStartPoint = [gesture locationInView:self.superview];
            self.resizeStartSize = CGPointMake(self.gridSize.width, self.gridSize.height);
            
            if ([self.delegate respondsToSelector:@selector(entityCardCell:didBeginResizing:)]) {
                [self.delegate entityCardCell:self didBeginResizing:gesture];
            }
            break;
            
        case UIGestureRecognizerStateChanged: {
            CGPoint currentPoint = [gesture locationInView:self.superview];
            CGPoint translation = CGPointMake(currentPoint.x - self.resizeStartPoint.x,
                                           currentPoint.y - self.resizeStartPoint.y);
            
            // Calculate new grid size based on translation
            // Use a more responsive calculation with smaller threshold
            CGFloat gridCellSize = 80.0; // Reduced for more responsive feedback
            NSInteger newWidth = MAX(1, self.resizeStartSize.x + (NSInteger)(translation.x / gridCellSize));
            NSInteger newHeight = MAX(1, self.resizeStartSize.y + (NSInteger)(translation.y / gridCellSize));
            
            // Limit maximum size to reasonable bounds (adjust based on grid size)
            newWidth = MIN(newWidth, 4);  // Max 4 cells wide
            newHeight = MIN(newHeight, 3); // Max 3 cells tall
            
            CGSize newGridSize = CGSizeMake(newWidth, newHeight);
            
            if (!CGSizeEqualToSize(self.gridSize, newGridSize)) {
                self.gridSize = newGridSize;
                
                if ([self.delegate respondsToSelector:@selector(entityCardCell:didUpdateResizing:)]) {
                    [self.delegate entityCardCell:self didUpdateResizing:gesture];
                }
            }
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            if ([self.delegate respondsToSelector:@selector(entityCardCell:didEndResizing:)]) {
                [self.delegate entityCardCell:self didEndResizing:gesture];
            }
            
            if ([self.delegate respondsToSelector:@selector(entityCardCell:didRequestSizeChange:)]) {
                [self.delegate entityCardCell:self didRequestSizeChange:self.gridSize];
            }
            break;
            
        default:
            break;
    }
}

- (void)setEditingMode:(BOOL)editingMode animated:(BOOL)animated {
    if (_editingMode == editingMode) return;
    
    _editingMode = editingMode;
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.resizeHandle.alpha = editingMode ? 1.0 : 0.0;
        } completion:^(BOOL finished) {
            self.resizeHandle.hidden = !editingMode;
        }];
        
        if (editingMode) {
            self.resizeHandle.hidden = NO;
            [self startWiggleAnimation];
        } else {
            [self stopWiggleAnimation];
        }
    } else {
        self.resizeHandle.hidden = !editingMode;
        self.resizeHandle.alpha = editingMode ? 1.0 : 0.0;
        
        if (editingMode) {
            [self startWiggleAnimation];
        } else {
            [self stopWiggleAnimation];
        }
    }
}

- (void)startWiggleAnimation {
    // Create subtle wiggle animation similar to iOS widgets
    CAKeyframeAnimation *wiggleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
    wiggleAnimation.values = @[@0.0, @(-M_PI/180), @0.0, @(M_PI/180), @0.0];
    wiggleAnimation.keyTimes = @[@0.0, @0.25, @0.5, @0.75, @1.0];
    wiggleAnimation.duration = 1.5;
    wiggleAnimation.repeatCount = HUGE_VALF;
    wiggleAnimation.autoreverses = NO;
    
    [self.cardContainerView.layer addAnimation:wiggleAnimation forKey:@"wiggle"];
}

- (void)stopWiggleAnimation {
    [self.cardContainerView.layer removeAnimationForKey:@"wiggle"];
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
    
    // Reset resize properties
    self.gridSize = CGSizeMake(1, 1);
    [self setEditingMode:NO animated:NO];
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