//
//  InputBooleanView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "InputBooleanView.h"
#import "UIColor+HAiPAD.h"

@interface InputBooleanView ()
@property (nonatomic, strong) UISwitch *toggleSwitch;
@property (nonatomic, strong) UIImageView *statusIcon;
@end

@implementation InputBooleanView

- (void)setupEntitySpecificUI {
    // Create large toggle switch in center
    self.toggleSwitch = [[UISwitch alloc] init];
    self.toggleSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toggleSwitch addTarget:self action:@selector(toggleSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.cardContainer addSubview:self.toggleSwitch];
    
    // Create status icon
    self.statusIcon = [[UIImageView alloc] init];
    self.statusIcon.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.statusIcon.image = [self createCheckIcon];
    [self.cardContainer addSubview:self.statusIcon];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Toggle switch in center
        [self.toggleSwitch.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.toggleSwitch.centerYAnchor constraintEqualToAnchor:self.cardContainer.centerYAnchor constant:-8],
        
        // Status icon above switch
        [self.statusIcon.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.statusIcon.bottomAnchor constraintEqualToAnchor:self.toggleSwitch.topAnchor constant:-8],
        [self.statusIcon.widthAnchor constraintEqualToConstant:24],
        [self.statusIcon.heightAnchor constraintEqualToConstant:24]
    ]];
}

- (void)updateWithEntity:(NSDictionary *)entity {
    [super updateWithEntity:entity];
    
    NSString *state = [self state];
    BOOL isOn = [state isEqualToString:@"on"];
    
    self.toggleSwitch.on = isOn;
    self.statusIcon.tintColor = isOn ? [UIColor ha_systemGreenColor] : [UIColor lightGrayColor];
    
    // Update state label
    self.stateLabel.text = isOn ? @"On" : @"Off";
}

- (UIColor *)colorForEntityState {
    NSString *state = [self state];
    if ([state isEqualToString:@"on"]) {
        return [UIColor colorWithRed:0.9 green:1.0 blue:0.95 alpha:1.0]; // Light green
    }
    return [UIColor whiteColor];
}

- (UIImage *)createCheckIcon {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    CGContextSetLineCap(context, kCGLineCapRound);
    
    // Draw checkmark
    CGContextMoveToPoint(context, 6, 12);
    CGContextAddLineToPoint(context, 10, 16);
    CGContextAddLineToPoint(context, 18, 8);
    CGContextStrokePath(context);
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

#pragma mark - Actions

- (void)toggleSwitchChanged:(UISwitch *)sender {
    NSString *service = sender.isOn ? @"turn_on" : @"turn_off";
    
    if ([self.delegate respondsToSelector:@selector(entityView:didRequestServiceCall:service:entityId:parameters:)]) {
        [self.delegate entityView:self didRequestServiceCall:@"input_boolean" service:service entityId:[self entityId] parameters:nil];
    }
}

@end
