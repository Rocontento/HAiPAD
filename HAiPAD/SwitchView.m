//
//  SwitchView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "SwitchView.h"

@implementation SwitchView

- (void)setupEntitySpecificUI {
    // Create the main toggle button that fills most of the card
    self.toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.toggleButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.toggleButton.layer.cornerRadius = 8.0;
    self.toggleButton.layer.borderWidth = 2.0;
    [self.toggleButton addTarget:self action:@selector(toggleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.cardContainer addSubview:self.toggleButton];
    
    // Create icon view
    self.iconView = [[UIImageView alloc] init];
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconView.tintColor = [UIColor grayColor];
    [self.toggleButton addSubview:self.iconView];
    
    // Use a power icon as default
    UIImage *powerIcon = [self createPowerIcon];
    self.iconView.image = powerIcon;
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Toggle button fills most of the card above the labels
        [self.toggleButton.topAnchor constraintEqualToAnchor:self.cardContainer.topAnchor constant:8],
        [self.toggleButton.leadingAnchor constraintEqualToAnchor:self.cardContainer.leadingAnchor constant:8],
        [self.toggleButton.trailingAnchor constraintEqualToAnchor:self.cardContainer.trailingAnchor constant:-8],
        [self.toggleButton.bottomAnchor constraintEqualToAnchor:self.nameLabel.topAnchor constant:-8],
        
        // Icon centered in button
        [self.iconView.centerXAnchor constraintEqualToAnchor:self.toggleButton.centerXAnchor],
        [self.iconView.centerYAnchor constraintEqualToAnchor:self.toggleButton.centerYAnchor],
        [self.iconView.widthAnchor constraintEqualToConstant:32],
        [self.iconView.heightAnchor constraintEqualToConstant:32]
    ]];
}

- (void)updateWithEntity:(NSDictionary *)entity {
    [super updateWithEntity:entity];
    
    NSString *state = [self state];
    BOOL isOn = [state isEqualToString:@"on"];
    
    if (isOn) {
        self.toggleButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.7 blue:1.0 alpha:1.0]; // Blue when on
        self.toggleButton.layer.borderColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.8 alpha:1.0].CGColor;
        self.iconView.tintColor = [UIColor whiteColor];
        self.stateLabel.text = @"On";
    } else {
        self.toggleButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0]; // Gray when off
        self.toggleButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.iconView.tintColor = [UIColor grayColor];
        self.stateLabel.text = @"Off";
    }
    
    // Add haptic feedback animation
    [self addTouchAnimation];
}

- (UIColor *)colorForEntityState {
    NSString *state = [self state];
    if ([state isEqualToString:@"on"]) {
        return [UIColor colorWithRed:0.95 green:0.98 blue:1.0 alpha:1.0]; // Light blue background
    }
    return [UIColor whiteColor];
}

- (UIImage *)createPowerIcon {
    // Create a simple power icon using Core Graphics
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(32, 32), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set line width and color
    CGContextSetLineWidth(context, 3.0);
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextSetLineCap(context, kCGLineCapRound);
    
    // Draw power symbol (circle with line at top)
    CGPoint center = CGPointMake(16, 16);
    CGFloat radius = 10;
    
    // Draw arc (circle without the top part)
    CGContextAddArc(context, center.x, center.y, radius, M_PI * 0.75, M_PI * 0.25, 0);
    CGContextStrokePath(context);
    
    // Draw vertical line at top
    CGContextMoveToPoint(context, center.x, center.y - radius - 3);
    CGContextAddLineToPoint(context, center.x, center.y - 3);
    CGContextStrokePath(context);
    
    UIImage *powerIcon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return powerIcon;
}

- (void)addTouchAnimation {
    // Add subtle scale animation on touch
    CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.values = @[@1.0, @0.95, @1.0];
    scaleAnimation.keyTimes = @[@0.0, @0.5, @1.0];
    scaleAnimation.duration = 0.2;
    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [self.toggleButton.layer addAnimation:scaleAnimation forKey:@"touchScale"];
}

#pragma mark - Actions

- (void)toggleButtonTapped:(UIButton *)sender {
    NSString *state = [self state];
    NSString *service = [state isEqualToString:@"on"] ? @"turn_off" : @"turn_on";
    
    // Add visual feedback
    [self addTouchAnimation];
    
    if ([self.delegate respondsToSelector:@selector(entityView:didRequestServiceCall:service:entityId:parameters:)]) {
        [self.delegate entityView:self didRequestServiceCall:@"switch" service:service entityId:[self entityId] parameters:nil];
    }
}

@end