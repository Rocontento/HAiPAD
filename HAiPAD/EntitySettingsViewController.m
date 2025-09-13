//
//  EntitySettingsViewController.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "EntitySettingsViewController.h"

@interface EntitySettingsViewController ()
@property (nonatomic, strong) NSArray *allEntities;
@property (nonatomic, strong) NSMutableSet *enabledEntityIds;
@property (nonatomic, strong) HomeAssistantClient *homeAssistantClient;
@end

@implementation EntitySettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Select Entities";
    self.allEntities = @[];
    self.enabledEntityIds = [NSMutableSet set];
    
    // Set up navigation bar
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped:)];
    
    // Set up table view
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    // Load current settings
    [self loadEntitySettings];
    
    // Set up Home Assistant client
    self.homeAssistantClient = [HomeAssistantClient sharedClient];
    self.homeAssistantClient.delegate = self;
    
    // Fetch current entities
    if (self.homeAssistantClient.isConnected) {
        [self.homeAssistantClient fetchStates];
        self.statusLabel.text = @"Loading entities...";
        self.statusLabel.textColor = [UIColor orangeColor];
    } else {
        self.statusLabel.text = @"Not connected to Home Assistant";
        self.statusLabel.textColor = [UIColor redColor];
    }
}

- (void)loadEntitySettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *savedEntityIds = [defaults arrayForKey:@"ha_enabled_entities"];
    
    if (savedEntityIds) {
        self.enabledEntityIds = [NSMutableSet setWithArray:savedEntityIds];
    } else {
        // If no settings saved, enable all entities by default
        self.enabledEntityIds = [NSMutableSet set];
    }
}

- (void)saveEntitySettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.enabledEntityIds allObjects] forKey:@"ha_enabled_entities"];
    [defaults synchronize];
}

#pragma mark - IBActions

- (IBAction)doneButtonTapped:(id)sender {
    [self saveEntitySettings];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - HomeAssistantClientDelegate

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
    
    // If no entities were previously saved, enable all by default
    if (self.enabledEntityIds.count == 0) {
        for (NSDictionary *entity in self.allEntities) {
            [self.enabledEntityIds addObject:entity[@"entity_id"]];
        }
    }
    
    [self.tableView reloadData];
    self.statusLabel.text = [NSString stringWithFormat:@"%lu entities available", (unsigned long)self.allEntities.count];
    self.statusLabel.textColor = [UIColor darkGrayColor];
}

- (void)homeAssistantClient:(HomeAssistantClient *)client didFailWithError:(NSError *)error {
    self.statusLabel.text = [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
    self.statusLabel.textColor = [UIColor redColor];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.allEntities.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EntitySettingCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"EntitySettingCell"];
    }
    
    NSDictionary *entity = self.allEntities[indexPath.row];
    NSString *entityId = entity[@"entity_id"];
    NSString *friendlyName = entity[@"attributes"][@"friendly_name"] ?: entityId;
    NSString *state = entity[@"state"];
    
    cell.textLabel.text = friendlyName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", entityId, state];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    // Set checkmark based on enabled state
    BOOL isEnabled = [self.enabledEntityIds containsObject:entityId];
    cell.accessoryType = isEnabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *entity = self.allEntities[indexPath.row];
    NSString *entityId = entity[@"entity_id"];
    
    // Toggle enabled state
    if ([self.enabledEntityIds containsObject:entityId]) {
        [self.enabledEntityIds removeObject:entityId];
    } else {
        [self.enabledEntityIds addObject:entityId];
    }
    
    // Update cell appearance
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    BOOL isEnabled = [self.enabledEntityIds containsObject:entityId];
    cell.accessoryType = isEnabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

@end