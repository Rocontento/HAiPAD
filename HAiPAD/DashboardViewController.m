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
#import "CustomPopupViewController.h"
#import "WhiteboardGridLayout.h"
#import "EmptyGridSlotView.h"

@interface DashboardViewController ()
@property (nonatomic, strong) NSArray *entities;
@property (nonatomic, strong) NSArray *allEntities;
@property (nonatomic, strong) NSSet *enabledEntityIds;
@property (nonatomic, strong) HomeAssistantClient *homeAssistantClient;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, assign) NSInteger columnCount;
@property (nonatomic, strong) WhiteboardGridLayout *whiteboardLayout;
@property (nonatomic, strong) NSMutableDictionary *entityPositions; // entity_id -> NSValue(CGPoint)
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
// Drag and drop properties
@property (nonatomic, assign) BOOL editingMode;
@property (nonatomic, strong) NSIndexPath *draggedIndexPath;
@property (nonatomic, strong) UIView *draggedCellSnapshot;
@property (nonatomic, assign) CGPoint draggedCellCenter;
@end

@implementation DashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Home Assistant";
    self.entities = @[];
    self.allEntities = @[];
    self.enabledEntityIds = [NSSet set];
    self.entityPositions = [NSMutableDictionary dictionary];
    self.homeAssistantClient = [HomeAssistantClient sharedClient];
    self.homeAssistantClient.delegate = self;

    // Set up whiteboard grid layout
    [self setupWhiteboardLayout];

    // Set up collection view
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];

    // Register empty slot supplementary view
    [self.collectionView registerClass:[EmptyGridSlotView class]
            forSupplementaryViewOfKind:@"EmptySlot"
                   withReuseIdentifier:@"EmptyGridSlotView"];

    // Add long press gesture for dragging cards - iOS 18 style with 0.8s duration
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPressGesture.minimumPressDuration = 0.8;
    [self.collectionView addGestureRecognizer:self.longPressGesture];

    // Register cell from storyboard
    // The cell will be registered automatically since it's defined in the storyboard

    // Load saved configuration
    [self loadConfiguration];

    // Load entity settings and positions
    [self loadEntitySettings];
    [self loadEntityPositions];

    // Set up refresh control for iOS 9.3.5 compatibility
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshButtonTapped:) forControlEvents:UIControlEventValueChanged];

    // Add refresh control to collection view
    [self.collectionView addSubview:self.refreshControl];
    [self.collectionView sendSubviewToBack:self.refreshControl];
    
    // Setup Done editing button - initially hidden
    [self setupDoneEditingButton];
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

- (void)loadConfiguration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *baseURL = [defaults stringForKey:@"ha_base_url"];
    NSString *accessToken = [defaults stringForKey:@"ha_access_token"];

    // Load column count preference (now used for grid columns)
    self.columnCount = [defaults integerForKey:@"ha_column_count"];
    if (self.columnCount == 0) {
        self.columnCount = 4; // Default to 4 columns for whiteboard
    }

    // Update grid layout
    self.whiteboardLayout.gridColumns = self.columnCount;

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

- (IBAction)doneEditingButtonTapped:(id)sender {
    [self setEditingMode:NO];
}

#pragma mark - Done Editing Button Setup

- (void)setupDoneEditingButton {
    if (self.doneEditingButton) {
        // Configure the button appearance
        [self.doneEditingButton setTitle:@"Done editing" forState:UIControlStateNormal];
        [self.doneEditingButton setTitleColor:[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] forState:UIControlStateNormal]; // iOS blue
        self.doneEditingButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        
        // Initially hidden
        self.doneEditingButton.hidden = YES;
        self.doneEditingButton.alpha = 0.0;
    }
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

    // Show custom popup for errors
    NSDictionary *errorEntity = @{
        @"entity_id": @"error",
        @"state": error.localizedDescription,
        @"attributes": @{
            @"friendly_name": @"Connection Error"
        }
    };

    CustomPopupViewController *popup = [CustomPopupViewController popupWithEntity:errorEntity
                                                                             type:CustomPopupTypeInfo
                                                                     actionHandler:nil];
    [popup presentFromViewController:self animated:YES];
}

- (void)homeAssistantClient:(HomeAssistantClient *)client didReceiveStateChange:(NSDictionary *)stateChange {
    // Handle individual state changes in real-time
    NSString *changedEntityId = stateChange[@"entity_id"];
    if (!changedEntityId) return;
    
    // Find the entity in our current list and update it
    NSMutableArray *mutableEntities = [self.entities mutableCopy];
    BOOL found = NO;
    
    for (NSInteger i = 0; i < mutableEntities.count; i++) {
        NSDictionary *entity = mutableEntities[i];
        NSString *entityId = entity[@"entity_id"];
        
        if ([entityId isEqualToString:changedEntityId]) {
            // Replace the entity with the updated state
            mutableEntities[i] = stateChange;
            found = YES;
            
            // Update the specific cell
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            
            if ([cell isKindOfClass:[EntityCardCell class]]) {
                EntityCardCell *entityCell = (EntityCardCell *)cell;
                [entityCell configureWithEntity:stateChange];
                
                // Add a subtle animation to indicate the update
                [self animateEntityUpdate:entityCell];
            }
            break;
        }
    }
    
    // Update the entities array if we found and updated the entity
    if (found) {
        self.entities = [mutableEntities copy];
    }
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
    
    // Configure edit mode for the cell
    [cell setEditModeEnabled:self.editingMode animated:NO];
    
    // Set resize delegate
    cell.resizeDelegate = self;

    return cell;
}

#pragma mark - UICollectionViewDataSource - Supplementary Views

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:@"EmptySlot"]) {
        EmptyGridSlotView *emptySlotView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                withReuseIdentifier:@"EmptyGridSlotView"
                                                                                       forIndexPath:indexPath];
        return emptySlotView;
    }

    return nil;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

    // Add visual feedback for the tap
    EntityCardCell *cell = (EntityCardCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self animateCardTap:cell];

    NSDictionary *entity = self.entities[indexPath.item];
    NSString *entityId = entity[@"entity_id"];
    NSString *state = entity[@"state"];

    // Handle tappable entities with optimistic UI updates
    if ([entityId hasPrefix:@"light."]) {
        NSString *newState = [state isEqualToString:@"on"] ? @"off" : @"on";
        [self updateEntityStateOptimistically:indexPath newState:newState];
        
        if ([state isEqualToString:@"on"]) {
            [self.homeAssistantClient callService:@"light" service:@"turn_off" entityId:entityId];
        } else {
            [self.homeAssistantClient callService:@"light" service:@"turn_on" entityId:entityId];
        }
    } else if ([entityId hasPrefix:@"switch."]) {
        NSString *newState = [state isEqualToString:@"on"] ? @"off" : @"on";
        [self updateEntityStateOptimistically:indexPath newState:newState];
        
        if ([state isEqualToString:@"on"]) {
            [self.homeAssistantClient callService:@"switch" service:@"turn_off" entityId:entityId];
        } else {
            [self.homeAssistantClient callService:@"switch" service:@"turn_on" entityId:entityId];
        }
    } else if ([entityId hasPrefix:@"fan."]) {
        NSString *newState = [state isEqualToString:@"on"] ? @"off" : @"on";
        [self updateEntityStateOptimistically:indexPath newState:newState];
        
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

#pragma mark - Whiteboard Grid Layout Setup and Management

- (void)setupWhiteboardLayout {
    self.whiteboardLayout = [[WhiteboardGridLayout alloc] init];
    self.whiteboardLayout.delegate = self;

    // Configure grid based on device
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.whiteboardLayout.gridColumns = 4;
        self.whiteboardLayout.gridRows = 6;
    } else {
        self.whiteboardLayout.gridColumns = 2;
        self.whiteboardLayout.gridRows = 8;
    }

    self.whiteboardLayout.cellSpacing = 12.0;
    self.whiteboardLayout.gridInsets = UIEdgeInsetsMake(16, 16, 16, 16);
    self.whiteboardLayout.showEmptySlots = NO; // Only show during editing
    self.whiteboardLayout.allowsReordering = YES;

    // Initialize editing mode
    self.editingMode = NO;

    // Apply the layout to collection view
    self.collectionView.collectionViewLayout = self.whiteboardLayout;
}

- (void)loadEntityPositions {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *savedPositions = [defaults dictionaryForKey:@"ha_entity_positions"];

    if (savedPositions) {
        self.entityPositions = [savedPositions mutableCopy];
    } else {
        self.entityPositions = [NSMutableDictionary dictionary];
    }
}

- (void)saveEntityPositions {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.entityPositions forKey:@"ha_entity_positions"];
    [defaults synchronize];
}

- (CGPoint)getGridPositionForEntity:(NSString *)entityId defaultPosition:(CGPoint)defaultPosition {
    NSString *positionString = self.entityPositions[entityId];
    if (positionString) {
        CGPoint position = CGPointFromString(positionString);
        return position;
    }

    // If no saved position, store the default position
    [self setGridPosition:defaultPosition forEntity:entityId];
    return defaultPosition;
}

- (void)setGridPosition:(CGPoint)position forEntity:(NSString *)entityId {
    NSString *positionString = NSStringFromCGPoint(position);
    self.entityPositions[entityId] = positionString;
    [self saveEntityPositions];
}

#pragma mark - WhiteboardGridLayoutDelegate

- (CGPoint)gridPositionForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < self.entities.count) {
        NSDictionary *entity = self.entities[indexPath.item];
        NSString *entityId = entity[@"entity_id"];

        // Calculate auto-placement position as fallback
        NSInteger autoRow = indexPath.item / self.whiteboardLayout.gridColumns;
        NSInteger autoCol = indexPath.item % self.whiteboardLayout.gridColumns;
        CGPoint autoPosition = CGPointMake(autoCol, autoRow);

        return [self getGridPositionForEntity:entityId defaultPosition:autoPosition];
    }

    return CGPointMake(0, 0);
}

- (CGSize)gridSizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // All cards are 1x1 for now, but this allows for future expansion
    return CGSizeMake(1, 1);
}

- (void)didMoveItemAtIndexPath:(NSIndexPath *)indexPath toGridPosition:(CGPoint)gridPosition {
    if (indexPath.item < self.entities.count) {
        NSDictionary *entity = self.entities[indexPath.item];
        NSString *entityId = entity[@"entity_id"];
        [self setGridPosition:gridPosition forEntity:entityId];
    }
}

#pragma mark - Drag and Drop Handling

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            if (indexPath) {
                [self beginDragForItemAtIndexPath:indexPath atLocation:location];
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            [self updateDragAtLocation:location];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            [self endDragAtLocation:location];
            break;
        }
        default:
            break;
    }
}

- (void)beginDragForItemAtIndexPath:(NSIndexPath *)indexPath atLocation:(CGPoint)location {
    // Enter editing mode
    [self setEditingMode:YES];

    // Store the dragged item
    self.draggedIndexPath = indexPath;

    // Get the cell being dragged
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if (!cell) return;

    // Create a snapshot of the cell
    UIView *cellSnapshot = [self snapshotViewFromCell:cell];
    self.draggedCellSnapshot = cellSnapshot;

    // Add snapshot to collection view
    [self.collectionView addSubview:cellSnapshot];

    // Position the snapshot at the cell's current location
    cellSnapshot.center = cell.center;
    self.draggedCellCenter = cell.center;

    // Hide the original cell
    cell.hidden = YES;

    // Animate the snapshot to indicate dragging
    [UIView animateWithDuration:0.2 animations:^{
        cellSnapshot.transform = CGAffineTransformMakeScale(1.05, 1.05);
        cellSnapshot.alpha = 0.9;
    }];
}

- (void)updateDragAtLocation:(CGPoint)location {
    if (!self.draggedCellSnapshot) return;

    // Move the snapshot to follow the finger
    self.draggedCellSnapshot.center = location;

    // Calculate target grid position and provide visual feedback
    CGPoint gridPosition = [self.whiteboardLayout gridPositionFromPoint:location];

    // Optional: Add highlighting for target position
    // This could be implemented by updating empty slot views to show as highlighted
}

- (void)endDragAtLocation:(CGPoint)location {
    if (!self.draggedIndexPath || !self.draggedCellSnapshot) {
        [self setEditingMode:NO];
        return;
    }

    // Calculate the target grid position
    CGPoint newGridPosition = [self.whiteboardLayout gridPositionFromPoint:location];

    // Get the original cell
    UICollectionViewCell *originalCell = [self.collectionView cellForItemAtIndexPath:self.draggedIndexPath];

    // Check if the new position is valid
    BOOL positionIsValid = [self.whiteboardLayout isGridPositionValid:newGridPosition withSize:CGSizeMake(1, 1)];

    if (positionIsValid) {
        // Update the entity position
        [self didMoveItemAtIndexPath:self.draggedIndexPath toGridPosition:newGridPosition];

        // Animate to the new position
        CGRect targetFrame = [self.whiteboardLayout frameForGridPosition:newGridPosition size:CGSizeMake(1, 1)];

        [UIView animateWithDuration:0.3 animations:^{
            self.draggedCellSnapshot.center = CGPointMake(CGRectGetMidX(targetFrame), CGRectGetMidY(targetFrame));
            self.draggedCellSnapshot.transform = CGAffineTransformIdentity;
            self.draggedCellSnapshot.alpha = 1.0;
        } completion:^(BOOL finished) {
            // Reload the layout to apply the new position
            [self.collectionView.collectionViewLayout invalidateLayout];
            [self.collectionView layoutIfNeeded];

            // Clean up
            [self cleanupDragOperation];
        }];
    } else {
        // Invalid position - animate back to original position
        [UIView animateWithDuration:0.3 animations:^{
            self.draggedCellSnapshot.center = self.draggedCellCenter;
            self.draggedCellSnapshot.transform = CGAffineTransformIdentity;
            self.draggedCellSnapshot.alpha = 1.0;
        } completion:^(BOOL finished) {
            [self cleanupDragOperation];
        }];
    }
}

- (UIView *)snapshotViewFromCell:(UICollectionViewCell *)cell {
    // Create a snapshot image of the cell
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0.0);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *cellImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Create a view with the snapshot image
    UIImageView *snapshotView = [[UIImageView alloc] initWithImage:cellImage];
    snapshotView.frame = cell.frame;

    // Add shadow for better visual feedback
    snapshotView.layer.shadowColor = [UIColor blackColor].CGColor;
    snapshotView.layer.shadowOffset = CGSizeMake(0, 5);
    snapshotView.layer.shadowOpacity = 0.3;
    snapshotView.layer.shadowRadius = 10;

    return snapshotView;
}

- (void)cleanupDragOperation {
    // Show the original cell
    if (self.draggedIndexPath) {
        UICollectionViewCell *originalCell = [self.collectionView cellForItemAtIndexPath:self.draggedIndexPath];
        originalCell.hidden = NO;
    }

    // Remove the snapshot
    [self.draggedCellSnapshot removeFromSuperview];

    // Clear drag state
    self.draggedIndexPath = nil;
    self.draggedCellSnapshot = nil;

    // Exit editing mode
    [self setEditingMode:NO];
}

- (void)setEditingMode:(BOOL)editingMode {
    if (_editingMode == editingMode) return;

    _editingMode = editingMode;

    // Update empty slots visibility based on editing mode
    self.whiteboardLayout.showEmptySlots = editingMode;

    // Invalidate layout to show/hide empty slots
    [self.collectionView.collectionViewLayout invalidateLayout];

    // Show/hide Done editing button with animation
    if (editingMode) {
        // Entering edit mode
        self.doneEditingButton.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.doneEditingButton.alpha = 1.0;
        }];
        
        // Add blue flash animation to indicate edit mode entry
        [self addBlueFlashAnimation];
    } else {
        // Exiting edit mode
        [UIView animateWithDuration:0.3 animations:^{
            self.doneEditingButton.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.doneEditingButton.hidden = YES;
        }];
    }
    
    // Update all visible cells to show/hide resize handles
    [self updateCellsEditMode:editingMode];
}

- (void)updateCellsEditMode:(BOOL)editingMode {
    NSArray *visibleIndexPaths = [self.collectionView indexPathsForVisibleItems];
    
    for (NSIndexPath *indexPath in visibleIndexPaths) {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        if ([cell isKindOfClass:[EntityCardCell class]]) {
            EntityCardCell *entityCell = (EntityCardCell *)cell;
            [entityCell setEditModeEnabled:editingMode animated:YES];
        }
    }
}

#pragma mark - Edit Mode Visual Feedback

- (void)addBlueFlashAnimation {
    // Create a blue overlay for the flash animation
    UIView *flashOverlay = [[UIView alloc] initWithFrame:self.collectionView.bounds];
    flashOverlay.backgroundColor = [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:0.3]; // iOS blue with transparency
    flashOverlay.alpha = 0.0;
    
    [self.collectionView addSubview:flashOverlay];
    
    // Animate the flash
    [UIView animateWithDuration:0.2 animations:^{
        flashOverlay.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            flashOverlay.alpha = 0.0;
        } completion:^(BOOL finished) {
            [flashOverlay removeFromSuperview];
        }];
    }];
}

#pragma mark - Action Methods

- (void)infoButtonTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < self.entities.count) {
        NSDictionary *entity = self.entities[index];
        
        // Add debugging to see what entity data we have
        NSLog(@"Info button tapped for entity: %@", entity);
        
        CustomPopupViewController *popup = [CustomPopupViewController popupWithEntity:entity
                                                                                 type:CustomPopupTypeInfo
                                                                         actionHandler:nil];
        [popup presentFromViewController:self animated:YES];
    } else {
        NSLog(@"Info button tapped with invalid index: %ld (total entities: %lu)", (long)index, (unsigned long)self.entities.count);
    }
}

#pragma mark - Entity Control Methods

- (void)showClimateControlForEntity:(NSDictionary *)entity {
    CustomPopupViewController *popup = [CustomPopupViewController popupWithEntity:entity
                                                                             type:CustomPopupTypeClimateControl
                                                                     actionHandler:^(NSString *action, NSDictionary *parameters) {
        NSString *entityId = entity[@"entity_id"];
        NSString *state = entity[@"state"];

        if ([action isEqualToString:@"increase_temp"] || [action isEqualToString:@"decrease_temp"]) {
            NSNumber *temperature = parameters[@"temperature"];
            if (temperature) {
                [self setClimateTemperature:temperature.floatValue forEntityId:entityId];
            }
        } else if ([action isEqualToString:@"toggle"]) {
            if ([state isEqualToString:@"off"]) {
                [self.homeAssistantClient callService:@"climate" service:@"turn_on" entityId:entityId];
            } else {
                [self.homeAssistantClient callService:@"climate" service:@"turn_off" entityId:entityId];
            }
        }
    }];
    [popup presentFromViewController:self animated:YES];
}

- (void)showCoverControlForEntity:(NSDictionary *)entity {
    CustomPopupViewController *popup = [CustomPopupViewController popupWithEntity:entity
                                                                             type:CustomPopupTypeCoverControl
                                                                     actionHandler:^(NSString *action, NSDictionary *parameters) {
        NSString *entityId = entity[@"entity_id"];

        if ([action isEqualToString:@"open"]) {
            [self.homeAssistantClient callService:@"cover" service:@"open_cover" entityId:entityId];
        } else if ([action isEqualToString:@"close"]) {
            [self.homeAssistantClient callService:@"cover" service:@"close_cover" entityId:entityId];
        } else if ([action isEqualToString:@"stop"]) {
            [self.homeAssistantClient callService:@"cover" service:@"stop_cover" entityId:entityId];
        }
    }];
    [popup presentFromViewController:self animated:YES];
}

- (void)showLockControlForEntity:(NSDictionary *)entity {
    CustomPopupViewController *popup = [CustomPopupViewController popupWithEntity:entity
                                                                             type:CustomPopupTypeLockControl
                                                                     actionHandler:^(NSString *action, NSDictionary *parameters) {
        NSString *entityId = entity[@"entity_id"];

        if ([action isEqualToString:@"lock"]) {
            [self.homeAssistantClient callService:@"lock" service:@"lock" entityId:entityId];
        } else if ([action isEqualToString:@"unlock"]) {
            [self.homeAssistantClient callService:@"lock" service:@"unlock" entityId:entityId];
        }
    }];
    [popup presentFromViewController:self animated:YES];
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
    // Add debugging to see what entity data we have
    NSLog(@"Showing sensor info for entity: %@", entity);
    
    CustomPopupViewController *popup = [CustomPopupViewController popupWithEntity:entity
                                                                             type:CustomPopupTypeSensorInfo
                                                                     actionHandler:nil];
    [popup presentFromViewController:self animated:YES];
}

- (void)animateEntityUpdate:(EntityCardCell *)cell {
    if (!cell) return;
    
    // Subtle pulse animation to indicate real-time update
    [UIView animateWithDuration:0.15 animations:^{
        cell.transform = CGAffineTransformMakeScale(1.02, 1.02);
        cell.alpha = 0.8;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            cell.transform = CGAffineTransformIdentity;
            cell.alpha = 1.0;
        }];
    }];
}

- (void)updateEntityStateOptimistically:(NSIndexPath *)indexPath newState:(NSString *)newState {
    if (indexPath.item >= self.entities.count) return;
    
    // Create a mutable copy of the entity with the new state
    NSMutableDictionary *updatedEntity = [self.entities[indexPath.item] mutableCopy];
    updatedEntity[@"state"] = newState;
    
    // Update the entities array
    NSMutableArray *mutableEntities = [self.entities mutableCopy];
    mutableEntities[indexPath.item] = [updatedEntity copy];
    self.entities = [mutableEntities copy];
    
    // Update the cell immediately for instant feedback
    EntityCardCell *cell = (EntityCardCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:[EntityCardCell class]]) {
        [cell configureWithEntity:updatedEntity];
        [self animateEntityUpdate:cell];
    }
}

#pragma mark - EntityCardCellResizeDelegate

- (void)entityCardCell:(EntityCardCell *)cell didBeginResizeWithGesture:(UIPanGestureRecognizer *)gesture {
    // TODO: Implement resize begin handling - could show grid overlay or visual feedback
    NSLog(@"Begin resize for cell");
}

- (void)entityCardCell:(EntityCardCell *)cell didChangeResizeWithGesture:(UIPanGestureRecognizer *)gesture {
    // TODO: Implement actual resizing with grid snapping
    CGPoint translation = [gesture translationInView:self.collectionView];
    NSLog(@"Resize translation: %@", NSStringFromCGPoint(translation));
    
    // For now, we'll implement a basic resize that doesn't affect the grid layout
    // In a full implementation, this would modify the grid size and update the layout
}

- (void)entityCardCell:(EntityCardCell *)cell didEndResizeWithGesture:(UIPanGestureRecognizer *)gesture {
    // TODO: Implement resize end handling - finalize new size and update layout
    NSLog(@"End resize for cell");
}

@end