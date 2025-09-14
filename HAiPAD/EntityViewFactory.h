//
//  EntityViewFactory.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

@interface EntityViewFactory : NSObject

// Factory method to create appropriate view for entity
+ (UIView *)createViewForEntity:(NSDictionary *)entity withFrame:(CGRect)frame;

// Check if entity supports interactive controls
+ (BOOL)entitySupportsInteraction:(NSDictionary *)entity;

// Get default grid size for entity type
+ (CGSize)defaultGridSizeForEntity:(NSDictionary *)entity;

// Get domain from entity_id
+ (NSString *)domainFromEntityId:(NSString *)entityId;

@end