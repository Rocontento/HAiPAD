//
//  CoverView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "CoverView.h"
#import "UIColor+HAiPAD.h"

@interface CoverView ()
@property (nonatomic, strong) UIButton *openButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UILabel *positionLabel;
@property (nonatomic, strong) UIProgressView *positionIndicator;
@end

@implementation CoverView

- (void)setupEntitySpecificUI {
    // Create position indicator
    self.positionIndicator = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.positionIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.positionIndicator.progressTintColor = [UIColor ha_systemBlueColor];
    [self.cardContainer addSubview:self.positionIndicator];
    
    // Create position label
    self.positionLabel = [[UILabel alloc] init];
    self.positionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.positionLabel.font = [UIFont systemFontOfSize:12];
    self.positionLabel.textColor = [UIColor grayColor];
    self.positionLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardContainer addSubview:self.positionLabel];
    
    // Create control buttons
    self.openButton = [self createControlButtonWithTitle:@"▲" action:@selector(openButtonTapped:)];
    self.stopButton = [self createControlButtonWithTitle:@"◼" action:@selector(stopButtonTapped:)];
    self.closeButton = [self createControlButtonWithTitle:@"▼" action:@selector(closeButtonTapped:)];
    
    [self.cardContainer addSubview:self.openButton];
    [self.cardContainer addSubview:self.stopButton];
    [self.cardContainer addSubview:self.closeButton];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Position indicator at top
        [self.positionIndicator.topAnchor constraintEqualToAnchor:self.cardContainer.topAnchor constant:12],
        [self.positionIndicator.leadingAnchor constraintEqualToAnchor:self.cardContainer.leadingAnchor constant:16],
        [self.positionIndicator.trailingAnchor constraintEqualToAnchor:self.cardContainer.trailingAnchor constant:-16],
        
        // Position label below indicator
        [self.positionLabel.topAnchor constraintEqualToAnchor:self.positionIndicator.bottomAnchor constant:4],
        [self.positionLabel.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        
        // Buttons in vertical arrangement
        [self.openButton.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.openButton.topAnchor constraintEqualToAnchor:self.positionLabel.bottomAnchor constant:8],
        [self.openButton.widthAnchor constraintEqualToConstant:40],
        [self.openButton.heightAnchor constraintEqualToConstant:30],
        
        [self.stopButton.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.stopButton.topAnchor constraintEqualToAnchor:self.openButton.bottomAnchor constant:4],
        [self.stopButton.widthAnchor constraintEqualToConstant:40],
        [self.stopButton.heightAnchor constraintEqualToConstant:30],
        
        [self.closeButton.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.closeButton.topAnchor constraintEqualToAnchor:self.stopButton.bottomAnchor constant:4],
        [self.closeButton.widthAnchor constraintEqualToConstant:40],
        [self.closeButton.heightAnchor constraintEqualToConstant:30]
    ]];
}

- (UIButton *)createControlButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
    [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    button.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    button.layer.cornerRadius = 6.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)updateWithEntity:(NSDictionary *)entity {
    [super updateWithEntity:entity];
    
    NSString *state = [self state];
    NSDictionary *attributes = [self attributes];
    NSNumber *position = attributes[@"current_position"];
    
    // Update position indicator and label
    if (position) {
        float positionValue = position.floatValue / 100.0; // Convert to 0-1 range
        self.positionIndicator.progress = positionValue;
        self.positionLabel.text = [NSString stringWithFormat:@"%d%% open", position.intValue];
    } else {
        // No position data, just show state
        if ([state isEqualToString:@"open"]) {
            self.positionIndicator.progress = 1.0;
            self.positionLabel.text = @"Open";
        } else if ([state isEqualToString:@"closed"]) {
            self.positionIndicator.progress = 0.0;
            self.positionLabel.text = @"Closed";
        } else {
            self.positionIndicator.progress = 0.5;
            self.positionLabel.text = [state capitalizedString];
        }
    }
    
    // Update button states based on current state
    BOOL isMoving = [state isEqualToString:@"opening"] || [state isEqualToString:@"closing"];
    self.openButton.enabled = !isMoving && ![state isEqualToString:@"open"];
    self.closeButton.enabled = !isMoving && ![state isEqualToString:@"closed"];
    self.stopButton.enabled = isMoving;
    
    // Visual feedback for moving state
    if (isMoving) {
        self.stopButton.backgroundColor = [UIColor ha_systemOrangeColor];
        [self.stopButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        self.stopButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        [self.stopButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
    }
    
    // Update state label
    if (position) {
        self.stateLabel.text = [NSString stringWithFormat:@"%d%% • %@", position.intValue, [state capitalizedString]];
    } else {
        self.stateLabel.text = [state capitalizedString];
    }
}

- (UIColor *)colorForEntityState {
    NSString *state = [self state];
    if ([state isEqualToString:@"open"]) {
        return [UIColor colorWithRed:0.95 green:0.98 blue:1.0 alpha:1.0]; // Light blue
    } else if ([state isEqualToString:@"opening"] || [state isEqualToString:@"closing"]) {
        return [UIColor colorWithRed:1.0 green:0.97 blue:0.9 alpha:1.0]; // Light orange
    }
    return [UIColor whiteColor];
}

#pragma mark - Actions

- (void)openButtonTapped:(UIButton *)sender {
    [self addButtonTapAnimation:sender];
    if ([self.delegate respondsToSelector:@selector(entityView:didRequestServiceCall:service:entityId:parameters:)]) {
        [self.delegate entityView:self didRequestServiceCall:@"cover" service:@"open_cover" entityId:[self entityId] parameters:nil];
    }
}

- (void)closeButtonTapped:(UIButton *)sender {
    [self addButtonTapAnimation:sender];
    if ([self.delegate respondsToSelector:@selector(entityView:didRequestServiceCall:service:entityId:parameters:)]) {
        [self.delegate entityView:self didRequestServiceCall:@"cover" service:@"close_cover" entityId:[self entityId] parameters:nil];
    }
}

- (void)stopButtonTapped:(UIButton *)sender {
    [self addButtonTapAnimation:sender];
    if ([self.delegate respondsToSelector:@selector(entityView:didRequestServiceCall:service:entityId:parameters:)]) {
        [self.delegate entityView:self didRequestServiceCall:@"cover" service:@"stop_cover" entityId:[self entityId] parameters:nil];
    }
}

- (void)addButtonTapAnimation:(UIButton *)button {
    [UIView animateWithDuration:0.1 animations:^{
        button.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            button.transform = CGAffineTransformIdentity;
        }];
    }];
}

@end
