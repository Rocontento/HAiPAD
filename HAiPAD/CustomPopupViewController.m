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
    
    // Add debugging to ensure entity data is properly passed
    NSLog(@"Creating popup with entity: %@, type: %ld", entity, (long)type);
    
    return popup;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"Popup: viewDidLoad called");
    
    self.actionButtons = [NSMutableArray array];
    [self setupBackgroundOverlay];
    [self setupPopupContainer];
    [self setupContentBasedOnType];
    [self layoutPopupContent];
    
    NSLog(@"Popup: viewDidLoad completed");
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
    
    // Add debug border to make popup visible
    self.popupContainer.layer.borderWidth = 2.0;
    self.popupContainer.layer.borderColor = [UIColor redColor].CGColor;
    
    // Shadow for iOS 9.3.5 compatibility
    self.popupContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.popupContainer.layer.shadowOffset = CGSizeMake(0, 8);
    self.popupContainer.layer.shadowOpacity = 0.2;
    self.popupContainer.layer.shadowRadius = 20.0;
    
    self.popupContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.popupContainer];
    
    // Center the popup and set dimensions with minimum height
    [NSLayoutConstraint activateConstraints:@[
        [self.popupContainer.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.popupContainer.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.popupContainer.widthAnchor constraintLessThanOrEqualToConstant:340.0],
        [self.popupContainer.widthAnchor constraintGreaterThanOrEqualToConstant:280.0],
        [self.popupContainer.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [self.popupContainer.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        [self.popupContainer.heightAnchor constraintLessThanOrEqualToConstant:500.0],
        [self.popupContainer.heightAnchor constraintGreaterThanOrEqualToConstant:200.0] // Ensure minimum height
    ]];
}

- (void)setupContentBasedOnType {
    // Content view directly in popup container (without scroll view for now)
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0]; // Light gray background for debugging
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.popupContainer addSubview:self.contentView];
    
    // Title label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20]; // Use boldSystemFont for iOS 9.3.5 compatibility
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.titleLabel];
    
    // Set title based on entity with better error handling
    NSString *friendlyName = self.entity[@"attributes"][@"friendly_name"] ?: self.entity[@"entity_id"] ?: @"Unknown Entity";
    self.titleLabel.text = friendlyName;
    
    // Add debugging
    NSLog(@"Popup: Setting title to: %@", friendlyName);
    NSLog(@"Popup: Entity data: %@", self.entity);
    
    // Button container
    self.buttonContainer = [[UIView alloc] init];
    self.buttonContainer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0]; // Debug background for buttons
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
    // Layout content view directly in popup container
    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.topAnchor constraintEqualToAnchor:self.popupContainer.topAnchor constant:20.0],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.popupContainer.leadingAnchor constant:20.0],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.popupContainer.trailingAnchor constant:-20.0],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.popupContainer.bottomAnchor constant:-20.0]
    ]];
    
    // Layout title with proper constraints
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
    
    NSLog(@"Popup: Layout constraints applied (simplified)");
}

#pragma mark - Content Setup Methods

- (void)setupInfoContent {
    // Create info content similar to the original alert
    UILabel *infoLabel = [[UILabel alloc] init];
    infoLabel.font = [UIFont systemFontOfSize:14];
    infoLabel.textColor = [UIColor blackColor]; // Use explicit black color for iOS 9.3.5 compatibility
    infoLabel.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0]; // Light background to help debugging
    infoLabel.numberOfLines = 0;
    infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:infoLabel];
    
    // Format entity information - with better error handling
    NSString *entityId = self.entity[@"entity_id"] ?: @"Unknown Entity";
    NSString *state = self.entity[@"state"] ?: @"Unknown State";
    NSMutableString *message = [NSMutableString stringWithFormat:@"Entity ID: %@\nState: %@", entityId, state];
    
    NSDictionary *attributes = self.entity[@"attributes"];
    if (attributes && attributes.count > 0) {
        [message appendString:@"\n\nAttributes:"];
        for (NSString *key in attributes) {
            id value = attributes[key];
            if (value) {
                [message appendFormat:@"\n%@: %@", key, value];
            }
        }
    } else {
        [message appendString:@"\n\nNo additional attributes available."];
    }
    
    infoLabel.text = message;
    
    // Add debugging - ensure the label has content
    NSLog(@"PopupInfo: Setting up info content with text: %@", message);
    NSLog(@"PopupInfo: Title text: '%@'", self.titleLabel.text);
    NSLog(@"PopupInfo: InfoLabel textColor: %@", infoLabel.textColor);
    NSLog(@"PopupInfo: InfoLabel font: %@", infoLabel.font);
    
    // Layout info label - simplified constraints
    [NSLayoutConstraint activateConstraints:@[
        [infoLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16.0],
        [infoLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [infoLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [infoLabel.bottomAnchor constraintEqualToAnchor:self.buttonContainer.topAnchor constant:-20.0]
    ]];
    
    // Add OK button
    [self addActionButton:@"OK" style:CustomPopupButtonStylePrimary action:@"dismiss"];
    
    NSLog(@"PopupInfo: Content setup completed");
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
    tempLabel.textColor = [UIColor blackColor];
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
    stateLabel.textColor = [UIColor blackColor];
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
    stateLabel.textColor = [UIColor blackColor];
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
    NSString *entityId = self.entity[@"entity_id"] ?: @"Unknown Entity";
    NSString *state = self.entity[@"state"] ?: @"Unknown State";
    
    NSMutableString *message = [NSMutableString stringWithFormat:@"Entity ID: %@\nCurrent State: %@", entityId, state];
    
    // Add useful attributes for sensors
    NSDictionary *attributes = self.entity[@"attributes"];
    if (attributes && attributes.count > 0) {
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
        
        // Add additional useful attributes
        [message appendString:@"\n\nOther Attributes:"];
        for (NSString *key in attributes) {
            // Skip already displayed attributes
            if (![key isEqualToString:@"unit_of_measurement"] && 
                ![key isEqualToString:@"device_class"] && 
                ![key isEqualToString:@"friendly_name"]) {
                id value = attributes[key];
                if (value) {
                    [message appendFormat:@"\n%@: %@", key, value];
                }
            }
        }
    } else {
        [message appendString:@"\n\nNo additional attributes available."];
    }
    
    UILabel *infoLabel = [[UILabel alloc] init];
    infoLabel.font = [UIFont systemFontOfSize:14];
    infoLabel.textColor = [UIColor blackColor];
    infoLabel.numberOfLines = 0;
    infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    infoLabel.text = message;
    [self.contentView addSubview:infoLabel];
    
    // Add debugging - ensure the label has content
    NSLog(@"PopupSensorInfo: Setting up sensor content with text: %@", message);
    
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

- (void)addActionButton:(NSString *)title style:(CustomPopupButtonStyle)style action:(NSString *)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16]; // Use boldSystemFont for iOS 9.3.5 compatibility
    
    // Style button based on type
    switch (style) {
        case CustomPopupButtonStylePrimary:
            button.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case CustomPopupButtonStyleSecondary:
            button.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
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
    NSLog(@"Popup: presentFromViewController called");
    
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
        NSLog(@"Popup: Presentation completed, starting animation");
        
        if (animated) {
            [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.popupContainer.alpha = 1.0;
                self.popupContainer.transform = CGAffineTransformIdentity;
                self.backgroundOverlay.alpha = 1.0;
            } completion:^(BOOL finished) {
                NSLog(@"Popup: Animation completed");
                
                // Force layout after animation
                [self.view layoutIfNeeded];
                
                // Debug current frame sizes
                NSLog(@"Popup: Final popup container frame: %@", NSStringFromCGRect(self.popupContainer.frame));
                NSLog(@"Popup: Final content view frame: %@", NSStringFromCGRect(self.contentView.frame));
                NSLog(@"Popup: Final title label frame: %@", NSStringFromCGRect(self.titleLabel.frame));
            }];
        } else {
            // Force layout for non-animated case
            [self.view layoutIfNeeded];
            
            // Debug current frame sizes
            NSLog(@"Popup: Final popup container frame: %@", NSStringFromCGRect(self.popupContainer.frame));
            NSLog(@"Popup: Final content view frame: %@", NSStringFromCGRect(self.contentView.frame));
            NSLog(@"Popup: Final title label frame: %@", NSStringFromCGRect(self.titleLabel.frame));
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