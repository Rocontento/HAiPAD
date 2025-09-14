//
//  EntityCardCell.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

@protocol EntityCardCellDelegate <NSObject>
@optional
- (void)entityCardCell:(UICollectionViewCell *)cell didStartResizing:(UIPanGestureRecognizer *)gesture;
- (void)entityCardCell:(UICollectionViewCell *)cell didResize:(UIPanGestureRecognizer *)gesture;
- (void)entityCardCell:(UICollectionViewCell *)cell didEndResizing:(UIPanGestureRecognizer *)gesture;
@end

@interface EntityCardCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UIView *cardContainerView;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (nonatomic, strong) UIView *resizeHandle;
@property (nonatomic, weak) id<EntityCardCellDelegate> delegate;

- (void)configureWithEntity:(NSDictionary *)entity;
- (void)setEditingMode:(BOOL)editingMode;

@end