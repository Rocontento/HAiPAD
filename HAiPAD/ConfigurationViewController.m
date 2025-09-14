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

@interface ConfigurationViewController () <HomeAssistantClientDelegate>
@property (nonatomic, strong) HomeAssistantClient *testClient;
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
    
    // Configure grid size slider (legacy - for backward compatibility)
    if (self.gridSizeSlider) {
        self.gridSizeSlider.minimumValue = 1.0;
        self.gridSizeSlider.maximumValue = 8.0;
        self.gridSizeSlider.continuous = YES;
        [self.gridSizeSlider addTarget:self action:@selector(gridSizeSliderChanged:) forControlEvents:UIControlEventValueChanged];
    }
    
    // Create new grid width and height controls programmatically
    [self createSeparateGridControls];
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
    
    // Load column preference (default to 2 columns)
    NSInteger columnCount = [defaults integerForKey:@"ha_column_count"];
    if (columnCount == 0) {
        columnCount = 2; // Default to 2 columns
    }
    
    // Set segmented control to correct index (1-4 columns maps to indices 0-3)
    self.columnsSegmentedControl.selectedSegmentIndex = columnCount - 1;
    
    // Load grid size preference (legacy - kept for backward compatibility with existing installations)
    if (self.gridSizeSlider && self.gridSizeLabel) {
        NSInteger gridSize = [defaults integerForKey:@"ha_grid_size"];
        if (gridSize == 0) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                gridSize = 6; // Default 6x6 for iPad
            } else {
                gridSize = 4; // Default 4x4 for iPhone
            }
        }
        
        self.gridSizeSlider.value = gridSize;
        [self updateGridSizeLabel];
    }
    
    // Load grid width preference (new)
    if (self.gridWidthSlider && self.gridWidthLabel) {
        NSInteger gridWidth = [defaults integerForKey:@"ha_grid_width"];
        if (gridWidth == 0) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                gridWidth = 4; // Default 4 columns for iPad
            } else {
                gridWidth = 2; // Default 2 columns for iPhone
            }
        }
        
        self.gridWidthSlider.value = gridWidth;
        [self updateGridWidthLabel];
    } else {
        // If controls are created programmatically, they will be loaded in createSeparateGridControls
    }
    
    // Load grid height preference (new)
    if (self.gridHeightSlider && self.gridHeightLabel) {
        NSInteger gridHeight = [defaults integerForKey:@"ha_grid_height"];
        if (gridHeight == 0) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                gridHeight = 6; // Default 6 rows for iPad
            } else {
                gridHeight = 4; // Default 4 rows for iPhone
            }
        }
        
        self.gridHeightSlider.value = gridHeight;
        [self updateGridHeightLabel];
    } else {
        // If controls are created programmatically, they will be loaded in createSeparateGridControls
    }
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
    
    // Save column preference (segmented control index 0-3 maps to 1-4 columns)
    NSInteger columnCount = self.columnsSegmentedControl.selectedSegmentIndex + 1;
    [defaults setInteger:columnCount forKey:@"ha_column_count"];
    
    // Save grid size preference (legacy - for backward compatibility)
    if (self.gridSizeSlider) {
        NSInteger gridSize = (NSInteger)self.gridSizeSlider.value;
        [defaults setInteger:gridSize forKey:@"ha_grid_size"];
    }
    
    // Save grid width preference (new)
    if (self.gridWidthSlider) {
        NSInteger gridWidth = (NSInteger)self.gridWidthSlider.value;
        [defaults setInteger:gridWidth forKey:@"ha_grid_width"];
    }
    
    // Save grid height preference (new)
    if (self.gridHeightSlider) {
        NSInteger gridHeight = (NSInteger)self.gridHeightSlider.value;
        [defaults setInteger:gridHeight forKey:@"ha_grid_height"];
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
    
    [defaults synchronize];
    
    // Connect with new configuration
    HomeAssistantClient *client = [HomeAssistantClient sharedClient];
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

- (IBAction)gridSizeSliderChanged:(id)sender {
    [self updateGridSizeLabel];
}

- (IBAction)gridWidthSliderChanged:(id)sender {
    [self updateGridWidthLabel];
}

- (IBAction)gridHeightSliderChanged:(id)sender {
    [self updateGridHeightLabel];
}

- (void)updateGridSizeLabel {
    if (self.gridSizeSlider && self.gridSizeLabel) {
        NSInteger gridSize = (NSInteger)self.gridSizeSlider.value;
        self.gridSizeLabel.text = [NSString stringWithFormat:@"Grid Size: %ldx%ld", (long)gridSize, (long)gridSize];
    }
}

- (void)updateGridWidthLabel {
    if (self.gridWidthSlider && self.gridWidthLabel) {
        NSInteger gridWidth = (NSInteger)self.gridWidthSlider.value;
        self.gridWidthLabel.text = [NSString stringWithFormat:@"Grid Width: %ld columns", (long)gridWidth];
    }
}

- (void)updateGridHeightLabel {
    if (self.gridHeightSlider && self.gridHeightLabel) {
        NSInteger gridHeight = (NSInteger)self.gridHeightSlider.value;
        self.gridHeightLabel.text = [NSString stringWithFormat:@"Grid Height: %ld rows", (long)gridHeight];
    }
}

#pragma mark - UI Creation Methods

- (void)createSeparateGridControls {
    // Create separate grid controls below the original grid slider
    UIView *parentView = self.gridSizeSlider.superview;
    if (!parentView) return;
    
    // Create grid width label
    self.gridWidthLabel = [[UILabel alloc] init];
    self.gridWidthLabel.text = @"Grid Width: 4 columns";
    self.gridWidthLabel.font = [UIFont systemFontOfSize:17];
    self.gridWidthLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [parentView addSubview:self.gridWidthLabel];
    
    // Create grid width slider
    self.gridWidthSlider = [[UISlider alloc] init];
    self.gridWidthSlider.minimumValue = 2.0;
    self.gridWidthSlider.maximumValue = 8.0;
    self.gridWidthSlider.continuous = YES;
    self.gridWidthSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.gridWidthSlider addTarget:self action:@selector(gridWidthSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [parentView addSubview:self.gridWidthSlider];
    
    // Create grid height label
    self.gridHeightLabel = [[UILabel alloc] init];
    self.gridHeightLabel.text = @"Grid Height: 6 rows";
    self.gridHeightLabel.font = [UIFont systemFontOfSize:17];
    self.gridHeightLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [parentView addSubview:self.gridHeightLabel];
    
    // Create grid height slider
    self.gridHeightSlider = [[UISlider alloc] init];
    self.gridHeightSlider.minimumValue = 2.0;
    self.gridHeightSlider.maximumValue = 10.0;
    self.gridHeightSlider.continuous = YES;
    self.gridHeightSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.gridHeightSlider addTarget:self action:@selector(gridHeightSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [parentView addSubview:self.gridHeightSlider];
    
    // Add constraints
    [NSLayoutConstraint activateConstraints:@[
        // Grid width label constraints
        [self.gridWidthLabel.topAnchor constraintEqualToAnchor:self.gridSizeSlider.bottomAnchor constant:30],
        [self.gridWidthLabel.leadingAnchor constraintEqualToAnchor:parentView.leadingAnchor constant:20],
        
        // Grid width slider constraints
        [self.gridWidthSlider.topAnchor constraintEqualToAnchor:self.gridWidthLabel.bottomAnchor constant:8],
        [self.gridWidthSlider.leadingAnchor constraintEqualToAnchor:parentView.leadingAnchor constant:20],
        [self.gridWidthSlider.trailingAnchor constraintEqualToAnchor:parentView.trailingAnchor constant:-20],
        
        // Grid height label constraints
        [self.gridHeightLabel.topAnchor constraintEqualToAnchor:self.gridWidthSlider.bottomAnchor constant:20],
        [self.gridHeightLabel.leadingAnchor constraintEqualToAnchor:parentView.leadingAnchor constant:20],
        
        // Grid height slider constraints
        [self.gridHeightSlider.topAnchor constraintEqualToAnchor:self.gridHeightLabel.bottomAnchor constant:8],
        [self.gridHeightSlider.leadingAnchor constraintEqualToAnchor:parentView.leadingAnchor constant:20],
        [self.gridHeightSlider.trailingAnchor constraintEqualToAnchor:parentView.trailingAnchor constant:-20],
    ]];
    
    // Load initial values
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger gridWidth = [defaults integerForKey:@"ha_grid_width"];
    NSInteger gridHeight = [defaults integerForKey:@"ha_grid_height"];
    
    if (gridWidth == 0) {
        gridWidth = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 4 : 2;
    }
    if (gridHeight == 0) {
        gridHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 6 : 4;
    }
    
    self.gridWidthSlider.value = gridWidth;
    self.gridHeightSlider.value = gridHeight;
    [self updateGridWidthLabel];
    [self updateGridHeightLabel];
}

@end