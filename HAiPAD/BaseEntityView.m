//
//  BaseEntityView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "BaseEntityView.h"

@implementation BaseEntityView

- (instancetype)initWithFrame:(CGRect)frame entity:(NSDictionary *)entity {
    self = [super initWithFrame:frame];
    if (self) {
        self.entity = entity;
        [self setupBaseUI];
        [self setupCardAppearance];
        [self setupEntitySpecificUI];
        [self updateWithEntity:entity];
    }
    return self;
}

- (void)setupBaseUI {
    // Create card container
    self.cardContainer = [[UIView alloc] init];
    self.cardContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardContainer.backgroundColor = [UIColor whiteColor];
    self.cardContainer.layer.cornerRadius = 12.0;
    self.cardContainer.clipsToBounds = NO;
    [self addSubview:self.cardContainer];
    
    // Fill the entire view
    [NSLayoutConstraint activateConstraints:@[
        [self.cardContainer.topAnchor constraintEqualToAnchor:self.topAnchor constant:4],
        [self.cardContainer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
        [self.cardContainer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-4],
        [self.cardContainer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4]
    ]];
    
    // Add shadow
    [self addCardShadow];
    
    // Create name label
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.font = [UIFont systemFontOfSize:14];
    self.nameLabel.textColor = [UIColor darkTextColor];
    self.nameLabel.numberOfLines = 2;
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardContainer addSubview:self.nameLabel];
    
    // Create state label
    self.stateLabel = [[UILabel alloc] init];
    self.stateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.stateLabel.font = [UIFont systemFontOfSize:12];
    self.stateLabel.textColor = [UIColor grayColor];
    self.stateLabel.numberOfLines = 1;
    self.stateLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardContainer addSubview:self.stateLabel];
    
    // Position labels at the bottom
    [NSLayoutConstraint activateConstraints:@[
        [self.stateLabel.leadingAnchor constraintEqualToAnchor:self.cardContainer.leadingAnchor constant:8],
        [self.stateLabel.trailingAnchor constraintEqualToAnchor:self.cardContainer.trailingAnchor constant:-8],
        [self.stateLabel.bottomAnchor constraintEqualToAnchor:self.cardContainer.bottomAnchor constant:-8],
        
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.cardContainer.leadingAnchor constant:8],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.cardContainer.trailingAnchor constant:-8],
        [self.nameLabel.bottomAnchor constraintEqualToAnchor:self.stateLabel.topAnchor constant:-4]
    ]];
}

- (void)setupCardAppearance {
    // Default implementation - can be overridden
    self.cardContainer.backgroundColor = [UIColor whiteColor];
}

- (void)setupEntitySpecificUI {
    // Abstract method - must be overridden by subclasses
}

- (void)updateWithEntity:(NSDictionary *)entity {
    self.entity = entity;
    self.nameLabel.text = [self friendlyName];
    self.stateLabel.text = [self state];
    self.cardContainer.backgroundColor = [self colorForEntityState];
}

- (void)addCardShadow {
    self.cardContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardContainer.layer.shadowOffset = CGSizeMake(0, 2);
    self.cardContainer.layer.shadowOpacity = 0.1;
    self.cardContainer.layer.shadowRadius = 4.0;
}

#pragma mark - Utility Methods

- (NSString *)friendlyName {
    return self.entity[@"attributes"][@"friendly_name"] ?: [self entityId];
}

- (NSString *)entityId {
    return self.entity[@"entity_id"] ?: @"";
}

- (NSString *)state {
    return self.entity[@"state"] ?: @"unavailable";
}

- (NSDictionary *)attributes {
    return self.entity[@"attributes"] ?: @{};
}

- (UIColor *)colorForEntityState {
    // Default implementation - can be overridden
    NSString *state = [self state];
    if ([state isEqualToString:@"on"]) {
        return [UIColor colorWithRed:0.9 green:0.95 blue:1.0 alpha:1.0];
    } else if ([state isEqualToString:@"off"]) {
        return [UIColor whiteColor];
    } else if ([state isEqualToString:@"unavailable"] || [state isEqualToString:@"unknown"]) {
        return [UIColor colorWithWhite:0.95 alpha:1.0];
    }
    return [UIColor whiteColor];
}

@end