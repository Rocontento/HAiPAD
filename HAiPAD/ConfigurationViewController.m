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
@property (nonatomic, weak) id<HomeAssistantClientDelegate> originalDelegate;
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

@end