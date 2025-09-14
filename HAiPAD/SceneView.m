//
//  SceneView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "SceneView.h"
#import "UIColor+HAiPAD.h"
#import <CoreGraphics/CoreGraphics.h>

@interface SceneView ()
@property (nonatomic, strong) UIButton *activateButton;
@property (nonatomic, strong) UIImageView *sceneIcon;
@end

@implementation SceneView

- (void)setupEntitySpecificUI {
    // Create main activation button
    self.activateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.activateButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.activateButton.backgroundColor = [UIColor ha_systemBlueColor];
    self.activateButton.layer.cornerRadius = 8.0;
    [self.activateButton setTitle:@"Activate" forState:UIControlStateNormal];
    [self.activateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.activateButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.activateButton addTarget:self action:@selector(activateButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.cardContainer addSubview:self.activateButton];
    
    // Create scene icon
    self.sceneIcon = [[UIImageView alloc] init];
    self.sceneIcon.translatesAutoresizingMaskIntoConstraints = NO;
    self.sceneIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.sceneIcon.image = [self createSceneIcon];
    self.sceneIcon.tintColor = [UIColor ha_systemBlueColor];
    [self.cardContainer addSubview:self.sceneIcon];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Scene icon at top
        [self.sceneIcon.topAnchor constraintEqualToAnchor:self.cardContainer.topAnchor constant:12],
        [self.sceneIcon.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.sceneIcon.widthAnchor constraintEqualToConstant:32],
        [self.sceneIcon.heightAnchor constraintEqualToConstant:32],
        
        // Activate button below icon
        [self.activateButton.topAnchor constraintEqualToAnchor:self.sceneIcon.bottomAnchor constant:8],
        [self.activateButton.leadingAnchor constraintEqualToAnchor:self.cardContainer.leadingAnchor constant:12],
        [self.activateButton.trailingAnchor constraintEqualToAnchor:self.cardContainer.trailingAnchor constant:-12],
        [self.activateButton.heightAnchor constraintEqualToConstant:36]
    ]];
}

- (void)updateWithEntity:(NSDictionary *)entity {
    [super updateWithEntity:entity];
    
    // Scenes don't really have states like other entities
    self.stateLabel.text = @"Tap to activate";
}

- (UIColor *)colorForEntityState {
    return [UIColor colorWithRed:0.95 green:0.98 blue:1.0 alpha:1.0]; // Light blue background
}

- (UIImage *)createSceneIcon {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(32, 32), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor ha_systemBlueColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    // Draw play button (triangle)
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 10, 8);
    CGPathAddLineToPoint(path, NULL, 24, 16);
    CGPathAddLineToPoint(path, NULL, 10, 24);
    CGPathCloseSubpath(path);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
    CGPathRelease(path);
    
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

#pragma mark - Actions

- (void)activateButtonTapped:(UIButton *)sender {
    // Add visual feedback
    [UIView animateWithDuration:0.1 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.95, 0.95);
        sender.backgroundColor = [UIColor ha_systemGreenColor];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            sender.transform = CGAffineTransformIdentity;
            sender.backgroundColor = [UIColor ha_systemBlueColor];
        }];
    }];
    
    if ([self.delegate respondsToSelector:@selector(entityView:didRequestServiceCall:service:entityId:parameters:)]) {
        [self.delegate entityView:self didRequestServiceCall:@"scene" service:@"turn_on" entityId:[self entityId] parameters:nil];
    }
}

@end
