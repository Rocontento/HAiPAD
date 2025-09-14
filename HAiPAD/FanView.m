//
//  FanView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "FanView.h"
#import "UIColor+HAiPAD.h"

@interface FanView ()
@property (nonatomic, strong) UISwitch *toggleSwitch;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) UILabel *speedLabel;
@property (nonatomic, strong) UIImageView *fanIcon;
@property (nonatomic, strong) CADisplayLink *animationLink;
@property (nonatomic, assign) CGFloat rotationAngle;
@end

@implementation FanView

- (void)setupEntitySpecificUI {
    // Create fan icon with rotation animation
    self.fanIcon = [[UIImageView alloc] init];
    self.fanIcon.translatesAutoresizingMaskIntoConstraints = NO;
    self.fanIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.fanIcon.image = [self createFanIcon];
    self.fanIcon.tintColor = [UIColor grayColor];
    [self.cardContainer addSubview:self.fanIcon];
    
    // Create toggle switch
    self.toggleSwitch = [[UISwitch alloc] init];
    self.toggleSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toggleSwitch addTarget:self action:@selector(toggleSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.cardContainer addSubview:self.toggleSwitch];
    
    // Create speed slider
    self.speedSlider = [[UISlider alloc] init];
    self.speedSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.speedSlider.minimumValue = 0;
    self.speedSlider.maximumValue = 100;
    self.speedSlider.minimumTrackTintColor = [UIColor ha_systemGreenColor];
    [self.speedSlider addTarget:self action:@selector(speedSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.cardContainer addSubview:self.speedSlider];
    
    // Create speed label
    self.speedLabel = [[UILabel alloc] init];
    self.speedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.speedLabel.font = [UIFont systemFontOfSize:10];
    self.speedLabel.textColor = [UIColor grayColor];
    self.speedLabel.textAlignment = NSTextAlignmentCenter;
    self.speedLabel.text = @"Speed";
    [self.cardContainer addSubview:self.speedLabel];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Toggle switch in top-right
        [self.toggleSwitch.topAnchor constraintEqualToAnchor:self.cardContainer.topAnchor constant:12],
        [self.toggleSwitch.trailingAnchor constraintEqualToAnchor:self.cardContainer.trailingAnchor constant:-12],
        
        // Fan icon in center-left
        [self.fanIcon.centerYAnchor constraintEqualToAnchor:self.cardContainer.centerYAnchor constant:-8],
        [self.fanIcon.leadingAnchor constraintEqualToAnchor:self.cardContainer.leadingAnchor constant:16],
        [self.fanIcon.widthAnchor constraintEqualToConstant:32],
        [self.fanIcon.heightAnchor constraintEqualToConstant:32],
        
        // Speed label
        [self.speedLabel.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.speedLabel.bottomAnchor constraintEqualToAnchor:self.nameLabel.topAnchor constant:-4],
        
        // Speed slider
        [self.speedSlider.leadingAnchor constraintEqualToAnchor:self.fanIcon.trailingAnchor constant:8],
        [self.speedSlider.trailingAnchor constraintEqualToAnchor:self.cardContainer.trailingAnchor constant:-16],
        [self.speedSlider.bottomAnchor constraintEqualToAnchor:self.speedLabel.topAnchor constant:-4]
    ]];
}

- (void)updateWithEntity:(NSDictionary *)entity {
    [super updateWithEntity:entity];
    
    NSString *state = [self state];
    NSDictionary *attributes = [self attributes];
    BOOL isOn = [state isEqualToString:@"on"];
    
    self.toggleSwitch.on = isOn;
    
    // Update speed
    NSNumber *percentage = attributes[@"percentage"];
    if (percentage) {
        self.speedSlider.value = percentage.floatValue;
        self.speedSlider.enabled = isOn;
        self.speedSlider.alpha = isOn ? 1.0 : 0.5;
        self.speedLabel.text = [NSString stringWithFormat:@"Speed %d%%", percentage.intValue];
    } else {
        self.speedSlider.enabled = NO;
        self.speedSlider.alpha = 0.5;
        self.speedLabel.text = @"Speed";
    }
    
    // Update fan icon color and animation
    if (isOn) {
        self.fanIcon.tintColor = [UIColor ha_systemGreenColor];
        [self startFanAnimation];
    } else {
        self.fanIcon.tintColor = [UIColor grayColor];
        [self stopFanAnimation];
    }
    
    // Update state label
    if (isOn && percentage) {
        self.stateLabel.text = [NSString stringWithFormat:@"On • %d%%", percentage.intValue];
    } else {
        self.stateLabel.text = isOn ? @"On" : @"Off";
    }
}

- (UIColor *)colorForEntityState {
    NSString *state = [self state];
    if ([state isEqualToString:@"on"]) {
        return [UIColor colorWithRed:0.9 green:1.0 blue:0.95 alpha:1.0]; // Light green
    }
    return [UIColor whiteColor];
}

- (UIImage *)createFanIcon {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(32, 32), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    // Draw fan blades
    CGPoint center = CGPointMake(16, 16);
    for (int i = 0; i < 3; i++) {
        CGFloat angle = (i * 2 * M_PI / 3);
        CGFloat x1 = center.x + cos(angle) * 8;
        CGFloat y1 = center.y + sin(angle) * 8;
        CGFloat x2 = center.x + cos(angle + M_PI/6) * 12;
        CGFloat y2 = center.y + sin(angle + M_PI/6) * 12;
        CGFloat x3 = center.x + cos(angle - M_PI/6) * 12;
        CGFloat y3 = center.y + sin(angle - M_PI/6) * 12;
        
        CGContextMoveToPoint(context, x1, y1);
        CGContextAddLineToPoint(context, x2, y2);
        CGContextAddLineToPoint(context, x3, y3);
        CGContextClosePath(context);
        CGContextStrokePath(context);
    }
    
    // Draw center circle
    CGContextSetFillColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(13, 13, 6, 6));
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

- (void)startFanAnimation {
    if (self.animationLink) {
        [self stopFanAnimation];
    }
    
    self.animationLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFanRotation:)];
    [self.animationLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopFanAnimation {
    [self.animationLink invalidate];
    self.animationLink = nil;
}

- (void)updateFanRotation:(CADisplayLink *)displayLink {
    self.rotationAngle += 0.1; // Rotation speed
    self.fanIcon.transform = CGAffineTransformMakeRotation(self.rotationAngle);
}

- (void)dealloc {
    [self stopFanAnimation];
}

#pragma mark - Actions

- (void)toggleSwitchChanged:(UISwitch *)sender {
    NSString *service = sender.isOn ? @"turn_on" : @"turn_off";
    
    if ([self.delegate respondsToSelector:@selector(entityView:didRequestServiceCall:service:entityId:parameters:)]) {
        [self.delegate entityView:self didRequestServiceCall:@"fan" service:service entityId:[self entityId] parameters:nil];
    }
}

- (void)speedSliderChanged:(UISlider *)sender {
    if (![self.toggleSwitch isOn]) {
        return; // Don't change speed if fan is off
    }
    
    NSDictionary *parameters = @{@"percentage": @((int)sender.value)};
    
    if ([self.delegate respondsToSelector:@selector(entityView:didRequestServiceCall:service:entityId:parameters:)]) {
        [self.delegate entityView:self didRequestServiceCall:@"fan" service:@"set_percentage" entityId:[self entityId] parameters:parameters];
    }
}

@end
