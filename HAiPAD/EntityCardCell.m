//
//  EntityCardCell.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "EntityCardCell.h"

@implementation EntityCardCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Configure card appearance for iOS 9.3.5 compatibility
    self.cardContainerView.layer.cornerRadius = 8.0;
    self.cardContainerView.layer.masksToBounds = NO;
    
    // Add shadow (iOS 9.3.5 compatible)
    self.cardContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardContainerView.layer.shadowOffset = CGSizeMake(0, 2);
    self.cardContainerView.layer.shadowOpacity = 0.1;
    self.cardContainerView.layer.shadowRadius = 4.0;
    
    // Set background color
    self.cardContainerView.backgroundColor = [UIColor whiteColor];
    
    // Configure labels
    self.nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.stateLabel.font = [UIFont systemFontOfSize:14];
    self.stateLabel.textColor = [UIColor grayColor];
    
    // Configure info button
    self.infoButton.layer.cornerRadius = 10.0;
    self.infoButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    [self.infoButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Reset to default appearance
    self.cardContainerView.backgroundColor = [UIColor whiteColor];
    self.nameLabel.text = @"";
    self.stateLabel.text = @"";
}

- (void)configureWithEntity:(NSDictionary *)entity {
    NSString *entityId = entity[@"entity_id"];
    NSString *friendlyName = entity[@"attributes"][@"friendly_name"] ?: entityId;
    NSString *state = entity[@"state"];
    
    self.nameLabel.text = friendlyName;
    self.stateLabel.text = [self formatStateForEntity:entity];
    
    // Set card color based on entity type and state
    [self updateCardAppearanceForEntity:entity];
}

- (NSString *)formatStateForEntity:(NSDictionary *)entity {
    NSString *entityId = entity[@"entity_id"];
    NSString *state = entity[@"state"];
    
    if ([entityId hasPrefix:@"light."] || [entityId hasPrefix:@"switch."] || [entityId hasPrefix:@"fan."]) {
        return [state isEqualToString:@"on"] ? @"On" : @"Off";
    } else if ([entityId hasPrefix:@"binary_sensor."]) {
        return [state isEqualToString:@"on"] ? @"Detected" : @"Clear";
    } else if ([entityId hasPrefix:@"sensor."]) {
        NSString *unit = entity[@"attributes"][@"unit_of_measurement"];
        if (unit) {
            return [NSString stringWithFormat:@"%@ %@", state, unit];
        }
        return state;
    } else if ([entityId hasPrefix:@"climate."]) {
        NSNumber *currentTemp = entity[@"attributes"][@"current_temperature"];
        NSNumber *targetTemp = entity[@"attributes"][@"temperature"];
        NSString *unit = entity[@"attributes"][@"temperature_unit"] ?: @"°C";
        
        if (currentTemp && targetTemp) {
            return [NSString stringWithFormat:@"%.1f%@ → %.1f%@", 
                   currentTemp.floatValue, unit, targetTemp.floatValue, unit];
        } else if (currentTemp) {
            return [NSString stringWithFormat:@"%.1f%@", currentTemp.floatValue, unit];
        }
        return state;
    }
    
    return state;
}

- (void)updateCardAppearanceForEntity:(NSDictionary *)entity {
    NSString *entityId = entity[@"entity_id"];
    NSString *state = entity[@"state"];
    
    if ([entityId hasPrefix:@"light."]) {
        if ([state isEqualToString:@"on"]) {
            // Light is on - warm yellow background
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.8 alpha:1.0];
            self.nameLabel.textColor = [UIColor colorWithRed:0.8 green:0.6 blue:0.0 alpha:1.0];
        } else {
            // Light is off - default appearance
            self.cardContainerView.backgroundColor = [UIColor whiteColor];
            self.nameLabel.textColor = [UIColor darkTextColor];
        }
    } else if ([entityId hasPrefix:@"switch."]) {
        if ([state isEqualToString:@"on"]) {
            // Switch is on - light blue background
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:0.9 green:0.95 blue:1.0 alpha:1.0];
            self.nameLabel.textColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
        } else {
            // Switch is off - default appearance
            self.cardContainerView.backgroundColor = [UIColor whiteColor];
            self.nameLabel.textColor = [UIColor darkTextColor];
        }
    } else if ([entityId hasPrefix:@"fan."]) {
        if ([state isEqualToString:@"on"]) {
            // Fan is on - light green background
            self.cardContainerView.backgroundColor = [UIColor colorWithRed:0.9 green:1.0 blue:0.9 alpha:1.0];
            self.nameLabel.textColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.0 alpha:1.0];
        } else {
            // Fan is off - default appearance
            self.cardContainerView.backgroundColor = [UIColor whiteColor];
            self.nameLabel.textColor = [UIColor darkTextColor];
        }
    } else if ([entityId hasPrefix:@"climate."]) {
        // Climate - orange/red tint
        self.cardContainerView.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.9 alpha:1.0];
        self.nameLabel.textColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
    } else if ([entityId hasPrefix:@"sensor."] || [entityId hasPrefix:@"binary_sensor."]) {
        // Sensors - light gray background
        self.cardContainerView.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];
        self.nameLabel.textColor = [UIColor darkTextColor];
    } else {
        // Default appearance
        self.cardContainerView.backgroundColor = [UIColor whiteColor];
        self.nameLabel.textColor = [UIColor darkTextColor];
    }
}

@end