//
//  DashboardViewController.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "DashboardViewController.h"
#import "ConfigurationViewController.h"
#import "EntitySettingsViewController.h"

@interface DashboardViewController ()
@property (nonatomic, strong) NSArray *entities;
@property (nonatomic, strong) NSArray *allEntities;
@property (nonatomic, strong) NSSet *enabledEntityIds;
@property (nonatomic, strong) HomeAssistantClient *homeAssistantClient;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@end

@implementation DashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Home Assistant";
    self.entities = @[];
    self.allEntities = @[];
    self.enabledEntityIds = [NSSet set];
    self.homeAssistantClient = [HomeAssistantClient sharedClient];
    self.homeAssistantClient.delegate = self;
    
    // Set up table view
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    // Load saved configuration
    [self loadConfiguration];
    
    // Load entity settings
    [self loadEntitySettings];
    
    // Set up refresh control for iOS 9.3.5 compatibility
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshButtonTapped:) forControlEvents:UIControlEventValueChanged];
    
    // Use iOS 10+ property if available, otherwise use legacy method for iOS 9.3
    if ([self.tableView respondsToSelector:@selector(setRefreshControl:)]) {
        self.tableView.refreshControl = self.refreshControl;
    } else {
        [self.tableView addSubview:self.refreshControl];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Reload entity settings in case they changed
    [self loadEntitySettings];
    
    if (self.homeAssistantClient.isConnected) {
        [self.homeAssistantClient fetchStates];
    }
}

- (void)loadConfiguration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *baseURL = [defaults stringForKey:@"ha_base_url"];
    NSString *accessToken = [defaults stringForKey:@"ha_access_token"];
    
    if (baseURL && accessToken) {
        [self.homeAssistantClient connectWithBaseURL:baseURL accessToken:accessToken];
        self.statusLabel.text = @"Connecting...";
        self.statusLabel.textColor = [UIColor orangeColor];
    } else {
        self.statusLabel.text = @"Not configured";
        self.statusLabel.textColor = [UIColor redColor];
    }
}

- (void)loadEntitySettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *savedEntityIds = [defaults arrayForKey:@"ha_enabled_entities"];
    
    if (savedEntityIds) {
        self.enabledEntityIds = [NSSet setWithArray:savedEntityIds];
    } else {
        // If no settings saved, enable all entities by default
        self.enabledEntityIds = [NSSet set];
    }
    
    // Filter entities based on settings if we have entities loaded
    if (self.allEntities.count > 0) {
        [self filterEntitiesBasedOnSettings];
    }
}

#pragma mark - IBActions

- (IBAction)configButtonTapped:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ConfigurationViewController *configVC = [storyboard instantiateViewControllerWithIdentifier:@"ConfigurationViewController"];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:configVC];
    [self presentViewController:navController animated:YES completion:nil];
}

- (IBAction)refreshButtonTapped:(id)sender {
    if (self.homeAssistantClient.isConnected) {
        [self.homeAssistantClient fetchStates];
    } else {
        [self loadConfiguration];
    }
    
    // Stop refresh control if it's active
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
}

- (IBAction)entitiesButtonTapped:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EntitySettingsViewController *entitiesVC = [storyboard instantiateViewControllerWithIdentifier:@"EntitySettingsViewController"];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:entitiesVC];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)filterEntitiesBasedOnSettings {
    if (self.enabledEntityIds.count == 0) {
        // If no settings saved, show all entities
        self.entities = self.allEntities;
    } else {
        // Filter entities based on enabled settings
        NSMutableArray *filteredEntities = [NSMutableArray array];
        for (NSDictionary *entity in self.allEntities) {
            NSString *entityId = entity[@"entity_id"];
            if ([self.enabledEntityIds containsObject:entityId]) {
                [filteredEntities addObject:entity];
            }
        }
        self.entities = filteredEntities;
    }
    
    [self.tableView reloadData];
}

#pragma mark - HomeAssistantClientDelegate

- (void)homeAssistantClientDidConnect:(HomeAssistantClient *)client {
    self.statusLabel.text = @"Connected";
    self.statusLabel.textColor = [UIColor greenColor];
}

- (void)homeAssistantClientDidDisconnect:(HomeAssistantClient *)client {
    self.statusLabel.text = @"Disconnected";
    self.statusLabel.textColor = [UIColor redColor];
    self.entities = @[];
    [self.tableView reloadData];
}

- (void)homeAssistantClient:(HomeAssistantClient *)client didReceiveStates:(NSArray *)states {
    // Filter for common entity types that are useful in a dashboard
    NSMutableArray *filteredEntities = [NSMutableArray array];
    
    for (NSDictionary *entity in states) {
        NSString *entityId = entity[@"entity_id"];
        if (entityId) {
            // Include lights, switches, sensors, and climate entities
            if ([entityId hasPrefix:@"light."] ||
                [entityId hasPrefix:@"switch."] ||
                [entityId hasPrefix:@"sensor."] ||
                [entityId hasPrefix:@"binary_sensor."] ||
                [entityId hasPrefix:@"climate."] ||
                [entityId hasPrefix:@"cover."] ||
                [entityId hasPrefix:@"fan."] ||
                [entityId hasPrefix:@"lock."]) {
                [filteredEntities addObject:entity];
            }
        }
    }
    
    // Sort entities by friendly name
    self.allEntities = [filteredEntities sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        NSString *name1 = obj1[@"attributes"][@"friendly_name"] ?: obj1[@"entity_id"];
        NSString *name2 = obj2[@"attributes"][@"friendly_name"] ?: obj2[@"entity_id"];
        return [name1 compare:name2];
    }];
    
    // Apply entity filtering based on user settings
    [self filterEntitiesBasedOnSettings];
    
    // Stop refresh control if it's active
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
}

- (void)homeAssistantClient:(HomeAssistantClient *)client didFailWithError:(NSError *)error {
    self.statusLabel.text = [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
    self.statusLabel.textColor = [UIColor redColor];
    
    // Stop refresh control if it's active
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
    
    // Show alert for errors
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.entities.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EntityCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"EntityCell"];
    }
    
    NSDictionary *entity = self.entities[indexPath.row];
    NSString *entityId = entity[@"entity_id"];
    NSString *friendlyName = entity[@"attributes"][@"friendly_name"] ?: entityId;
    NSString *state = entity[@"state"];
    
    cell.textLabel.text = friendlyName;
    cell.detailTextLabel.text = state;
    
    // Set appropriate accessory and styling based on entity type
    if ([entityId hasPrefix:@"light."] || [entityId hasPrefix:@"switch."] || [entityId hasPrefix:@"fan."]) {
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        if ([state isEqualToString:@"on"]) {
            cell.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.8 alpha:1.0]; // Light yellow
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
    } else if ([entityId hasPrefix:@"cover."]) {
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        cell.backgroundColor = [UIColor whiteColor];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *entity = self.entities[indexPath.row];
    NSString *entityId = entity[@"entity_id"];
    NSString *state = entity[@"state"];
    
    // Handle tappable entities
    if ([entityId hasPrefix:@"light."]) {
        if ([state isEqualToString:@"on"]) {
            [self.homeAssistantClient callService:@"light" service:@"turn_off" entityId:entityId];
        } else {
            [self.homeAssistantClient callService:@"light" service:@"turn_on" entityId:entityId];
        }
    } else if ([entityId hasPrefix:@"switch."]) {
        if ([state isEqualToString:@"on"]) {
            [self.homeAssistantClient callService:@"switch" service:@"turn_off" entityId:entityId];
        } else {
            [self.homeAssistantClient callService:@"switch" service:@"turn_on" entityId:entityId];
        }
    } else if ([entityId hasPrefix:@"fan."]) {
        if ([state isEqualToString:@"on"]) {
            [self.homeAssistantClient callService:@"fan" service:@"turn_off" entityId:entityId];
        } else {
            [self.homeAssistantClient callService:@"fan" service:@"turn_on" entityId:entityId];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entity = self.entities[indexPath.row];
    NSString *entityId = entity[@"entity_id"];
    NSString *friendlyName = entity[@"attributes"][@"friendly_name"] ?: entityId;
    NSString *state = entity[@"state"];
    
    // Show entity details
    NSString *message = [NSString stringWithFormat:@"Entity ID: %@\nState: %@", entityId, state];
    
    NSDictionary *attributes = entity[@"attributes"];
    if (attributes) {
        NSMutableString *attributesString = [NSMutableString stringWithString:message];
        [attributesString appendString:@"\n\nAttributes:"];
        for (NSString *key in attributes) {
            id value = attributes[key];
            [attributesString appendFormat:@"\n%@: %@", key, value];
        }
        message = attributesString;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:friendlyName
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end