//
//  CustomPopupViewController.m
//  HAiPAD
//
//  Custom popup view controller to replace system dialogs
//  Compatible with iOS 9.3.5
//

#import "CustomPopupViewController.h"

@interface CustomPopupViewController ()

@property (nonatomic, strong) UIView *backgroundOverlay;
@property (nonatomic, strong) UIView *popupContainer;
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *buttonContainer;
@property (nonatomic, strong) NSMutableArray *actionButtons;

@end

@implementation CustomPopupViewController

+ (instancetype)popupWithEntity:(NSDictionary *)entity 
                           type:(CustomPopupType)type 
                  actionHandler:(void(^)(NSString *action, NSDictionary *parameters))actionHandler {
    CustomPopupViewController *popup = [[CustomPopupViewController alloc] init];
    popup.entity = entity;
    popup.popupType = type;
    popup.actionHandler = actionHandler;
    return popup;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.actionButtons = [NSMutableArray array];
    [self setupBackgroundOverlay];
    [self setupPopupContainer];
    [self setupContentBasedOnType];
    [self layoutPopupContent];
}

- (void)setupBackgroundOverlay {
    // Semi-transparent background similar to Apple Home app
    self.backgroundOverlay = [[UIView alloc] init];
    self.backgroundOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
    self.backgroundOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Add tap gesture to dismiss
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    [self.backgroundOverlay addGestureRecognizer:tapGesture];
    
    [self.view addSubview:self.backgroundOverlay];
    
    // Pin to edges
    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundOverlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backgroundOverlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backgroundOverlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backgroundOverlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)setupPopupContainer {
    // Main popup container with modern card styling
    self.popupContainer = [[UIView alloc] init];
    self.popupContainer.backgroundColor = [UIColor whiteColor];
    self.popupContainer.layer.cornerRadius = 16.0;
    self.popupContainer.layer.masksToBounds = NO;
    
    // Shadow for iOS 9.3.5 compatibility
    self.popupContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.popupContainer.layer.shadowOffset = CGSizeMake(0, 8);
    self.popupContainer.layer.shadowOpacity = 0.2;
    self.popupContainer.layer.shadowRadius = 20.0;
    
    self.popupContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.popupContainer];
    
    // Center the popup and set max dimensions
    [NSLayoutConstraint activateConstraints:@[
        [self.popupContainer.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.popupContainer.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.popupContainer.widthAnchor constraintLessThanOrEqualToConstant:340.0],
        [self.popupContainer.widthAnchor constraintGreaterThanOrEqualToConstant:280.0],
        [self.popupContainer.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [self.popupContainer.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        [self.popupContainer.heightAnchor constraintLessThanOrEqualToConstant:500.0]
    ]];
}

- (void)setupContentBasedOnType {
    // Setup scroll view for content
    self.contentScrollView = [[UIScrollView alloc] init];
    self.contentScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.popupContainer addSubview:self.contentScrollView];
    
    // Content view inside scroll view
    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentScrollView addSubview:self.contentView];
    
    // Title label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor darkTextColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.titleLabel];
    
    // Set title based on entity
    NSString *friendlyName = self.entity[@"attributes"][@"friendly_name"] ?: self.entity[@"entity_id"];
    self.titleLabel.text = friendlyName;
    
    // Button container
    self.buttonContainer = [[UIView alloc] init];
    self.buttonContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.buttonContainer];
    
    // Setup content based on popup type
    switch (self.popupType) {
        case CustomPopupTypeInfo:
            [self setupInfoContent];
            break;
        case CustomPopupTypeClimateControl:
            [self setupClimateControlContent];
            break;
        case CustomPopupTypeCoverControl:
            [self setupCoverControlContent];
            break;
        case CustomPopupTypeLockControl:
            [self setupLockControlContent];
            break;
        case CustomPopupTypeSensorInfo:
            [self setupSensorInfoContent];
            break;
    }
}

- (void)layoutPopupContent {
    // Layout scroll view
    [NSLayoutConstraint activateConstraints:@[
        [self.contentScrollView.topAnchor constraintEqualToAnchor:self.popupContainer.topAnchor constant:20.0],
        [self.contentScrollView.leadingAnchor constraintEqualToAnchor:self.popupContainer.leadingAnchor constant:20.0],
        [self.contentScrollView.trailingAnchor constraintEqualToAnchor:self.popupContainer.trailingAnchor constant:-20.0],
        [self.contentScrollView.bottomAnchor constraintEqualToAnchor:self.popupContainer.bottomAnchor constant:-20.0]
    ]];
    
    // Layout content view
    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.topAnchor constraintEqualToAnchor:self.contentScrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.contentScrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.contentScrollView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.contentScrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.contentScrollView.widthAnchor]
    ]];
    
    // Layout title
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
    ]];
    
    // Layout button container
    [NSLayoutConstraint activateConstraints:@[
        [self.buttonContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.buttonContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.buttonContainer.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
    ]];
}

#pragma mark - Content Setup Methods

- (void)setupInfoContent {
    // Create info content similar to the original alert
    UILabel *infoLabel = [[UILabel alloc] init];
    infoLabel.font = [UIFont systemFontOfSize:14];
    infoLabel.textColor = [UIColor grayColor];
    infoLabel.numberOfLines = 0;
    infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:infoLabel];
    
    // Format entity information
    NSString *entityId = self.entity[@"entity_id"];
    NSString *state = self.entity[@"state"];
    NSMutableString *message = [NSMutableString stringWithFormat:@"Entity ID: %@\nState: %@", entityId, state];
    
    NSDictionary *attributes = self.entity[@"attributes"];
    if (attributes) {
        [message appendString:@"\n\nAttributes:"];
        for (NSString *key in attributes) {
            id value = attributes[key];
            [message appendFormat:@"\n%@: %@", key, value];
        }
    }
    
    infoLabel.text = message;
    
    // Layout info label
    [NSLayoutConstraint activateConstraints:@[
        [infoLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16.0],
        [infoLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [infoLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [infoLabel.bottomAnchor constraintEqualToAnchor:self.buttonContainer.topAnchor constant:-20.0]
    ]];
    
    // Add OK button
    [self addActionButton:@"OK" style:CustomPopupButtonStylePrimary action:@"dismiss"];
}

- (void)setupClimateControlContent {
    // Similar to the original climate control but with better UI
    NSString *state = self.entity[@"state"];
    NSNumber *currentTemp = self.entity[@"attributes"][@"current_temperature"];
    NSNumber *targetTemp = self.entity[@"attributes"][@"temperature"];
    NSString *unit = self.entity[@"attributes"][@"temperature_unit"] ?: @"°C";
    
    // Create temperature display
    UILabel *tempLabel = [[UILabel alloc] init];
    tempLabel.font = [UIFont systemFontOfSize:16];
    tempLabel.textColor = [UIColor darkTextColor];
    tempLabel.numberOfLines = 0;
    tempLabel.textAlignment = NSTextAlignmentCenter;
    tempLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:tempLabel];
    
    NSString *tempText;
    if (currentTemp && targetTemp) {
        tempText = [NSString stringWithFormat:@"Current: %.1f%@\nTarget: %.1f%@", 
                   currentTemp.floatValue, unit, targetTemp.floatValue, unit];
    } else if (currentTemp) {
        tempText = [NSString stringWithFormat:@"Current: %.1f%@\nState: %@", 
                   currentTemp.floatValue, unit, [state capitalizedString]];
    } else {
        tempText = [NSString stringWithFormat:@"State: %@", [state capitalizedString]];
    }
    
    tempLabel.text = tempText;
    
    // Layout temperature label
    [NSLayoutConstraint activateConstraints:@[
        [tempLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16.0],
        [tempLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [tempLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [tempLabel.bottomAnchor constraintEqualToAnchor:self.buttonContainer.topAnchor constant:-20.0]
    ]];
    
    // Add temperature control buttons if we have a target temperature
    if (targetTemp) {
        [self addActionButton:@"Increase Temperature (+1°)" style:CustomPopupButtonStyleSecondary action:@"increase_temp"];
        [self addActionButton:@"Decrease Temperature (-1°)" style:CustomPopupButtonStyleSecondary action:@"decrease_temp"];
    }
    
    // Add on/off toggle if the device supports it
    if (![state isEqualToString:@"unavailable"]) {
        NSString *toggleTitle = [state isEqualToString:@"off"] ? @"Turn On" : @"Turn Off";
        [self addActionButton:toggleTitle style:CustomPopupButtonStyleSecondary action:@"toggle"];
    }
    
    [self addActionButton:@"Cancel" style:CustomPopupButtonStyleCancel action:@"dismiss"];
}

- (void)setupCoverControlContent {
    // Cover control content
    NSString *state = self.entity[@"state"];
    
    UILabel *stateLabel = [[UILabel alloc] init];
    stateLabel.font = [UIFont systemFontOfSize:16];
    stateLabel.textColor = [UIColor darkTextColor];
    stateLabel.textAlignment = NSTextAlignmentCenter;
    stateLabel.text = [NSString stringWithFormat:@"Current state: %@", state];
    stateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:stateLabel];
    
    // Layout state label
    [NSLayoutConstraint activateConstraints:@[
        [stateLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16.0],
        [stateLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [stateLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [stateLabel.bottomAnchor constraintEqualToAnchor:self.buttonContainer.topAnchor constant:-20.0]
    ]];
    
    // Add control buttons
    [self addActionButton:@"Open" style:CustomPopupButtonStyleSecondary action:@"open"];
    [self addActionButton:@"Close" style:CustomPopupButtonStyleSecondary action:@"close"];
    [self addActionButton:@"Stop" style:CustomPopupButtonStyleSecondary action:@"stop"];
    [self addActionButton:@"Cancel" style:CustomPopupButtonStyleCancel action:@"dismiss"];
}

- (void)setupLockControlContent {
    // Lock control content
    NSString *state = self.entity[@"state"];
    
    UILabel *stateLabel = [[UILabel alloc] init];
    stateLabel.font = [UIFont systemFontOfSize:16];
    stateLabel.textColor = [UIColor darkTextColor];
    stateLabel.textAlignment = NSTextAlignmentCenter;
    stateLabel.text = [NSString stringWithFormat:@"Current state: %@", state];
    stateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:stateLabel];
    
    // Layout state label
    [NSLayoutConstraint activateConstraints:@[
        [stateLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16.0],
        [stateLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [stateLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [stateLabel.bottomAnchor constraintEqualToAnchor:self.buttonContainer.topAnchor constant:-20.0]
    ]];
    
    // Add control buttons
    [self addActionButton:@"Lock" style:CustomPopupButtonStyleSecondary action:@"lock"];
    [self addActionButton:@"Unlock" style:CustomPopupButtonStyleSecondary action:@"unlock"];
    [self addActionButton:@"Cancel" style:CustomPopupButtonStyleCancel action:@"dismiss"];
}

- (void)setupSensorInfoContent {
    // Sensor info content - enhanced version of the original
    NSString *entityId = self.entity[@"entity_id"];
    NSString *state = self.entity[@"state"];
    
    NSMutableString *message = [NSMutableString stringWithFormat:@"Current State: %@", state];
    
    // Add useful attributes for sensors
    NSDictionary *attributes = self.entity[@"attributes"];
    if (attributes) {
        NSString *unit = attributes[@"unit_of_measurement"];
        NSString *deviceClass = attributes[@"device_class"];
        NSString *lastChanged = self.entity[@"last_changed"];
        
        if (unit) {
            [message appendFormat:@"\nUnit: %@", unit];
        }
        if (deviceClass) {
            [message appendFormat:@"\nType: %@", [deviceClass capitalizedString]];
        }
        if (lastChanged) {
            // Format the timestamp
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'";
            NSDate *date = [formatter dateFromString:lastChanged];
            if (date) {
                formatter.dateStyle = NSDateFormatterMediumStyle;
                formatter.timeStyle = NSDateFormatterShortStyle;
                [message appendFormat:@"\nLast Updated: %@", [formatter stringFromDate:date]];
            }
        }
    }
    
    UILabel *infoLabel = [[UILabel alloc] init];
    infoLabel.font = [UIFont systemFontOfSize:14];
    infoLabel.textColor = [UIColor darkTextColor];
    infoLabel.numberOfLines = 0;
    infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    infoLabel.text = message;
    [self.contentView addSubview:infoLabel];
    
    // Layout info label
    [NSLayoutConstraint activateConstraints:@[
        [infoLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16.0],
        [infoLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [infoLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [infoLabel.bottomAnchor constraintEqualToAnchor:self.buttonContainer.topAnchor constant:-20.0]
    ]];
    
    // Add OK button
    [self addActionButton:@"OK" style:CustomPopupButtonStylePrimary action:@"dismiss"];
}

#pragma mark - Button Management

typedef NS_ENUM(NSInteger, CustomPopupButtonStyle) {
    CustomPopupButtonStylePrimary,
    CustomPopupButtonStyleSecondary,
    CustomPopupButtonStyleCancel
};

- (void)addActionButton:(NSString *)title style:(CustomPopupButtonStyle)style action:(NSString *)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    
    // Style button based on type
    switch (style) {
        case CustomPopupButtonStylePrimary:
            button.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case CustomPopupButtonStyleSecondary:
            button.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
            [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
            break;
        case CustomPopupButtonStyleCancel:
            button.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
            [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            break;
    }
    
    button.layer.cornerRadius = 8.0;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Add tap handler
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    button.accessibilityIdentifier = action;
    
    [self.actionButtons addObject:button];
    [self.buttonContainer addSubview:button];
    
    [self layoutButtons];
}

- (void)layoutButtons {
    // Remove existing constraints
    [self.buttonContainer removeConstraints:self.buttonContainer.constraints];
    
    if (self.actionButtons.count == 0) return;
    
    CGFloat buttonHeight = 44.0;
    CGFloat spacing = 12.0;
    
    for (NSInteger i = 0; i < self.actionButtons.count; i++) {
        UIButton *button = self.actionButtons[i];
        
        [NSLayoutConstraint activateConstraints:@[
            [button.leadingAnchor constraintEqualToAnchor:self.buttonContainer.leadingAnchor],
            [button.trailingAnchor constraintEqualToAnchor:self.buttonContainer.trailingAnchor],
            [button.heightAnchor constraintEqualToConstant:buttonHeight]
        ]];
        
        if (i == 0) {
            [button.topAnchor constraintEqualToAnchor:self.buttonContainer.topAnchor].active = YES;
        } else {
            UIButton *previousButton = self.actionButtons[i - 1];
            [button.topAnchor constraintEqualToAnchor:previousButton.bottomAnchor constant:spacing].active = YES;
        }
        
        if (i == self.actionButtons.count - 1) {
            [button.bottomAnchor constraintEqualToAnchor:self.buttonContainer.bottomAnchor].active = YES;
        }
    }
}

#pragma mark - Actions

- (void)buttonTapped:(UIButton *)sender {
    NSString *action = sender.accessibilityIdentifier;
    
    if ([action isEqualToString:@"dismiss"]) {
        [self dismissAnimated:YES completion:nil];
        return;
    }
    
    // Handle specific actions
    NSDictionary *parameters = @{};
    
    if ([action isEqualToString:@"increase_temp"]) {
        NSNumber *targetTemp = self.entity[@"attributes"][@"temperature"];
        if (targetTemp) {
            float newTemp = targetTemp.floatValue + 1.0;
            parameters = @{@"temperature": @(newTemp)};
        }
    } else if ([action isEqualToString:@"decrease_temp"]) {
        NSNumber *targetTemp = self.entity[@"attributes"][@"temperature"];
        if (targetTemp) {
            float newTemp = targetTemp.floatValue - 1.0;
            parameters = @{@"temperature": @(newTemp)};
        }
    }
    
    // Call action handler
    if (self.actionHandler) {
        self.actionHandler(action, parameters);
    }
    
    // Dismiss popup
    [self dismissAnimated:YES completion:nil];
}

- (void)backgroundTapped:(UITapGestureRecognizer *)gesture {
    [self dismissAnimated:YES completion:nil];
}

#pragma mark - Presentation/Dismissal

- (void)presentFromViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // Present as overlay
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    if (animated) {
        // Initial state for animation
        self.popupContainer.alpha = 0.0;
        self.popupContainer.transform = CGAffineTransformMakeScale(0.8, 0.8);
        self.backgroundOverlay.alpha = 0.0;
    }
    
    [viewController presentViewController:self animated:NO completion:^{
        if (animated) {
            [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.popupContainer.alpha = 1.0;
                self.popupContainer.transform = CGAffineTransformIdentity;
                self.backgroundOverlay.alpha = 1.0;
            } completion:nil];
        }
    }];
}

- (void)dismissAnimated:(BOOL)animated completion:(void(^)(void))completion {
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.popupContainer.alpha = 0.0;
            self.popupContainer.transform = CGAffineTransformMakeScale(0.9, 0.9);
            self.backgroundOverlay.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self dismissViewControllerAnimated:NO completion:completion];
        }];
    } else {
        [self dismissViewControllerAnimated:NO completion:completion];
    }
}

@end