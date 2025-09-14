//
//  EntitySelectionViewController.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "EntitySelectionViewController.h"

@interface EntitySelectionViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@end

@implementation EntitySelectionViewController

+ (instancetype)controllerWithEntities:(NSArray *)entities targetGridPosition:(CGPoint)gridPosition {
    EntitySelectionViewController *controller = [[EntitySelectionViewController alloc] init];
    controller.availableEntities = entities;
    controller.targetGridPosition = gridPosition;
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5]; // Semi-transparent background
    
    [self setupUI];
}

- (void)setupUI {
    // Create container view
    UIView *containerView = [[UIView alloc] init];
    containerView.backgroundColor = [UIColor whiteColor];
    containerView.layer.cornerRadius = 12.0;
    containerView.layer.masksToBounds = YES;
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:containerView];
    
    // Title label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = [NSString stringWithFormat:@"Select Entity for Position (%.0f, %.0f)", 
                           self.targetGridPosition.x, self.targetGridPosition.y];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:self.titleLabel];
    
    // Cancel button
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:self.cancelButton];
    
    // Table view
    self.tableView = [[UITableView alloc] init];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:self.tableView];
    
    // Setup constraints
    [NSLayoutConstraint activateConstraints:@[
        // Container view - centered and sized
        [containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [containerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [containerView.widthAnchor constraintEqualToConstant:400],
        [containerView.heightAnchor constraintEqualToConstant:500],
        
        // Title label
        [self.titleLabel.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:16],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:16],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-16],
        
        // Cancel button
        [self.cancelButton.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:8],
        [self.cancelButton.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-16],
        
        // Table view
        [self.tableView.topAnchor constraintEqualToAnchor:self.cancelButton.bottomAnchor constant:8],
        [self.tableView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor]
    ]];
}

- (void)cancelButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(entitySelectionViewControllerDidCancel:)]) {
        [self.delegate entitySelectionViewControllerDidCancel:self];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.availableEntities.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"EntitySelectionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSDictionary *entity = self.availableEntities[indexPath.row];
    NSString *entityId = entity[@"entity_id"];
    NSString *friendlyName = entity[@"attributes"][@"friendly_name"] ?: entityId;
    NSString *state = entity[@"state"];
    NSString *domain = [[entityId componentsSeparatedByString:@"."] firstObject];
    
    cell.textLabel.text = friendlyName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ • %@", domain, state];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    // Add entity type icon based on domain
    NSString *iconText = @"•";
    if ([domain isEqualToString:@"light"]) {
        iconText = @"💡";
    } else if ([domain isEqualToString:@"switch"]) {
        iconText = @"🔌";
    } else if ([domain isEqualToString:@"sensor"]) {
        iconText = @"📊";
    } else if ([domain isEqualToString:@"climate"]) {
        iconText = @"🌡️";
    } else if ([domain isEqualToString:@"cover"]) {
        iconText = @"🏠";
    } else if ([domain isEqualToString:@"fan"]) {
        iconText = @"🌀";
    } else if ([domain isEqualToString:@"lock"]) {
        iconText = @"🔒";
    }
    
    UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    iconLabel.text = iconText;
    iconLabel.textAlignment = NSTextAlignmentCenter;
    iconLabel.font = [UIFont systemFontOfSize:16];
    cell.imageView.image = nil; // Clear any existing image
    [cell.contentView addSubview:iconLabel];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *selectedEntity = self.availableEntities[indexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(entitySelectionViewController:didSelectEntity:forGridPosition:)]) {
        [self.delegate entitySelectionViewController:self 
                                    didSelectEntity:selectedEntity 
                                     forGridPosition:self.targetGridPosition];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0; // Slightly taller rows for better readability
}

@end