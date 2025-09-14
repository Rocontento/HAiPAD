//
//  ConfigurationViewController.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "ConfigurationViewController.h"
#import "HomeAssistantClient.h"
#import "CustomPopupViewController.h"
#import "ImagePreviewViewController.h"
#import <Photos/Photos.h>

@interface ConfigurationViewController () <HomeAssistantClientDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ImagePreviewViewControllerDelegate>
@property (nonatomic, strong) HomeAssistantClient *testClient;
@property (nonatomic, weak) id<HomeAssistantClientDelegate> originalDelegate;
@property (nonatomic, strong) UIColor *selectedDashboardColor;
@property (nonatomic, strong) UIColor *selectedNavbarColor;
@property (nonatomic, strong) UIImage *selectedBackgroundImage;
@end

@implementation ConfigurationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Configuration";
    
    // Add cancel button to navigation bar
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    // Load existing configuration
    [self loadConfiguration];
    
    // Set up text field styling
    self.urlTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.urlTextField.placeholder = @"http://192.168.1.100:8123";
    self.urlTextField.keyboardType = UIKeyboardTypeURL;
    self.urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    self.tokenTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.tokenTextField.placeholder = @"Long-lived access token";
    self.tokenTextField.secureTextEntry = YES;
    self.tokenTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.tokenTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    // Set up button styling
    self.saveButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.saveButton.layer.cornerRadius = 5.0;
    
    self.testButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0];
    [self.testButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.testButton.layer.cornerRadius = 5.0;
    
    self.statusLabel.text = @"Enter your Home Assistant URL and access token";
    self.statusLabel.textColor = [UIColor grayColor];
    self.statusLabel.numberOfLines = 0;
    
    // Configure grid controls for independent column/row selection
    if (self.gridColumnsSlider) {
        self.gridColumnsSlider.minimumValue = 2.0;
        self.gridColumnsSlider.maximumValue = 8.0;
        self.gridColumnsSlider.continuous = YES;
        [self.gridColumnsSlider addTarget:self action:@selector(gridColumnsSliderChanged:) forControlEvents:UIControlEventValueChanged];
    }
    
    if (self.gridRowsSlider) {
        self.gridRowsSlider.minimumValue = 2.0;
        self.gridRowsSlider.maximumValue = 12.0;
        self.gridRowsSlider.continuous = YES;
        [self.gridRowsSlider addTarget:self action:@selector(gridRowsSliderChanged:) forControlEvents:UIControlEventValueChanged];
    }
    
    // Set up customization controls
    [self setupCustomizationControls];
}

- (void)loadConfiguration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *baseURL = [defaults stringForKey:@"ha_base_url"];
    NSString *accessToken = [defaults stringForKey:@"ha_access_token"];
    
    if (baseURL) {
        self.urlTextField.text = baseURL;
    }
    
    if (accessToken) {
        self.tokenTextField.text = accessToken;
    }
    
    // Load independent grid preferences with backward compatibility
    if (self.gridColumnsSlider && self.gridColumnsLabel) {
        NSInteger gridColumns = [defaults integerForKey:@"ha_grid_columns"];
        
        // If new format doesn't exist, try to migrate from legacy format
        if (gridColumns == 0) {
            NSInteger legacyGridSize = [defaults integerForKey:@"ha_grid_size"];
            if (legacyGridSize > 0) {
                gridColumns = legacyGridSize;
            } else {
                // Set device-appropriate defaults
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    gridColumns = 6; // Default 6 columns for iPad
                } else {
                    gridColumns = 4; // Default 4 columns for iPhone
                }
            }
        }
        
        self.gridColumnsSlider.value = gridColumns;
        [self updateGridColumnsLabel];
    }
    
    if (self.gridRowsSlider && self.gridRowsLabel) {
        NSInteger gridRows = [defaults integerForKey:@"ha_grid_rows"];
        
        // If new format doesn't exist, try to migrate from legacy format
        if (gridRows == 0) {
            NSInteger legacyGridSize = [defaults integerForKey:@"ha_grid_size"];
            if (legacyGridSize > 0) {
                gridRows = legacyGridSize;
            } else {
                // Set device-appropriate defaults
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    gridRows = 8; // Default 8 rows for iPad
                } else {
                    gridRows = 6; // Default 6 rows for iPhone
                }
            }
        }
        
        self.gridRowsSlider.value = gridRows;
        [self updateGridRowsLabel];
    }
    
    // Load customization settings
    [self loadCustomizationSettings];
}

#pragma mark - IBActions

- (IBAction)saveButtonTapped:(id)sender {
    NSString *url = [self.urlTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *token = [self.tokenTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (url.length == 0 || token.length == 0) {
        NSDictionary *errorEntity = @{
            @"entity_id": @"validation_error",
            @"state": @"Please enter both URL and access token",
            @"attributes": @{
                @"friendly_name": @"Missing Information"
            }
        };
        
        CustomPopupViewController *popup = [CustomPopupViewController popupWithEntity:errorEntity
                                                                                 type:CustomPopupTypeInfo
                                                                         actionHandler:nil];
        [popup presentFromViewController:self animated:YES];
        return;
    }
    
    // Remove trailing slash from URL if present
    if ([url hasSuffix:@"/"]) {
        url = [url substringToIndex:url.length - 1];
    }
    
    // Save configuration
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:url forKey:@"ha_base_url"];
    [defaults setObject:token forKey:@"ha_access_token"];
    
    // Save independent grid preferences
    if (self.gridColumnsSlider) {
        NSInteger gridColumns = (NSInteger)self.gridColumnsSlider.value;
        [defaults setInteger:gridColumns forKey:@"ha_grid_columns"];
    }
    
    if (self.gridRowsSlider) {
        NSInteger gridRows = (NSInteger)self.gridRowsSlider.value;
        [defaults setInteger:gridRows forKey:@"ha_grid_rows"];
    }
    
    // Set default refresh intervals if not already configured
    if (![defaults objectForKey:@"ha_auto_refresh_interval"]) {
        [defaults setDouble:2.0 forKey:@"ha_auto_refresh_interval"]; // 2 seconds default
    }
    if (![defaults objectForKey:@"ha_service_call_delay"]) {
        [defaults setDouble:0.3 forKey:@"ha_service_call_delay"]; // 0.3 seconds default
    }
    if (![defaults objectForKey:@"ha_websocket_enabled"]) {
        [defaults setBool:YES forKey:@"ha_websocket_enabled"]; // WebSocket enabled by default
    }
    
    // Save customization settings
    [self saveCustomizationSettings];
    
    [defaults synchronize];
    
    // Connect with new configuration
    HomeAssistantClient *client = [HomeAssistantClient sharedClient];
    
    // Store the original delegate before setting ourselves
    self.originalDelegate = client.delegate;
    client.delegate = self;
    
    [client connectWithBaseURL:url accessToken:token];
    
    self.statusLabel.text = @"Saving and testing connection...";
    self.statusLabel.textColor = [UIColor orangeColor];
    
    // Disable buttons during save
    self.saveButton.enabled = NO;
    self.testButton.enabled = NO;
}

- (IBAction)testButtonTapped:(id)sender {
    NSString *url = [self.urlTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *token = [self.tokenTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (url.length == 0 || token.length == 0) {
        NSDictionary *errorEntity = @{
            @"entity_id": @"validation_error",
            @"state": @"Please enter both URL and access token",
            @"attributes": @{
                @"friendly_name": @"Missing Information"
            }
        };
        
        CustomPopupViewController *popup = [CustomPopupViewController popupWithEntity:errorEntity
                                                                                 type:CustomPopupTypeInfo
                                                                         actionHandler:nil];
        [popup presentFromViewController:self animated:YES];
        return;
    }
    
    // Remove trailing slash from URL if present
    if ([url hasSuffix:@"/"]) {
        url = [url substringToIndex:url.length - 1];
    }
    
    // Test connection without saving
    self.testClient = [[HomeAssistantClient alloc] init];
    self.testClient.delegate = self;
    [self.testClient connectWithBaseURL:url accessToken:token];
    
    self.statusLabel.text = @"Testing connection...";
    self.statusLabel.textColor = [UIColor orangeColor];
    
    // Disable buttons during test
    self.saveButton.enabled = NO;
    self.testButton.enabled = NO;
}

- (IBAction)cancelButtonTapped:(id)sender {
    [self cleanupTestClient];
    
    // Restore the original delegate before dismissing
    if (self.originalDelegate) {
        HomeAssistantClient *client = [HomeAssistantClient sharedClient];
        client.delegate = self.originalDelegate;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cleanupTestClient {
    if (self.testClient) {
        self.testClient.delegate = nil;
        self.testClient = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self cleanupTestClient];
    
    // Restore the original delegate for the shared client
    if (self.originalDelegate) {
        HomeAssistantClient *client = [HomeAssistantClient sharedClient];
        client.delegate = self.originalDelegate;
    }
}

#pragma mark - HomeAssistantClientDelegate

- (void)homeAssistantClientDidConnect:(HomeAssistantClient *)client {
    self.statusLabel.text = @"✓ Connection successful!";
    self.statusLabel.textColor = [UIColor greenColor];
    
    // Re-enable buttons
    self.saveButton.enabled = YES;
    self.testButton.enabled = YES;
    
    // Clean up test client if this was a test
    if (client == self.testClient) {
        [self cleanupTestClient];
    }
    
    // If this was a save operation, dismiss the view controller
    if (client == [HomeAssistantClient sharedClient]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // Restore the original delegate before dismissing
            if (self.originalDelegate) {
                client.delegate = self.originalDelegate;
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    }
}

- (void)homeAssistantClient:(HomeAssistantClient *)client didFailWithError:(NSError *)error {
    self.statusLabel.text = [NSString stringWithFormat:@"✗ Connection failed: %@", error.localizedDescription];
    self.statusLabel.textColor = [UIColor redColor];
    
    // Re-enable buttons
    self.saveButton.enabled = YES;
    self.testButton.enabled = YES;
    
    // Clean up test client if this was a test
    if (client == self.testClient) {
        [self cleanupTestClient];
    }
}

- (void)homeAssistantClient:(HomeAssistantClient *)client didReceiveStates:(NSArray *)states {
    // This delegate method is called after successful connection
    // We'll just use the didConnect method for our purposes
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)gridColumnsSliderChanged:(id)sender {
    [self updateGridColumnsLabel];
}

- (IBAction)gridRowsSliderChanged:(id)sender {
    [self updateGridRowsLabel];
}

- (void)updateGridColumnsLabel {
    if (self.gridColumnsSlider && self.gridColumnsLabel) {
        NSInteger gridColumns = (NSInteger)self.gridColumnsSlider.value;
        self.gridColumnsLabel.text = [NSString stringWithFormat:@"Columns: %ld", (long)gridColumns];
    }
}

- (void)updateGridRowsLabel {
    if (self.gridRowsSlider && self.gridRowsLabel) {
        NSInteger gridRows = (NSInteger)self.gridRowsSlider.value;
        self.gridRowsLabel.text = [NSString stringWithFormat:@"Rows: %ld", (long)gridRows];
    }
}

#pragma mark - Customization Controls

- (void)setupCustomizationControls {
    // Initialize default colors
    self.selectedDashboardColor = [UIColor colorWithWhite:0.95 alpha:1.0]; // Default light gray
    self.selectedNavbarColor = [UIColor colorWithWhite:0.98 alpha:1.0]; // Default navigation color
    
    // Style dashboard color button
    if (self.dashboardColorButton) {
        self.dashboardColorButton.layer.cornerRadius = 8.0;
        self.dashboardColorButton.layer.borderWidth = 2.0;
        self.dashboardColorButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
        [self updateDashboardColorButton];
    }
    
    // Style navbar color button
    if (self.navbarColorButton) {
        self.navbarColorButton.layer.cornerRadius = 8.0;
        self.navbarColorButton.layer.borderWidth = 2.0;
        self.navbarColorButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
        [self updateNavbarColorButton];
    }
    
    // Style background image button
    if (self.backgroundImageButton) {
        self.backgroundImageButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0];
        [self.backgroundImageButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.backgroundImageButton.layer.cornerRadius = 5.0;
    }
    
    // Setup background type control
    if (self.backgroundTypeControl) {
        [self.backgroundTypeControl setTitle:@"Color" forSegmentAtIndex:0];
        [self.backgroundTypeControl setTitle:@"Image" forSegmentAtIndex:1];
        self.backgroundTypeControl.selectedSegmentIndex = 0; // Default to color
        [self backgroundTypeChanged:self.backgroundTypeControl];
    }
}

- (void)loadCustomizationSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Load dashboard background color
    NSData *dashboardColorData = [defaults dataForKey:@"ha_dashboard_background_color"];
    if (dashboardColorData) {
        self.selectedDashboardColor = [NSKeyedUnarchiver unarchiveObjectWithData:dashboardColorData];
    } else {
        self.selectedDashboardColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    }
    [self updateDashboardColorButton];
    
    // Load navbar color
    NSData *navbarColorData = [defaults dataForKey:@"ha_navbar_color"];
    if (navbarColorData) {
        self.selectedNavbarColor = [NSKeyedUnarchiver unarchiveObjectWithData:navbarColorData];
    } else {
        self.selectedNavbarColor = [UIColor colorWithWhite:0.98 alpha:1.0];
    }
    [self updateNavbarColorButton];
    
    // Load background image
    NSData *backgroundImageData = [defaults dataForKey:@"ha_background_image"];
    if (backgroundImageData) {
        self.selectedBackgroundImage = [UIImage imageWithData:backgroundImageData];
        // Note: Scale and offset will be loaded by DashboardViewController when applying the image
    }
    
    // Load background type
    NSInteger backgroundType = [defaults integerForKey:@"ha_background_type"];
    if (self.backgroundTypeControl) {
        self.backgroundTypeControl.selectedSegmentIndex = backgroundType;
        [self backgroundTypeChanged:self.backgroundTypeControl];
    }
}

- (void)saveCustomizationSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Save dashboard background color
    if (self.selectedDashboardColor) {
        NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:self.selectedDashboardColor];
        [defaults setObject:colorData forKey:@"ha_dashboard_background_color"];
    }
    
    // Save navbar color
    if (self.selectedNavbarColor) {
        NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:self.selectedNavbarColor];
        [defaults setObject:colorData forKey:@"ha_navbar_color"];
    }
    
    // Save background image
    if (self.selectedBackgroundImage) {
        NSData *imageData = UIImageJPEGRepresentation(self.selectedBackgroundImage, 0.8);
        [defaults setObject:imageData forKey:@"ha_background_image"];
    }
    
    // Save background type
    if (self.backgroundTypeControl) {
        [defaults setInteger:self.backgroundTypeControl.selectedSegmentIndex forKey:@"ha_background_type"];
    }
}

- (void)updateDashboardColorButton {
    if (self.dashboardColorButton && self.selectedDashboardColor) {
        self.dashboardColorButton.backgroundColor = self.selectedDashboardColor;
        
        // Show hex value on button
        NSString *hexValue = [self hexStringFromColor:self.selectedDashboardColor];
        [self.dashboardColorButton setTitle:hexValue forState:UIControlStateNormal];
        [self.dashboardColorButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.dashboardColorButton.titleLabel.font = [UIFont systemFontOfSize:12];
        
        // Add text shadow for better readability
        self.dashboardColorButton.titleLabel.shadowColor = [UIColor blackColor];
        self.dashboardColorButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
    }
    
    if (self.dashboardColorLabel) {
        self.dashboardColorLabel.text = @"Dashboard Background";
    }
}

- (void)updateNavbarColorButton {
    if (self.navbarColorButton && self.selectedNavbarColor) {
        self.navbarColorButton.backgroundColor = self.selectedNavbarColor;
        
        // Show hex value on button
        NSString *hexValue = [self hexStringFromColor:self.selectedNavbarColor];
        [self.navbarColorButton setTitle:hexValue forState:UIControlStateNormal];
        [self.navbarColorButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.navbarColorButton.titleLabel.font = [UIFont systemFontOfSize:12];
        
        // Add text shadow for better readability
        self.navbarColorButton.titleLabel.shadowColor = [UIColor blackColor];
        self.navbarColorButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
    }
    
    if (self.navbarColorLabel) {
        self.navbarColorLabel.text = @"Navigation Bar Color";
    }
}

- (NSString *)hexStringFromColor:(UIColor *)color {
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    int r = (int)(red * 255);
    int g = (int)(green * 255);
    int b = (int)(blue * 255);
    
    return [NSString stringWithFormat:@"#%02X%02X%02X", r, g, b];
}

#pragma mark - IBActions for Customization

- (IBAction)dashboardColorButtonTapped:(id)sender {
    [self showColorPickerForType:@"dashboard"];
}

- (IBAction)navbarColorButtonTapped:(id)sender {
    [self showColorPickerForType:@"navbar"];
}

- (IBAction)backgroundImageButtonTapped:(id)sender {
    [self showImagePicker];
}

- (IBAction)backgroundTypeChanged:(id)sender {
    if (self.backgroundTypeControl) {
        BOOL isImageMode = (self.backgroundTypeControl.selectedSegmentIndex == 1);
        
        // Enable/disable controls based on selected type
        if (self.dashboardColorButton) {
            self.dashboardColorButton.enabled = !isImageMode;
            self.dashboardColorButton.alpha = isImageMode ? 0.5 : 1.0;
        }
        
        if (self.backgroundImageButton) {
            self.backgroundImageButton.enabled = isImageMode;
            self.backgroundImageButton.alpha = isImageMode ? 1.0 : 0.5;
        }
        
        if (self.dashboardColorLabel) {
            self.dashboardColorLabel.textColor = isImageMode ? [UIColor lightGrayColor] : [UIColor darkTextColor];
        }
    }
}

#pragma mark - Color Picker

- (void)showColorPickerForType:(NSString *)colorType {
    // Create a custom color picker with hex input
    UIAlertController *colorAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Choose %@ Color", [colorType capitalizedString]]
                                                                        message:@"Select a predefined color or enter a hex value"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    // Add text field for hex input
    [colorAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Enter hex color (e.g., #FF5733)";
        textField.text = @"#";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    
    // Custom hex color action
    UIAlertAction *customColorAction = [UIAlertAction actionWithTitle:@"Use Hex Color"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
        UITextField *hexField = colorAlert.textFields.firstObject;
        NSString *hexString = [hexField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        UIColor *customColor = [self colorFromHexString:hexString];
        if (customColor) {
            if ([colorType isEqualToString:@"dashboard"]) {
                self.selectedDashboardColor = customColor;
                [self updateDashboardColorButton];
            } else if ([colorType isEqualToString:@"navbar"]) {
                self.selectedNavbarColor = customColor;
                [self updateNavbarColorButton];
            }
        } else {
            // Show error if invalid hex
            [self showInvalidHexColorAlert];
        }
    }];
    
    [colorAlert addAction:customColorAction];
    
    // Add separator
    UIAlertAction *separatorAction = [UIAlertAction actionWithTitle:@"--- Predefined Colors ---"
                                                              style:UIAlertActionStyleDefault
                                                            handler:nil];
    separatorAction.enabled = NO;
    [colorAlert addAction:separatorAction];
    
    // Predefined colors with names
    NSArray *colors = @[
        @{@"name": @"Light Gray", @"color": [UIColor colorWithWhite:0.95 alpha:1.0]},
        @{@"name": @"White", @"color": [UIColor whiteColor]},
        @{@"name": @"Black", @"color": [UIColor blackColor]},
        @{@"name": @"Blue", @"color": [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1.0]},
        @{@"name": @"Green", @"color": [UIColor colorWithRed:0.2 green:0.7 blue:0.3 alpha:1.0]},
        @{@"name": @"Red", @"color": [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.0]},
        @{@"name": @"Purple", @"color": [UIColor colorWithRed:0.6 green:0.2 blue:0.8 alpha:1.0]},
        @{@"name": @"Orange", @"color": [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0]},
        @{@"name": @"Dark Gray", @"color": [UIColor colorWithWhite:0.3 alpha:1.0]},
        @{@"name": @"Navy Blue", @"color": [UIColor colorWithRed:0.1 green:0.2 blue:0.5 alpha:1.0]}
    ];
    
    for (NSDictionary *colorInfo in colors) {
        NSString *colorName = colorInfo[@"name"];
        UIColor *color = colorInfo[@"color"];
        
        UIAlertAction *colorAction = [UIAlertAction actionWithTitle:colorName
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
            if ([colorType isEqualToString:@"dashboard"]) {
                self.selectedDashboardColor = color;
                [self updateDashboardColorButton];
            } else if ([colorType isEqualToString:@"navbar"]) {
                self.selectedNavbarColor = color;
                [self updateNavbarColorButton];
            }
        }];
        
        [colorAlert addAction:colorAction];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [colorAlert addAction:cancelAction];
    
    // For iPad, set source view
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        colorAlert.popoverPresentationController.sourceView = ([colorType isEqualToString:@"dashboard"]) ? self.dashboardColorButton : self.navbarColorButton;
        colorAlert.popoverPresentationController.sourceRect = ([colorType isEqualToString:@"dashboard"]) ? self.dashboardColorButton.bounds : self.navbarColorButton.bounds;
    }
    
    [self presentViewController:colorAlert animated:YES completion:nil];
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    // Remove # if present
    if ([hexString hasPrefix:@"#"]) {
        hexString = [hexString substringFromIndex:1];
    }
    
    // Check for valid length
    if (hexString.length != 6) {
        return nil;
    }
    
    // Check for valid hex characters
    NSCharacterSet *hexCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"];
    NSCharacterSet *invalidChars = [hexCharSet invertedSet];
    if ([hexString rangeOfCharacterFromSet:invalidChars].location != NSNotFound) {
        return nil;
    }
    
    // Parse RGB components
    unsigned int rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&rgbValue];
    
    CGFloat red = ((rgbValue & 0xFF0000) >> 16) / 255.0;
    CGFloat green = ((rgbValue & 0x00FF00) >> 8) / 255.0;
    CGFloat blue = (rgbValue & 0x0000FF) / 255.0;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

- (void)showInvalidHexColorAlert {
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Invalid Hex Color"
                                                                        message:@"Please enter a valid hex color code (e.g., #FF5733 or FF5733)"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [errorAlert addAction:okAction];
    
    [self presentViewController:errorAlert animated:YES completion:nil];
}

#pragma mark - Image Picker

- (void)showImagePicker {
    // Check photo library permission
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    [self presentImagePicker];
                } else {
                    [self showPhotoPermissionAlert];
                }
            });
        }];
    } else if (status == PHAuthorizationStatusAuthorized) {
        [self presentImagePicker];
    } else {
        [self showPhotoPermissionAlert];
    }
}

- (void)presentImagePicker {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = NO; // We'll handle editing in our preview controller
    
    // Fix landscape orientation issue - set modal presentation style
    imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)showPhotoPermissionAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Photo Access Required"
                                                                   message:@"Please allow access to your photo library in Settings to use custom background images."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Settings"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:settingsAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *selectedImage = info[UIImagePickerControllerOriginalImage];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        if (selectedImage) {
            // Present the image preview controller for cropping and positioning
            ImagePreviewViewController *previewController = [[ImagePreviewViewController alloc] initWithImage:selectedImage];
            previewController.delegate = self;
            previewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:previewController animated:YES completion:nil];
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ImagePreviewViewControllerDelegate

- (void)imagePreviewViewController:(ImagePreviewViewController *)controller didFinishWithImage:(UIImage *)croppedImage scale:(CGFloat)scale offset:(CGPoint)offset {
    [controller dismissViewControllerAnimated:YES completion:^{
        if (croppedImage) {
            // Resize image to reduce memory usage while maintaining quality
            self.selectedBackgroundImage = [self resizeImage:croppedImage toMaxSize:CGSizeMake(1024, 1024)];
            
            // Save scale and offset for later use
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setFloat:scale forKey:@"ha_background_scale"];
            [defaults setFloat:offset.x forKey:@"ha_background_offset_x"];
            [defaults setFloat:offset.y forKey:@"ha_background_offset_y"];
            
            // Update the button to show a preview or checkmark
            if (self.backgroundImageButton) {
                [self.backgroundImageButton setTitle:@"✓ Image Selected" forState:UIControlStateNormal];
                self.backgroundImageButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.3 alpha:1.0];
            }
        }
    }];
}

- (void)imagePreviewViewControllerDidCancel:(ImagePreviewViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Image Utility

- (UIImage *)resizeImage:(UIImage *)image toMaxSize:(CGSize)maxSize {
    CGSize imageSize = image.size;
    CGFloat ratio = MIN(maxSize.width / imageSize.width, maxSize.height / imageSize.height);
    
    if (ratio >= 1.0) {
        return image; // No need to resize
    }
    
    CGSize newSize = CGSizeMake(imageSize.width * ratio, imageSize.height * ratio);
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

@end