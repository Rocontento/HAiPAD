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
@property (nonatomic, strong) UILabel *mainValueLabel;
@property (nonatomic, strong) UILabel *entityIdLabel;
@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UIView *attributesContainer;
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
    
    // Clean design - remove debug border
    // Shadow for iOS 9.3.5 compatibility
    self.popupContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.popupContainer.layer.shadowOffset = CGSizeMake(0, 8);
    self.popupContainer.layer.shadowOpacity = 0.15;
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
    // Content view directly in popup container
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor whiteColor]; // Clean white background
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.popupContainer addSubview:self.contentView];
    
    // Title label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18]; // Slightly smaller for better hierarchy
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.titleLabel];
    
    // Main value label - the prominent display for the key value
    self.mainValueLabel = [[UILabel alloc] init];
    self.mainValueLabel.font = [UIFont systemFontOfSize:48]; // Large, prominent font
    self.mainValueLabel.textColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0]; // Blue accent color
    self.mainValueLabel.textAlignment = NSTextAlignmentCenter;
    self.mainValueLabel.numberOfLines = 1;
    self.mainValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.mainValueLabel];
    
    // Entity ID label
    self.entityIdLabel = [[UILabel alloc] init];
    self.entityIdLabel.font = [UIFont systemFontOfSize:12];
    self.entityIdLabel.textColor = [UIColor grayColor];
    self.entityIdLabel.textAlignment = NSTextAlignmentCenter;
    self.entityIdLabel.numberOfLines = 1;
    self.entityIdLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.entityIdLabel];
    
    // State label
    self.stateLabel = [[UILabel alloc] init];
    self.stateLabel.font = [UIFont systemFontOfSize:14];
    self.stateLabel.textColor = [UIColor darkGrayColor];
    self.stateLabel.textAlignment = NSTextAlignmentCenter;
    self.stateLabel.numberOfLines = 1;
    self.stateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.stateLabel];
    
    // Attributes container for additional information
    self.attributesContainer = [[UIView alloc] init];
    self.attributesContainer.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];
    self.attributesContainer.layer.cornerRadius = 8.0;
    self.attributesContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.attributesContainer];
    
    // Set basic entity information
    NSString *friendlyName = self.entity[@"attributes"][@"friendly_name"] ?: self.entity[@"entity_id"] ?: @"Unknown Entity";
    NSString *entityId = self.entity[@"entity_id"] ?: @"Unknown Entity";
    NSString *state = self.entity[@"state"] ?: @"Unknown State";
    
    self.titleLabel.text = friendlyName;
    self.entityIdLabel.text = [NSString stringWithFormat:@"Entity ID: %@", entityId];
    self.stateLabel.text = [NSString stringWithFormat:@"State: %@", state];
    
    // Button container
    self.buttonContainer = [[UIView alloc] init];
    self.buttonContainer.backgroundColor = [UIColor whiteColor]; // Clean background
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
        [self.contentView.topAnchor constraintEqualToAnchor:self.popupContainer.topAnchor constant:24.0],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.popupContainer.leadingAnchor constant:24.0],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.popupContainer.trailingAnchor constant:-24.0],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.popupContainer.bottomAnchor constant:-24.0]
    ]];
    
    // Layout title
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
    ]];
    
    // Layout main value label (prominently displayed)
    [NSLayoutConstraint activateConstraints:@[
        [self.mainValueLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16.0],
        [self.mainValueLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.mainValueLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
    ]];
    
    // Layout entity ID label
    [NSLayoutConstraint activateConstraints:@[
        [self.entityIdLabel.topAnchor constraintEqualToAnchor:self.mainValueLabel.bottomAnchor constant:12.0],
        [self.entityIdLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.entityIdLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
    ]];
    
    // Layout state label
    [NSLayoutConstraint activateConstraints:@[
        [self.stateLabel.topAnchor constraintEqualToAnchor:self.entityIdLabel.bottomAnchor constant:4.0],
        [self.stateLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.stateLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
    ]];
    
    // Layout attributes container
    [NSLayoutConstraint activateConstraints:@[
        [self.attributesContainer.topAnchor constraintEqualToAnchor:self.stateLabel.bottomAnchor constant:16.0],
        [self.attributesContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.attributesContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.attributesContainer.bottomAnchor constraintEqualToAnchor:self.buttonContainer.topAnchor constant:-16.0]
    ]];
    
    // Layout button container
    [NSLayoutConstraint activateConstraints:@[
        [self.buttonContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.buttonContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.buttonContainer.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
    ]];
    
    NSLog(@"Popup: Layout constraints applied (new design)");
}

#pragma mark - Content Setup Methods

// Helper method to extract the main value for prominent display
- (NSString *)extractMainValueForEntity {
    NSDictionary *attributes = self.entity[@"attributes"];
    NSString *entityId = self.entity[@"entity_id"] ?: @"";
    NSString *state = self.entity[@"state"] ?: @"Unknown";
    
    // Temperature sensors
    if ([entityId containsString:@"temperature"] || 
        [attributes[@"device_class"] isEqualToString:@"temperature"]) {
        NSString *unit = attributes[@"unit_of_measurement"] ?: @"°C";
        return [NSString stringWithFormat:@"%@%@", state, unit];
    }
    
    // Humidity sensors
    if ([entityId containsString:@"humidity"] || 
        [attributes[@"device_class"] isEqualToString:@"humidity"]) {
        NSString *unit = attributes[@"unit_of_measurement"] ?: @"%";
        return [NSString stringWithFormat:@"%@%@", state, unit];
    }
    
    // Battery sensors
    if ([entityId containsString:@"battery"] || 
        [attributes[@"device_class"] isEqualToString:@"battery"]) {
        NSString *unit = attributes[@"unit_of_measurement"] ?: @"%";
        return [NSString stringWithFormat:@"%@%@", state, unit];
    }
    
    // Light entities - show brightness if available
    if ([entityId hasPrefix:@"light."]) {
        NSNumber *brightness = attributes[@"brightness"];
        if (brightness && ![state isEqualToString:@"off"]) {
            // Convert from 0-255 to 0-100 percentage
            int percentage = (int)((brightness.floatValue / 255.0) * 100);
            return [NSString stringWithFormat:@"%d%%", percentage];
        }
        return [state capitalizedString];
    }
    
    // Climate entities - show current temperature
    if ([entityId hasPrefix:@"climate."]) {
        NSNumber *currentTemp = attributes[@"current_temperature"];
        NSString *unit = attributes[@"temperature_unit"] ?: @"°C";
        if (currentTemp) {
            return [NSString stringWithFormat:@"%.1f%@", currentTemp.floatValue, unit];
        }
        return [state capitalizedString];
    }
    
    // Switch entities
    if ([entityId hasPrefix:@"switch."]) {
        return [state capitalizedString];
    }
    
    // Sensor entities with numeric values
    if ([entityId hasPrefix:@"sensor."]) {
        NSString *unit = attributes[@"unit_of_measurement"];
        if (unit) {
            return [NSString stringWithFormat:@"%@%@", state, unit];
        }
        return state;
    }
    
    // For all other entities, just show the state
    return [state capitalizedString];
}

- (void)populateAttributesContainer {
    // Clear any existing content
    for (UIView *subview in self.attributesContainer.subviews) {
        [subview removeFromSuperview];
    }
    
    NSDictionary *attributes = self.entity[@"attributes"];
    if (!attributes || attributes.count == 0) {
        // Show "No additional attributes" message
        UILabel *noAttributesLabel = [[UILabel alloc] init];
        noAttributesLabel.font = [UIFont systemFontOfSize:12];
        noAttributesLabel.textColor = [UIColor grayColor];
        noAttributesLabel.textAlignment = NSTextAlignmentCenter;
        noAttributesLabel.text = @"No additional attributes available";
        noAttributesLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.attributesContainer addSubview:noAttributesLabel];
        
        [NSLayoutConstraint activateConstraints:@[
            [noAttributesLabel.centerXAnchor constraintEqualToAnchor:self.attributesContainer.centerXAnchor],
            [noAttributesLabel.centerYAnchor constraintEqualToAnchor:self.attributesContainer.centerYAnchor],
            [noAttributesLabel.leadingAnchor constraintEqualToAnchor:self.attributesContainer.leadingAnchor constant:12.0],
            [noAttributesLabel.trailingAnchor constraintEqualToAnchor:self.attributesContainer.trailingAnchor constant:-12.0]
        ]];
        
        // Add minimum height for container
        [self.attributesContainer.heightAnchor constraintEqualToConstant:40.0].active = YES;
        return;
    }
    
    // Create attributes title
    UILabel *attributesTitle = [[UILabel alloc] init];
    attributesTitle.font = [UIFont boldSystemFontOfSize:14];
    attributesTitle.textColor = [UIColor blackColor];
    attributesTitle.text = @"Attributes";
    attributesTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [self.attributesContainer addSubview:attributesTitle];
    
    [NSLayoutConstraint activateConstraints:@[
        [attributesTitle.topAnchor constraintEqualToAnchor:self.attributesContainer.topAnchor constant:12.0],
        [attributesTitle.leadingAnchor constraintEqualToAnchor:self.attributesContainer.leadingAnchor constant:12.0],
        [attributesTitle.trailingAnchor constraintEqualToAnchor:self.attributesContainer.trailingAnchor constant:-12.0]
    ]];
    
    UIView *lastView = attributesTitle;
    
    // Add key attributes (skip friendly_name as it's already the title)
    NSArray *importantKeys = @[@"brightness", @"color_temp", @"unit_of_measurement", @"device_class", @"battery"];
    
    for (NSString *key in importantKeys) {
        id value = attributes[key];
        if (value && ![key isEqualToString:@"friendly_name"]) {
            UILabel *attributeLabel = [[UILabel alloc] init];
            attributeLabel.font = [UIFont systemFontOfSize:12];
            attributeLabel.textColor = [UIColor darkGrayColor];
            attributeLabel.numberOfLines = 0;
            attributeLabel.translatesAutoresizingMaskIntoConstraints = NO;
            
            NSString *displayValue = [NSString stringWithFormat:@"%@", value];
            if ([key isEqualToString:@"brightness"] && [value isKindOfClass:[NSNumber class]]) {
                // Convert brightness from 0-255 to 0-100%
                int percentage = (int)((((NSNumber *)value).floatValue / 255.0) * 100);
                displayValue = [NSString stringWithFormat:@"%d%%", percentage];
            }
            
            attributeLabel.text = [NSString stringWithFormat:@"%@: %@", [key capitalizedString], displayValue];
            [self.attributesContainer addSubview:attributeLabel];
            
            [NSLayoutConstraint activateConstraints:@[
                [attributeLabel.topAnchor constraintEqualToAnchor:lastView.bottomAnchor constant:6.0],
                [attributeLabel.leadingAnchor constraintEqualToAnchor:self.attributesContainer.leadingAnchor constant:12.0],
                [attributeLabel.trailingAnchor constraintEqualToAnchor:self.attributesContainer.trailingAnchor constant:-12.0]
            ]];
            
            lastView = attributeLabel;
        }
    }
    
    // Add bottom padding
    [lastView.bottomAnchor constraintEqualToAnchor:self.attributesContainer.bottomAnchor constant:-12.0].active = YES;
}

- (void)setupInfoContent {
    // Set the main value for prominent display
    self.mainValueLabel.text = [self extractMainValueForEntity];
    
    // Populate the attributes container
    [self populateAttributesContainer];
    
    // Add debugging
    NSLog(@"PopupInfo: Setting up info content with main value: %@", self.mainValueLabel.text);
    
    // Add OK button
    [self addActionButton:@"OK" style:CustomPopupButtonStylePrimary action:@"dismiss"];
    
    NSLog(@"PopupInfo: Content setup completed");
}

- (void)setupClimateControlContent {
    // Set the main value - show current temperature prominently
    NSNumber *currentTemp = self.entity[@"attributes"][@"current_temperature"];
    NSNumber *targetTemp = self.entity[@"attributes"][@"temperature"];
    NSString *unit = self.entity[@"attributes"][@"temperature_unit"] ?: @"°C";
    NSString *state = self.entity[@"state"];
    
    if (currentTemp) {
        self.mainValueLabel.text = [NSString stringWithFormat:@"%.1f%@", currentTemp.floatValue, unit];
    } else if (targetTemp) {
        self.mainValueLabel.text = [NSString stringWithFormat:@"%.1f%@", targetTemp.floatValue, unit];
    } else {
        self.mainValueLabel.text = [state capitalizedString];
    }
    
    // Update state label to show additional info
    if (currentTemp && targetTemp) {
        self.stateLabel.text = [NSString stringWithFormat:@"Target: %.1f%@ | State: %@", 
                               targetTemp.floatValue, unit, [state capitalizedString]];
    } else {
        self.stateLabel.text = [NSString stringWithFormat:@"State: %@", [state capitalizedString]];
    }
    
    // Populate the attributes container
    [self populateAttributesContainer];
    
    // Add temperature control buttons if we have a target temperature
    if (targetTemp) {
        [self addActionButton:@"Increase (+1°)" style:CustomPopupButtonStyleSecondary action:@"increase_temp"];
        [self addActionButton:@"Decrease (-1°)" style:CustomPopupButtonStyleSecondary action:@"decrease_temp"];
    }
    
    // Add on/off toggle if the device supports it
    if (![state isEqualToString:@"unavailable"]) {
        NSString *toggleTitle = [state isEqualToString:@"off"] ? @"Turn On" : @"Turn Off";
        [self addActionButton:toggleTitle style:CustomPopupButtonStyleSecondary action:@"toggle"];
    }
    
    [self addActionButton:@"Cancel" style:CustomPopupButtonStyleCancel action:@"dismiss"];
}

- (void)setupCoverControlContent {
    // Set the main value - show state prominently
    NSString *state = self.entity[@"state"];
    self.mainValueLabel.text = [state capitalizedString];
    
    // Populate the attributes container
    [self populateAttributesContainer];
    
    // Add control buttons
    [self addActionButton:@"Open" style:CustomPopupButtonStyleSecondary action:@"open"];
    [self addActionButton:@"Close" style:CustomPopupButtonStyleSecondary action:@"close"];
    [self addActionButton:@"Stop" style:CustomPopupButtonStyleSecondary action:@"stop"];
    [self addActionButton:@"Cancel" style:CustomPopupButtonStyleCancel action:@"dismiss"];
}

- (void)setupLockControlContent {
    // Set the main value - show state prominently
    NSString *state = self.entity[@"state"];
    self.mainValueLabel.text = [state capitalizedString];
    
    // Populate the attributes container
    [self populateAttributesContainer];
    
    // Add control buttons
    NSString *lockAction = [state isEqualToString:@"locked"] ? @"Unlock" : @"Lock";
    [self addActionButton:lockAction style:CustomPopupButtonStylePrimary action:@"toggle_lock"];
    [self addActionButton:@"Cancel" style:CustomPopupButtonStyleCancel action:@"dismiss"];
}

- (void)setupSensorInfoContent {
    // Set the main value for prominent display
    self.mainValueLabel.text = [self extractMainValueForEntity];
    
    // Update state label to show last updated time if available
    NSString *lastChanged = self.entity[@"last_changed"];
    if (lastChanged) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'";
        NSDate *date = [formatter dateFromString:lastChanged];
        if (date) {
            formatter.dateStyle = NSDateFormatterMediumStyle;
            formatter.timeStyle = NSDateFormatterShortStyle;
            self.stateLabel.text = [NSString stringWithFormat:@"Last Updated: %@", [formatter stringFromDate:date]];
        }
    }
    
    // Populate the attributes container
    [self populateAttributesContainer];
    
    // Add debugging
    NSLog(@"PopupSensorInfo: Setting up sensor content with main value: %@", self.mainValueLabel.text);
    
    // Add OK button
    [self addActionButton:@"OK" style:CustomPopupButtonStylePrimary action:@"dismiss"];
}

#pragma mark - Button Management

- (void)addActionButton:(NSString *)title style:(CustomPopupButtonStyle)style action:(NSString *)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16]; // Use boldSystemFont for iOS 9.3.5 compatibility
    
    // Style button based on type with improved styling
    switch (style) {
        case CustomPopupButtonStylePrimary:
            button.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case CustomPopupButtonStyleSecondary:
            button.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.layer.borderWidth = 1.0;
            button.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
            break;
        case CustomPopupButtonStyleCancel:
            button.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
            [button setTitleColor:[UIColor colorWithWhite:0.4 alpha:1.0] forState:UIControlStateNormal];
            break;
    }
    
    button.layer.cornerRadius = 10.0; // Slightly more rounded
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
    } else if ([action isEqualToString:@"toggle_lock"]) {
        // Handle lock/unlock toggle
        NSString *currentState = self.entity[@"state"];
        NSString *newAction = [currentState isEqualToString:@"locked"] ? @"unlock" : @"lock";
        action = newAction; // Override action for the handler
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