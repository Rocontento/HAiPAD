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
    
    // Create grid size segmented control if not connected via Interface Builder
    [self setupGridSizeControl];
}

- (void)setupGridSizeControl {
    // If the grid size control is not connected via Interface Builder, create it programmatically
    if (!self.gridSizeSegmentedControl) {
        NSArray *gridSizeOptions = @[@"Small (3×4)", @"Medium (4×6)", @"Large (5×8)"];
        self.gridSizeSegmentedControl = [[UISegmentedControl alloc] initWithItems:gridSizeOptions];
        
        // Position below the columns control (approximate positioning)
        CGRect columnsFrame = self.columnsSegmentedControl.frame;
        CGRect gridSizeFrame = CGRectMake(
            columnsFrame.origin.x,
            columnsFrame.origin.y + columnsFrame.size.height + 20,
            columnsFrame.size.width,
            columnsFrame.size.height
        );
        self.gridSizeSegmentedControl.frame = gridSizeFrame;
        
        // Style to match existing controls
        self.gridSizeSegmentedControl.tintColor = self.columnsSegmentedControl.tintColor;
        
        // Add to view
        [self.view addSubview:self.gridSizeSegmentedControl];
        
        // Add label
        UILabel *gridSizeLabel = [[UILabel alloc] init];
        gridSizeLabel.text = @"Grid Size:";
        gridSizeLabel.font = [UIFont systemFontOfSize:16];
        gridSizeLabel.textColor = [UIColor blackColor];
        
        CGRect labelFrame = CGRectMake(
            gridSizeFrame.origin.x,
            gridSizeFrame.origin.y - 25,
            gridSizeFrame.size.width,
            20
        );
        gridSizeLabel.frame = labelFrame;
        
        [self.view addSubview:gridSizeLabel];
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
    
    // Load column preference (default to 2 columns)
    NSInteger columnCount = [defaults integerForKey:@"ha_column_count"];
    if (columnCount == 0) {
        columnCount = 2; // Default to 2 columns
    }
    
    // Set segmented control to correct index (1-4 columns maps to indices 0-3)
    self.columnsSegmentedControl.selectedSegmentIndex = columnCount - 1;
    
    // Load grid size preference (default to medium: 4x6)
    NSInteger gridSizeIndex = [defaults integerForKey:@"ha_grid_size"];
    if (gridSizeIndex == 0) {
        gridSizeIndex = 1; // Default to medium (4x6)
    }
    
    // Set grid size segmented control (0=Small 3x4, 1=Medium 4x6, 2=Large 5x8)
    if (self.gridSizeSegmentedControl) {
        self.gridSizeSegmentedControl.selectedSegmentIndex = gridSizeIndex;
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
    
    // Save grid size preference (index 0=Small 3x4, 1=Medium 4x6, 2=Large 5x8)
    NSInteger gridSizeIndex = 1; // Default to medium
    if (self.gridSizeSegmentedControl) {
        gridSizeIndex = self.gridSizeSegmentedControl.selectedSegmentIndex;
    }
    [defaults setInteger:gridSizeIndex forKey:@"ha_grid_size"];
    
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

@end