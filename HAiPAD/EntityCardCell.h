//
//  EntityCardCell.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>
#import "BaseEntityView.h"

@class EntityCardCell;

@protocol EntityCardCellDelegate <NSObject>
@optional
- (void)entityCardCell:(EntityCardCell *)cell didRequestSizeChange:(CGSize)newSize;
- (void)entityCardCell:(EntityCardCell *)cell didBeginResizing:(UIGestureRecognizer *)gesture;
- (void)entityCardCell:(EntityCardCell *)cell didUpdateResizing:(UIGestureRecognizer *)gesture;
- (void)entityCardCell:(EntityCardCell *)cell didEndResizing:(UIGestureRecognizer *)gesture;
- (void)entityCardCell:(EntityCardCell *)cell didRequestServiceCall:(NSString *)domain service:(NSString *)service entityId:(NSString *)entityId parameters:(NSDictionary *)parameters;
@end

@interface EntityCardCell : UICollectionViewCell <BaseEntityViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UIView *cardContainerView;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;

@property (weak, nonatomic) id<EntityCardCellDelegate> delegate;
@property (nonatomic, assign) CGSize gridSize; // Size in grid units (width, height)
@property (nonatomic, assign) BOOL editingMode;
@property (nonatomic, strong) UIView *resizeHandle;
@property (nonatomic, strong) BaseEntityView *entityView; // The domain-specific entity view

- (void)configureWithEntity:(NSDictionary *)entity;
- (void)setEditingMode:(BOOL)editingMode animated:(BOOL)animated;
- (void)startWiggleAnimation;
- (void)stopWiggleAnimation;

@end