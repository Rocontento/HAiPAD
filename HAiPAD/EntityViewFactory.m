//
//  EntityViewFactory.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "EntityViewFactory.h"
#import "ClimateView.h"
#import "LightView.h"
#import "SwitchView.h"
#import "SensorView.h"
#import "BinarySensorView.h"
#import "CoverView.h"
#import "LockView.h"
#import "MediaPlayerView.h"
#import "FanView.h"
#import "HumidifierView.h"
#import "AlarmControlPanelView.h"
#import "CameraView.h"
#import "PersonView.h"
#import "SceneView.h"
#import "ScriptView.h"
#import "AutomationView.h"
#import "InputBooleanView.h"
#import "InputNumberView.h"
#import "InputSelectView.h"
#import "InputDateTimeView.h"

@implementation EntityViewFactory

+ (UIView *)createViewForEntity:(NSDictionary *)entity withFrame:(CGRect)frame {
    NSString *entityId = entity[@"entity_id"];
    NSString *domain = [self domainFromEntityId:entityId];
    
    UIView *entityView = nil;
    
    if ([domain isEqualToString:@"climate"]) {
        entityView = [[ClimateView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"light"]) {
        entityView = [[LightView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"switch"]) {
        entityView = [[SwitchView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"sensor"]) {
        entityView = [[SensorView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"binary_sensor"]) {
        entityView = [[BinarySensorView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"cover"]) {
        entityView = [[CoverView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"lock"]) {
        entityView = [[LockView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"media_player"]) {
        entityView = [[MediaPlayerView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"fan"]) {
        entityView = [[FanView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"humidifier"]) {
        entityView = [[HumidifierView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"alarm_control_panel"]) {
        entityView = [[AlarmControlPanelView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"camera"]) {
        entityView = [[CameraView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"person"] || [domain isEqualToString:@"device_tracker"]) {
        entityView = [[PersonView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"scene"]) {
        entityView = [[SceneView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"script"]) {
        entityView = [[ScriptView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"automation"]) {
        entityView = [[AutomationView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"input_boolean"]) {
        entityView = [[InputBooleanView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"input_number"]) {
        entityView = [[InputNumberView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"input_select"]) {
        entityView = [[InputSelectView alloc] initWithFrame:frame entity:entity];
    } else if ([domain isEqualToString:@"input_datetime"]) {
        entityView = [[InputDateTimeView alloc] initWithFrame:frame entity:entity];
    } else {
        // Fallback to basic sensor view for unknown entities
        entityView = [[SensorView alloc] initWithFrame:frame entity:entity];
    }
    
    return entityView;
}

+ (BOOL)entitySupportsInteraction:(NSDictionary *)entity {
    NSString *entityId = entity[@"entity_id"];
    NSString *domain = [self domainFromEntityId:entityId];
    
    // Define which domains support user interaction
    NSArray *interactiveDomains = @[
        @"light", @"switch", @"climate", @"cover", @"lock", @"media_player",
        @"fan", @"humidifier", @"alarm_control_panel", @"scene", @"script",
        @"automation", @"input_boolean", @"input_number", @"input_select",
        @"input_datetime"
    ];
    
    return [interactiveDomains containsObject:domain];
}

+ (CGSize)defaultGridSizeForEntity:(NSDictionary *)entity {
    NSString *entityId = entity[@"entity_id"];
    NSString *domain = [self domainFromEntityId:entityId];
    
    // Define default grid sizes for different entity types
    if ([domain isEqualToString:@"climate"]) {
        return CGSizeMake(2, 2); // Thermostat needs more space for dial
    } else if ([domain isEqualToString:@"media_player"]) {
        return CGSizeMake(2, 2); // Media player needs space for controls
    } else if ([domain isEqualToString:@"alarm_control_panel"]) {
        return CGSizeMake(2, 3); // Keypad needs more vertical space
    } else if ([domain isEqualToString:@"camera"]) {
        return CGSizeMake(2, 2); // Camera preview needs space
    } else if ([domain isEqualToString:@"cover"]) {
        return CGSizeMake(1, 2); // Cover controls need vertical space
    } else if ([domain isEqualToString:@"input_datetime"]) {
        return CGSizeMake(2, 1); // Date/time picker needs horizontal space
    } else {
        return CGSizeMake(1, 1); // Default size for simple entities
    }
}

+ (NSString *)domainFromEntityId:(NSString *)entityId {
    if (!entityId || ![entityId isKindOfClass:[NSString class]]) {
        return @"unknown";
    }
    
    NSRange dotRange = [entityId rangeOfString:@"."];
    if (dotRange.location != NSNotFound) {
        return [entityId substringToIndex:dotRange.location];
    }
    
    return @"unknown";
}

@end