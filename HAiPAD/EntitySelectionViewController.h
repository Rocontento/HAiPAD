//
//  EntitySelectionViewController.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

@class EntitySelectionViewController;

@protocol EntitySelectionViewControllerDelegate <NSObject>
@optional
- (void)entitySelectionViewController:(EntitySelectionViewController *)controller 
                     didSelectEntity:(NSDictionary *)entity 
                      forGridPosition:(CGPoint)gridPosition;
- (void)entitySelectionViewControllerDidCancel:(EntitySelectionViewController *)controller;
@end

@interface EntitySelectionViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id<EntitySelectionViewControllerDelegate> delegate;
@property (nonatomic, assign) CGPoint targetGridPosition;
@property (nonatomic, strong) NSArray *availableEntities;

+ (instancetype)controllerWithEntities:(NSArray *)entities targetGridPosition:(CGPoint)gridPosition;

@end