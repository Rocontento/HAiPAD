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
#import "EntitySelectionViewController.h"

@interface DashboardViewController () <EntityCardCellDelegate, EmptyGridSlotViewDelegate, EntitySelectionViewControllerDelegate>
@property (nonatomic, strong) NSArray *entities;
@property (nonatomic, strong) NSArray *allEntities;
@property (nonatomic, strong) NSSet *enabledEntityIds;
@property (nonatomic, strong) HomeAssistantClient *homeAssistantClient;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) WhiteboardGridLayout *whiteboardLayout;
@property (nonatomic, strong) NSMutableDictionary *entityPositions; // entity_id -> NSValue(CGPoint)
@property (nonatomic, strong) NSMutableDictionary *entitySizes; // entity_id -> NSValue(CGSize)
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
// Drag and drop properties
@property (nonatomic, assign) BOOL editingMode;
@property (nonatomic, assign) BOOL hasPendingReload; // Flag to track if reload is needed after editing
@property (nonatomic, strong) NSIndexPath *draggedIndexPath;
@property (nonatomic, strong) UIView *draggedCellSnapshot;
@property (nonatomic, assign) CGPoint draggedCellCenter;
// Navigation bar toggle properties
@property (nonatomic, assign) BOOL navigationBarHidden;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) NSLayoutConstraint *collectionViewTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *navigationBarHeightConstraint;
// Customization properties
@property (nonatomic, strong) UIColor *dashboardBackgroundColor;
@property (nonatomic, strong) UIColor *navbarColor;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, assign) NSInteger backgroundType; // 0 = color, 1 = image
@end

@implementation DashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Home Assistant";
    self.entities = @[];
    self.allEntities = @[];
    self.enabledEntityIds = [NSSet set];
    self.entityPositions = [NSMutableDictionary dictionary];
    self.entitySizes = [NSMutableDictionary dictionary];
    self.homeAssistantClient = [HomeAssistantClient sharedClient];
    self.homeAssistantClient.delegate = self;


    // Initialize drag and drop state
    self.hasPendingReload = NO;

    // Initialize navigation bar state - hidden by default
    self.navigationBarHidden = YES;


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

    // Add long press gesture for dragging cards
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPressGesture.minimumPressDuration = 0.5;
    [self.collectionView addGestureRecognizer:self.longPressGesture];

    // Register cell from storyboard
    // The cell will be registered automatically since it's defined in the storyboard

    // Style navigation buttons with borders
    [self styleNavigationButtons];

    // Set up navigation bar toggle functionality
    [self setupNavigationBarToggle];
    
    // Initialize navigation bar to hidden state
    [self initializeNavigationBarState];

    // Load saved configuration
    [self loadConfiguration];

    // Load entity settings and positions
    [self loadEntitySettings];
    [self loadEntityPositions];
    [self loadEntitySizes];
    
    // Load and apply customization settings
    [self loadCustomizationSettings];
    [self applyCustomizationSettings];

    // Set up refresh control for iOS 9.3.5 compatibility
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshButtonTapped:) forControlEvents:UIControlEventValueChanged];

    // Add refresh control to collection view
    [self.collectionView addSubview:self.refreshControl];
    [self.collectionView sendSubviewToBack:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Ensure we are the delegate for HomeAssistantClient when this view appears
    self.homeAssistantClient.delegate = self;

    // Reload entity settings in case they changed
    [self loadEntitySettings];

    // Reload configuration in case column count changed
    [self loadConfiguration];

    // Reload layout to apply any column changes
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    // Reload and apply customization settings in case they changed
    [self loadCustomizationSettings];
    [self applyCustomizationSettings];

    if (self.homeAssistantClient.isConnected) {
        // Update status label immediately if already connected
        self.statusLabel.text = @"Connected";
        self.statusLabel.textColor = [UIColor greenColor];
        
        [self.homeAssistantClient fetchStates];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Reapply background image after layout to ensure proper scaling
    if (self.backgroundType == 1 && self.backgroundImage) {
        [self applyBackgroundImage];
    }
}

- (void)loadConfiguration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *baseURL = [defaults stringForKey:@"ha_base_url"];
    NSString *accessToken = [defaults stringForKey:@"ha_access_token"];

    // Load independent grid preferences with backward compatibility
    NSInteger gridColumns = [defaults integerForKey:@"ha_grid_columns"];
    NSInteger gridRows = [defaults integerForKey:@"ha_grid_rows"];
    
    // If new format doesn't exist, fall back to legacy grid size
    if (gridColumns == 0 && gridRows == 0) {
        NSInteger gridSize = [defaults integerForKey:@"ha_grid_size"];
        if (gridSize == 0) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                gridColumns = 6; // Default 6 columns for iPad
                gridRows = 8;    // Default 8 rows for iPad
            } else {
                gridColumns = 4; // Default 4 columns for iPhone
                gridRows = 6;    // Default 6 rows for iPhone
            }
        } else {
            // Legacy format - use the same value for both dimensions
            gridColumns = gridSize;
            gridRows = gridSize;
        }
    } else {
        // Use the new independent values, but provide defaults if only one is set
        if (gridColumns == 0) {
            gridColumns = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 6 : 4;
        }
        if (gridRows == 0) {
            gridRows = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 8 : 6;
        }
    }

    // Update grid layout with independent dimensions
    self.whiteboardLayout.gridColumns = gridColumns;
    self.whiteboardLayout.gridRows = gridRows;

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

#pragma mark - Customization Settings

- (void)loadCustomizationSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Load background color (default to white)
    NSData *colorData = [defaults objectForKey:@"ha_dashboard_background_color"];
    if (colorData) {
        self.dashboardBackgroundColor = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    } else {
        self.dashboardBackgroundColor = [UIColor whiteColor];
    }
    
    // Load navbar color (default to light gray)
    NSData *navbarColorData = [defaults objectForKey:@"ha_navbar_color"];
    if (navbarColorData) {
        self.navbarColor = [NSKeyedUnarchiver unarchiveObjectWithData:navbarColorData];
    } else {
        self.navbarColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    }
    
    // Load background type (default to color)
    self.backgroundType = [defaults integerForKey:@"ha_background_type"];
    
    // Load background image if exists
    NSData *imageData = [defaults objectForKey:@"ha_background_image"];
    if (imageData) {
        self.backgroundImage = [UIImage imageWithData:imageData];
    }
}

- (void)applyCustomizationSettings {
    // Apply background based on type
    if (self.backgroundType == 1 && self.backgroundImage) {
        // Apply background image
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:self.backgroundImage];
        backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        backgroundImageView.clipsToBounds = YES;
        self.view.backgroundColor = [UIColor clearColor];
        
        // Insert background image view behind all other views
        [self.view insertSubview:backgroundImageView atIndex:0];
        
        // Set constraints to fill the view
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [backgroundImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [backgroundImageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
            [backgroundImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [backgroundImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
        ]];
    } else {
        // Apply background color
        self.view.backgroundColor = self.dashboardBackgroundColor;
    }
    
    // Apply navbar color
    if (self.navigationBarView) {
        self.navigationBarView.backgroundColor = self.navbarColor;
    }
}

#pragma mark - Navigation Bar Styling and Toggle

- (void)styleNavigationButtons {
    NSArray *buttons = @[self.configButton, self.refreshButton, self.entitiesButton, self.editButton];
    
    for (UIButton *button in buttons) {
        // Add border
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = [UIColor colorWithWhite:0.7 alpha:1.0].CGColor;
        button.layer.cornerRadius = 6.0;
        
        // Add background color for better contrast
        button.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];
        
        // Add some padding
        button.contentEdgeInsets = UIEdgeInsetsMake(6, 10, 6, 10);
        
        // Add subtle shadow
        button.layer.shadowColor = [UIColor blackColor].CGColor;
        button.layer.shadowOffset = CGSizeMake(0, 1);
        button.layer.shadowOpacity = 0.1;
        button.layer.shadowRadius = 1.0;
        
        // Set text color
        [button setTitleColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0] forState:UIControlStateHighlighted];
    }
    
    // Update entities button text to "Settings"
    [self.entitiesButton setTitle:@"Settings" forState:UIControlStateNormal];
}

- (void)setupNavigationBarToggle {
    // Create a small toggle button that will remain visible when nav bar is hidden
    self.toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.toggleButton setTitle:@"☰" forState:UIControlStateNormal]; // Menu icon
    self.toggleButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [self.toggleButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    self.toggleButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.9];
    self.toggleButton.layer.cornerRadius = 15;
    self.toggleButton.layer.borderWidth = 1.0;
    self.toggleButton.layer.borderColor = [UIColor colorWithWhite:0.7 alpha:1.0].CGColor;
    
    [self.toggleButton addTarget:self action:@selector(toggleNavigationBarTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // Add toggle button to main view
    self.toggleButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.toggleButton];
    
    // Position toggle button in the top-right corner (iOS 9.3.5 compatible)
    [NSLayoutConstraint activateConstraints:@[
        [self.toggleButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:28], // Below status bar
        [self.toggleButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.toggleButton.widthAnchor constraintEqualToConstant:30],
        [self.toggleButton.heightAnchor constraintEqualToConstant:30]
    ]];
    
    // Initially show the toggle button since nav bar is hidden by default
    self.toggleButton.hidden = NO;
    
    // Add double-tap gesture to collection view to show nav bar when hidden
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.collectionView addGestureRecognizer:doubleTap];
    
    // Add swipe up gesture to navigation bar to hide it
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.navigationBarView addGestureRecognizer:swipeUp];
    
    // Find and store the navigation bar height constraint and collection view top constraint
    for (NSLayoutConstraint *constraint in self.view.constraints) {
        if (constraint.firstItem == self.collectionView && 
            constraint.firstAttribute == NSLayoutAttributeTop &&
            constraint.secondItem == self.navigationBarView) {
            self.collectionViewTopConstraint = constraint;
        }
    }
    
    // Find the navigation bar height constraint
    for (NSLayoutConstraint *constraint in self.navigationBarView.constraints) {
        if (constraint.firstAttribute == NSLayoutAttributeHeight) {
            self.navigationBarHeightConstraint = constraint;
            break;
        }
    }
}

- (void)initializeNavigationBarState {
    // Set initial visual state based on navigationBarHidden property
    if (self.navigationBarHidden) {
        // Hide navigation bar immediately without animation
        if (self.navigationBarHeightConstraint) {
            self.navigationBarHeightConstraint.constant = 0;
        }
        self.navigationBarView.alpha = 0.0;
        self.toggleButton.hidden = NO;
        self.toggleButton.alpha = 1.0;
    } else {
        // Show navigation bar
        if (self.navigationBarHeightConstraint) {
            self.navigationBarHeightConstraint.constant = 60;
        }
        self.navigationBarView.alpha = 1.0;
        self.toggleButton.hidden = YES;
        self.toggleButton.alpha = 0.0;
    }
    
    // Apply layout changes immediately
    [self.view layoutIfNeeded];
}

- (IBAction)toggleNavigationBarTapped:(id)sender {
    self.navigationBarHidden = !self.navigationBarHidden;
    
    [UIView animateWithDuration:0.3 animations:^{
        if (self.navigationBarHidden) {
            // Hide navigation bar by setting its height to 0
            if (self.navigationBarHeightConstraint) {
                self.navigationBarHeightConstraint.constant = 0;
            }
            
            // Fade out the navigation bar content
            self.navigationBarView.alpha = 0.0;
            
            // Show toggle button
            self.toggleButton.hidden = NO;
            self.toggleButton.alpha = 1.0;
        } else {
            // Show navigation bar by restoring its height
            if (self.navigationBarHeightConstraint) {
                self.navigationBarHeightConstraint.constant = 60;
            }
            
            // Fade in the navigation bar content
            self.navigationBarView.alpha = 1.0;
            
            // Hide toggle button
            self.toggleButton.alpha = 0.0;
        }
        
        // Force layout update during animation
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (!self.navigationBarHidden) {
            self.toggleButton.hidden = YES;
        }
    }];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture {
    // Only respond to double-tap when navigation bar is hidden
    if (self.navigationBarHidden) {
        [self toggleNavigationBarTapped:nil];
    }
}

- (void)handleSwipeUp:(UISwipeGestureRecognizer *)gesture {
    // Only respond to swipe up when navigation bar is visible
    if (!self.navigationBarHidden) {
        [self toggleNavigationBarTapped:nil];
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

- (IBAction)editButtonTapped:(id)sender {
    [self setEditingMode:!self.editingMode];
    
    // Update button title
    NSString *buttonTitle = self.editingMode ? @"Done" : @"Edit";
    [self.editButton setTitle:buttonTitle forState:UIControlStateNormal];
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

    // Avoid reloading data during drag operations to prevent visual glitches
    if (!self.editingMode) {
        [self.collectionView reloadData];
    } else {
        self.hasPendingReload = YES; // Mark that reload is needed
    }
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
    // Avoid reloading data during drag operations to prevent visual glitches
    if (!self.editingMode) {
        [self.collectionView reloadData];
    } else {
        self.hasPendingReload = YES; // Mark that reload is needed
    }
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
    
    // Set up cell delegate and properties
    cell.delegate = self;
    NSString *entityId = entity[@"entity_id"];
    cell.gridSize = [self getGridSizeForEntity:entityId defaultSize:CGSizeMake(1, 1)];
    [cell setEditingMode:self.editingMode animated:NO];

    // Add target for info button
    [cell.infoButton addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    cell.infoButton.tag = indexPath.item;

    return cell;
}

#pragma mark - UICollectionViewDataSource - Supplementary Views

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:@"EmptySlot"]) {
        EmptyGridSlotView *emptySlotView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                withReuseIdentifier:@"EmptyGridSlotView"
                                                                                       forIndexPath:indexPath];
        
        // Set delegate and get grid position from layout
        emptySlotView.delegate = self;
        emptySlotView.gridPosition = [self.whiteboardLayout gridPositionForEmptySlotAtIndexPath:indexPath];
        
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

    // Load configuration for grid size (independent dimensions)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Load independent grid preferences first
    NSInteger gridColumns = [defaults integerForKey:@"ha_grid_columns"];
    NSInteger gridRows = [defaults integerForKey:@"ha_grid_rows"];
    
    // If new format doesn't exist, fall back to legacy grid size
    if (gridColumns == 0 && gridRows == 0) {
        NSInteger gridSize = [defaults integerForKey:@"ha_grid_size"];
        if (gridSize == 0) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                gridColumns = 6; // Default 6 columns for iPad
                gridRows = 8;    // Default 8 rows for iPad
            } else {
                gridColumns = 4; // Default 4 columns for iPhone
                gridRows = 6;    // Default 6 rows for iPhone
            }
        } else {
            // Legacy format - use the same value for both dimensions
            gridColumns = gridSize;
            gridRows = gridSize;
        }
    } else {
        // Use the new independent values, but provide defaults if only one is set
        if (gridColumns == 0) {
            gridColumns = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 6 : 4;
        }
        if (gridRows == 0) {
            gridRows = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 8 : 6;
        }
    }

    self.whiteboardLayout.gridColumns = gridColumns;
    self.whiteboardLayout.gridRows = gridRows;
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

- (void)loadEntitySizes {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *savedSizes = [defaults dictionaryForKey:@"ha_entity_sizes"];

    if (savedSizes) {
        self.entitySizes = [savedSizes mutableCopy];
    } else {
        self.entitySizes = [NSMutableDictionary dictionary];
    }
}

- (void)saveEntityPositions {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.entityPositions forKey:@"ha_entity_positions"];
    [defaults synchronize];
}

- (void)saveEntitySizes {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.entitySizes forKey:@"ha_entity_sizes"];
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

- (CGSize)getGridSizeForEntity:(NSString *)entityId defaultSize:(CGSize)defaultSize {
    NSString *sizeString = self.entitySizes[entityId];
    if (sizeString) {
        CGSize size = CGSizeFromString(sizeString);
        return size;
    }

    // If no saved size, store the default size
    [self setGridSize:defaultSize forEntity:entityId];
    return defaultSize;
}

- (void)setGridSize:(CGSize)size forEntity:(NSString *)entityId {
    NSString *sizeString = NSStringFromCGSize(size);
    self.entitySizes[entityId] = sizeString;
    [self saveEntitySizes];
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
    if (indexPath.item < self.entities.count) {
        NSDictionary *entity = self.entities[indexPath.item];
        NSString *entityId = entity[@"entity_id"];
        
        return [self getGridSizeForEntity:entityId defaultSize:CGSizeMake(1, 1)];
    }
    
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

    // Show grid overlay for better visual feedback
    [self.whiteboardLayout showGridOverlayInView:self.collectionView];

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

    // Get the actual size of the card being dragged
    CGSize cardSize = [self gridSizeForItemAtIndexPath:self.draggedIndexPath];
    
    // Calculate target grid position considering the card size
    CGPoint gridPosition = [self.whiteboardLayout gridPositionFromPoint:location forCardSize:cardSize];
    
    // Show visual feedback for the target area
    if ([self.whiteboardLayout respondsToSelector:@selector(highlightGridCells:size:)]) {
        [self.whiteboardLayout highlightGridCells:gridPosition size:cardSize];
    }
}

- (void)endDragAtLocation:(CGPoint)location {
    if (!self.draggedIndexPath || !self.draggedCellSnapshot) {
        [self setEditingMode:NO];
        return;
    }

    // Get the actual size of the card being dragged
    CGSize cardSize = [self gridSizeForItemAtIndexPath:self.draggedIndexPath];

    // Calculate the target grid position considering the card size
    CGPoint newGridPosition = [self.whiteboardLayout gridPositionFromPoint:location forCardSize:cardSize];

    // Get the original cell
    UICollectionViewCell *originalCell = [self.collectionView cellForItemAtIndexPath:self.draggedIndexPath];

    // Check if the new position is valid for the actual card size
    BOOL positionIsValid = [self.whiteboardLayout isGridPositionValid:newGridPosition withSize:cardSize excludingIndexPath:self.draggedIndexPath];

    if (positionIsValid) {
        // Update the entity position
        [self didMoveItemAtIndexPath:self.draggedIndexPath toGridPosition:newGridPosition];

        // Animate to the new position using the actual card size
        CGRect targetFrame = [self.whiteboardLayout frameForGridPosition:newGridPosition size:cardSize];

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
    // Hide grid overlay
    [self.whiteboardLayout hideGridOverlay];
    
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

    // Prevent auto-refresh during drag operations to avoid visual glitches
    if (editingMode) {
        [self.homeAssistantClient stopAutoRefresh];
        self.hasPendingReload = NO; // Reset pending reload flag
    } else {
        [self.homeAssistantClient startAutoRefresh];
        // If there was a pending reload, execute it now
        if (self.hasPendingReload) {
            self.hasPendingReload = NO;
            [self.collectionView reloadData];
        }
    }

    // Update empty slots visibility based on editing mode
    self.whiteboardLayout.showEmptySlots = editingMode;

    // Invalidate layout to show/hide empty slots
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    // Update all visible cells
    for (NSIndexPath *indexPath in [self.collectionView indexPathsForVisibleItems]) {
        EntityCardCell *cell = (EntityCardCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if ([cell isKindOfClass:[EntityCardCell class]]) {
            [cell setEditingMode:editingMode animated:YES];
        }
    }

    // Optional: Add visual feedback for editing mode
    // Could change collection view background color slightly, etc.
}

#pragma mark - EntityCardCellDelegate

- (void)entityCardCell:(EntityCardCell *)cell didRequestSizeChange:(CGSize)newSize {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (!indexPath || indexPath.item >= self.entities.count) return;
    
    NSDictionary *entity = self.entities[indexPath.item];
    NSString *entityId = entity[@"entity_id"];
    
    // Save the new size
    [self setGridSize:newSize forEntity:entityId];
    
    // Update the layout
    [self.whiteboardLayout invalidateLayout];
    [self.collectionView layoutIfNeeded];
}

- (void)entityCardCell:(EntityCardCell *)cell didBeginResizing:(UIGestureRecognizer *)gesture {
    // Enter editing mode if not already
    if (!self.editingMode) {
        [self setEditingMode:YES];
    }
    
    // Show grid overlay for visual feedback
    [self.whiteboardLayout showGridOverlayInView:self.collectionView];
    
    // Find the index path for this cell to get its position
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath) {
        NSDictionary *entity = self.entities[indexPath.item];
        NSString *entityId = entity[@"entity_id"];
        CGPoint gridPosition = [self getGridPositionForEntity:entityId defaultPosition:CGPointMake(0, 0)];
        [self.whiteboardLayout highlightGridCells:gridPosition size:cell.gridSize];
    }
}

- (void)entityCardCell:(EntityCardCell *)cell didUpdateResizing:(UIGestureRecognizer *)gesture {
    // Update layout during resizing for real-time feedback
    [self.whiteboardLayout invalidateLayout];
    
    // Update the grid highlight to show new size
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath) {
        NSDictionary *entity = self.entities[indexPath.item];
        NSString *entityId = entity[@"entity_id"];
        CGPoint gridPosition = [self getGridPositionForEntity:entityId defaultPosition:CGPointMake(0, 0)];
        [self.whiteboardLayout highlightGridCells:gridPosition size:cell.gridSize];
    }
}

- (void)entityCardCell:(EntityCardCell *)cell didEndResizing:(UIGestureRecognizer *)gesture {
    // Hide grid overlay
    [self.whiteboardLayout hideGridOverlay];
    
    // Final layout update
    [self.whiteboardLayout invalidateLayout];
    [self.collectionView layoutIfNeeded];
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


#pragma mark - EmptyGridSlotViewDelegate

- (void)emptyGridSlotViewWasTapped:(EmptyGridSlotView *)slotView atGridPosition:(CGPoint)gridPosition {
    // Only respond to taps when in editing mode
    if (!self.editingMode) {
        return;
    }
    
    // Create entity selection controller with all available entities
    EntitySelectionViewController *entitySelection = [EntitySelectionViewController controllerWithEntities:self.allEntities 
                                                                                           targetGridPosition:gridPosition];
    entitySelection.delegate = self;
    
    // Present modally
    entitySelection.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    entitySelection.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:entitySelection animated:YES completion:nil];
}

#pragma mark - EntitySelectionViewControllerDelegate

- (void)entitySelectionViewController:(EntitySelectionViewController *)controller 
                     didSelectEntity:(NSDictionary *)entity 
                      forGridPosition:(CGPoint)gridPosition {
    
    // Dismiss the selection controller first
    [controller dismissViewControllerAnimated:YES completion:^{
        // Add the entity to our enabled entities if it's not already there
        NSString *entityId = entity[@"entity_id"];
        if (![self.enabledEntityIds containsObject:entityId]) {
            NSMutableSet *mutableEnabledEntities = [self.enabledEntityIds mutableCopy];
            [mutableEnabledEntities addObject:entityId];
            self.enabledEntityIds = [mutableEnabledEntities copy];
            
            // Save the updated enabled entities
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[self.enabledEntityIds allObjects] forKey:@"ha_enabled_entities"];
            [defaults synchronize];
        }
        
        // Set the position for this entity
        [self setGridPosition:gridPosition forEntity:entityId];
        
        // Refresh the filtered entities and reload the collection view
        [self filterEntitiesBasedOnSettings];
        
        // Exit editing mode
        [self setEditingMode:NO];
        [self.editButton setTitle:@"Edit" forState:UIControlStateNormal];
    }];
}

- (void)entitySelectionViewControllerDidCancel:(EntitySelectionViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];

}

@end