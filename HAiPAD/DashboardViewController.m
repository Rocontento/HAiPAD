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
#import "EntityCardCell.h"
#import "WhiteboardLayout.h"
#import "GridOverlayView.h"

@interface DashboardViewController ()
@property (nonatomic, strong) NSArray *entities;
@property (nonatomic, strong) NSArray *allEntities;
@property (nonatomic, strong) NSSet *enabledEntityIds;
@property (nonatomic, strong) HomeAssistantClient *homeAssistantClient;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, assign) NSInteger columnCount;
@property (nonatomic, strong) WhiteboardLayout *whiteboardLayout;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) NSIndexPath *draggingIndexPath;
@property (nonatomic, assign) CGPoint initialDragOffset;
@property (nonatomic, strong) UIView *draggingView;
@property (nonatomic, strong) GridOverlayView *gridOverlay;
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
    
    // Set up whiteboard layout
    self.whiteboardLayout = [[WhiteboardLayout alloc] init];
    self.whiteboardLayout.gridSize = CGSizeMake(160, 120);
    self.whiteboardLayout.gridSpacing = 20;
    
    // Set up collection view with whiteboard layout
    self.collectionView.collectionViewLayout = self.whiteboardLayout;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    
    // Enable scrolling in both directions for whiteboard
    self.collectionView.scrollEnabled = YES;
    self.collectionView.bounces = YES;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.alwaysBounceHorizontal = YES;
    
    // Set up grid overlay
    [self setupGridOverlay];
    
    // Add gesture recognizers for drag and drop
    [self setupGestureRecognizers];
    
    // Load saved configuration
    [self loadConfiguration];
    
    // Load entity settings
    [self loadEntitySettings];
    
    // Load saved card positions
    [self loadCardPositions];
    
    // Set up refresh control for iOS 9.3.5 compatibility
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshButtonTapped:) forControlEvents:UIControlEventValueChanged];
    
    // Add refresh control to collection view
    [self.collectionView addSubview:self.refreshControl];
    [self.collectionView sendSubviewToBack:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Reload entity settings in case they changed
    [self loadEntitySettings];
    
    // Reload configuration in case column count changed
    [self loadConfiguration];
    
    // Reload layout to apply any column changes
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    if (self.homeAssistantClient.isConnected) {
        [self.homeAssistantClient fetchStates];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Update grid overlay frame to match collection view content size
    if (self.gridOverlay) {
        CGSize contentSize = self.whiteboardLayout.collectionViewContentSize;
        self.gridOverlay.frame = CGRectMake(0, 0, 
                                           MAX(contentSize.width, self.collectionView.bounds.size.width),
                                           MAX(contentSize.height, self.collectionView.bounds.size.height));
    }
}

- (void)loadConfiguration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *baseURL = [defaults stringForKey:@"ha_base_url"];
    NSString *accessToken = [defaults stringForKey:@"ha_access_token"];
    
    // Load column count preference (default to 2 columns)
    self.columnCount = [defaults integerForKey:@"ha_column_count"];
    if (self.columnCount == 0) {
        self.columnCount = 2; // Default to 2 columns
    }
    
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

#pragma mark - Gesture Recognizers

- (void)setupGridOverlay {
    // Create grid overlay that matches collection view content size
    self.gridOverlay = [[GridOverlayView alloc] initWithFrame:self.collectionView.bounds];
    self.gridOverlay.gridSize = self.whiteboardLayout.gridSize;
    self.gridOverlay.gridSpacing = self.whiteboardLayout.gridSpacing;
    [self.collectionView addSubview:self.gridOverlay];
    [self.collectionView sendSubviewToBack:self.gridOverlay];
}

- (void)setupGestureRecognizers {
    // Long press gesture to start dragging
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPressGesture.minimumPressDuration = 0.5;
    [self.collectionView addGestureRecognizer:self.longPressGesture];
    
    // Pan gesture for dragging
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.panGesture.enabled = NO; // Initially disabled
    [self.collectionView addGestureRecognizer:self.panGesture];
    
    // Double tap gesture to toggle grid visibility
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.collectionView addGestureRecognizer:doubleTapGesture];
    
    // Make sure single tap doesn't interfere with double tap
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
    [self.collectionView addGestureRecognizer:singleTapGesture];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture {
    // Toggle grid visibility on double tap
    BOOL currentlyVisible = self.gridOverlay.showGrid;
    [self.gridOverlay setGridVisible:!currentlyVisible animated:YES];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)gesture {
    // Handle single tap if needed - currently handled by collection view delegate
    // This is mainly here to properly handle the gesture precedence
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.collectionView];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
            if (indexPath) {
                [self startDraggingItemAtIndexPath:indexPath withLocation:location];
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self endDragging];
            break;
        default:
            break;
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if (!self.draggingIndexPath) return;
    
    CGPoint location = [gesture locationInView:self.collectionView];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateChanged:
            [self updateDraggingViewPosition:location];
            break;
        case UIGestureRecognizerStateEnded:
            [self finishDragging:location];
            break;
        case UIGestureRecognizerStateCancelled:
            [self cancelDragging];
            break;
        default:
            break;
    }
}

#pragma mark - Drag and Drop Implementation

- (void)startDraggingItemAtIndexPath:(NSIndexPath *)indexPath withLocation:(CGPoint)location {
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if (!cell) return;
    
    self.draggingIndexPath = indexPath;
    
    // Show grid overlay during dragging
    [self.gridOverlay setGridVisible:YES animated:YES];
    
    // Create a snapshot view for dragging
    self.draggingView = [self createDraggingViewFromCell:cell];
    [self.collectionView addSubview:self.draggingView];
    
    // Calculate offset from touch to cell center
    CGPoint cellCenter = cell.center;
    self.initialDragOffset = CGPointMake(location.x - cellCenter.x, location.y - cellCenter.y);
    
    // Position the dragging view
    self.draggingView.center = location;
    
    // Hide the original cell
    cell.hidden = YES;
    
    // Add visual feedback
    [UIView animateWithDuration:0.2 animations:^{
        self.draggingView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        self.draggingView.alpha = 0.9;
    }];
    
    // Enable pan gesture
    self.panGesture.enabled = YES;
}

- (UIView *)createDraggingViewFromCell:(UICollectionViewCell *)cell {
    // Create a snapshot of the cell
    UIView *snapshot = [cell snapshotViewAfterScreenUpdates:NO];
    snapshot.frame = cell.frame;
    
    // Add shadow for visual feedback
    snapshot.layer.shadowColor = [UIColor blackColor].CGColor;
    snapshot.layer.shadowOffset = CGSizeMake(0, 5);
    snapshot.layer.shadowOpacity = 0.3;
    snapshot.layer.shadowRadius = 10;
    
    return snapshot;
}

- (void)updateDraggingViewPosition:(CGPoint)location {
    if (!self.draggingView) return;
    
    // Update dragging view position
    self.draggingView.center = CGPointMake(location.x - self.initialDragOffset.x, 
                                          location.y - self.initialDragOffset.y);
    
    // Visual feedback for valid drop zones could be added here
    // For now, just ensure the view follows the touch
}

- (void)finishDragging:(CGPoint)location {
    if (!self.draggingIndexPath || !self.draggingView) return;
    
    // Calculate final position (minus the offset)
    CGPoint finalPosition = CGPointMake(location.x - self.initialDragOffset.x, 
                                       location.y - self.initialDragOffset.y);
    
    // Snap to grid
    CGPoint snappedPosition = [self.whiteboardLayout snapToGrid:finalPosition];
    
    // Update the layout with new position
    [self.whiteboardLayout setPosition:snappedPosition forItemAtIndexPath:self.draggingIndexPath];
    
    // Save the new position
    [self saveCardPositions];
    
    // Animate to final position
    [UIView animateWithDuration:0.3 animations:^{
        self.draggingView.center = CGPointMake(snappedPosition.x + self.whiteboardLayout.gridSize.width / 2,
                                              snappedPosition.y + self.whiteboardLayout.gridSize.height / 2);
        self.draggingView.transform = CGAffineTransformIdentity;
        self.draggingView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [self endDragging];
    }];
}

- (void)cancelDragging {
    // Return to original position
    if (self.draggingIndexPath && self.draggingView) {
        UICollectionViewLayoutAttributes *attributes = [self.whiteboardLayout layoutAttributesForItemAtIndexPath:self.draggingIndexPath];
        
        [UIView animateWithDuration:0.3 animations:^{
            self.draggingView.center = CGPointMake(attributes.center.x, attributes.center.y);
            self.draggingView.transform = CGAffineTransformIdentity;
            self.draggingView.alpha = 1.0;
        } completion:^(BOOL finished) {
            [self endDragging];
        }];
    }
}

- (void)endDragging {
    // Hide grid overlay when dragging ends
    [self.gridOverlay setGridVisible:NO animated:YES];
    
    // Clean up dragging state
    if (self.draggingIndexPath) {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:self.draggingIndexPath];
        cell.hidden = NO;
    }
    
    [self.draggingView removeFromSuperview];
    self.draggingView = nil;
    self.draggingIndexPath = nil;
    self.panGesture.enabled = NO;
    
    // Reload layout to ensure everything is positioned correctly
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - Position Persistence

- (void)loadCardPositions {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *savedPositions = [defaults dictionaryForKey:@"ha_card_positions"];
    
    if (savedPositions) {
        NSMutableDictionary *positions = [NSMutableDictionary dictionary];
        
        for (NSString *key in savedPositions) {
            NSArray *pointArray = savedPositions[key];
            if (pointArray.count == 2) {
                CGFloat x = [pointArray[0] floatValue];
                CGFloat y = [pointArray[1] floatValue];
                positions[key] = [NSValue valueWithCGPoint:CGPointMake(x, y)];
            }
        }
        
        self.whiteboardLayout.itemPositions = positions;
    }
}

- (void)saveCardPositions {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *positionsToSave = [NSMutableDictionary dictionary];
    
    for (NSString *key in self.whiteboardLayout.itemPositions) {
        NSValue *positionValue = self.whiteboardLayout.itemPositions[key];
        CGPoint position = [positionValue CGPointValue];
        positionsToSave[key] = @[@(position.x), @(position.y)];
    }
    
    [defaults setObject:positionsToSave forKey:@"ha_card_positions"];
    [defaults synchronize];
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
    
    [self.collectionView reloadData];
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
    [self.collectionView reloadData];
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

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.entities.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EntityCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EntityCardCell" forIndexPath:indexPath];
    
    NSDictionary *entity = self.entities[indexPath.item];
    [cell configureWithEntity:entity];
    
    // Add target for info button
    [cell.infoButton addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    cell.infoButton.tag = indexPath.item;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    // Don't handle selection if we're in dragging mode
    if (self.draggingIndexPath) return;
    
    // Add visual feedback for the tap
    EntityCardCell *cell = (EntityCardCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self animateCardTap:cell];
    
    NSDictionary *entity = self.entities[indexPath.item];
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
    } else if ([entityId hasPrefix:@"climate."]) {
        [self showClimateControlForEntity:entity];
    } else if ([entityId hasPrefix:@"cover."]) {
        [self showCoverControlForEntity:entity];
    } else if ([entityId hasPrefix:@"lock."]) {
        [self showLockControlForEntity:entity];
    } else if ([entityId hasPrefix:@"sensor."] || [entityId hasPrefix:@"binary_sensor."]) {
        // Sensors are read-only, show info instead
        [self showSensorInfoForEntity:entity];
    }
}

#pragma mark - Action Methods

- (void)infoButtonTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < self.entities.count) {
        NSDictionary *entity = self.entities[index];
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
}

#pragma mark - Entity Control Methods

- (void)showClimateControlForEntity:(NSDictionary *)entity {
    NSString *entityId = entity[@"entity_id"];
    NSString *friendlyName = entity[@"attributes"][@"friendly_name"] ?: entityId;
    NSString *state = entity[@"state"];
    NSNumber *currentTemp = entity[@"attributes"][@"current_temperature"];
    NSNumber *targetTemp = entity[@"attributes"][@"temperature"];
    NSString *unit = entity[@"attributes"][@"temperature_unit"] ?: @"°C";
    
    NSString *message;
    if (currentTemp && targetTemp) {
        message = [NSString stringWithFormat:@"Current: %.1f%@\nTarget: %.1f%@", 
                  currentTemp.floatValue, unit, targetTemp.floatValue, unit];
    } else if (currentTemp) {
        message = [NSString stringWithFormat:@"Current: %.1f%@\nState: %@", 
                  currentTemp.floatValue, unit, [state capitalizedString]];
    } else {
        message = [NSString stringWithFormat:@"State: %@", [state capitalizedString]];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:friendlyName
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // Only add temperature controls if we have a target temperature
    if (targetTemp) {
        UIAlertAction *increaseTempAction = [UIAlertAction actionWithTitle:@"Increase Temperature (+1°)"
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction *action) {
            float newTemp = targetTemp.floatValue + 1.0;
            [self setClimateTemperature:newTemp forEntityId:entityId];
        }];
        
        UIAlertAction *decreaseTempAction = [UIAlertAction actionWithTitle:@"Decrease Temperature (-1°)"
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction *action) {
            float newTemp = targetTemp.floatValue - 1.0;
            [self setClimateTemperature:newTemp forEntityId:entityId];
        }];
        
        [alert addAction:increaseTempAction];
        [alert addAction:decreaseTempAction];
    }
    
    // Add on/off toggle if the device supports it
    if (![state isEqualToString:@"unavailable"]) {
        NSString *toggleTitle = [state isEqualToString:@"off"] ? @"Turn On" : @"Turn Off";
        UIAlertAction *toggleAction = [UIAlertAction actionWithTitle:toggleTitle
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
            if ([state isEqualToString:@"off"]) {
                [self.homeAssistantClient callService:@"climate" service:@"turn_on" entityId:entityId];
            } else {
                [self.homeAssistantClient callService:@"climate" service:@"turn_off" entityId:entityId];
            }
        }];
        [alert addAction:toggleAction];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showCoverControlForEntity:(NSDictionary *)entity {
    NSString *entityId = entity[@"entity_id"];
    NSString *friendlyName = entity[@"attributes"][@"friendly_name"] ?: entityId;
    NSString *state = entity[@"state"];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:friendlyName
                                                                   message:[NSString stringWithFormat:@"Current state: %@", state]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *openAction = [UIAlertAction actionWithTitle:@"Open"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
        [self.homeAssistantClient callService:@"cover" service:@"open_cover" entityId:entityId];
    }];
    
    UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"Close"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
        [self.homeAssistantClient callService:@"cover" service:@"close_cover" entityId:entityId];
    }];
    
    UIAlertAction *stopAction = [UIAlertAction actionWithTitle:@"Stop"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
        [self.homeAssistantClient callService:@"cover" service:@"stop_cover" entityId:entityId];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:openAction];
    [alert addAction:closeAction];
    [alert addAction:stopAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showLockControlForEntity:(NSDictionary *)entity {
    NSString *entityId = entity[@"entity_id"];
    NSString *friendlyName = entity[@"attributes"][@"friendly_name"] ?: entityId;
    NSString *state = entity[@"state"];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:friendlyName
                                                                   message:[NSString stringWithFormat:@"Current state: %@", state]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *lockAction = [UIAlertAction actionWithTitle:@"Lock"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
        [self.homeAssistantClient callService:@"lock" service:@"lock" entityId:entityId];
    }];
    
    UIAlertAction *unlockAction = [UIAlertAction actionWithTitle:@"Unlock"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
        [self.homeAssistantClient callService:@"lock" service:@"unlock" entityId:entityId];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:lockAction];
    [alert addAction:unlockAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)setClimateTemperature:(float)temperature forEntityId:(NSString *)entityId {
    [self.homeAssistantClient callClimateService:@"set_temperature" 
                                        entityId:entityId 
                                     temperature:temperature];
}

- (void)animateCardTap:(EntityCardCell *)cell {
    if (!cell) return;
    
    // Scale animation for visual feedback
    [UIView animateWithDuration:0.1 animations:^{
        cell.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            cell.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (void)showSensorInfoForEntity:(NSDictionary *)entity {
    NSString *entityId = entity[@"entity_id"];
    NSString *friendlyName = entity[@"attributes"][@"friendly_name"] ?: entityId;
    NSString *state = entity[@"state"];
    
    NSMutableString *message = [NSMutableString stringWithFormat:@"Current State: %@", state];
    
    // Add useful attributes for sensors
    NSDictionary *attributes = entity[@"attributes"];
    if (attributes) {
        NSString *unit = attributes[@"unit_of_measurement"];
        NSString *deviceClass = attributes[@"device_class"];
        NSString *lastChanged = entity[@"last_changed"];
        
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
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:friendlyName
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end