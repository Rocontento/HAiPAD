//
//  EntityCardCell.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

@interface EntityCardCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UIView *cardContainerView;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;

// Resize handles for edit mode
@property (strong, nonatomic) UIView *resizeHandleBottomRight;
@property (strong, nonatomic) UIView *resizeHandleBottomLeft;
@property (strong, nonatomic) UIView *resizeHandleTopRight;
@property (strong, nonatomic) UIView *resizeHandleTopLeft;

// Resize gesture recognizers
@property (strong, nonatomic) UIPanGestureRecognizer *resizePanGesture;

@property (nonatomic, assign) BOOL editModeEnabled;

// Resize delegate
@property (nonatomic, weak) id<EntityCardCellResizeDelegate> resizeDelegate;

- (void)configureWithEntity:(NSDictionary *)entity;
- (void)setEditModeEnabled:(BOOL)enabled animated:(BOOL)animated;

@end

@protocol EntityCardCellResizeDelegate <NSObject>
@optional
- (void)entityCardCell:(EntityCardCell *)cell didBeginResizeWithGesture:(UIPanGestureRecognizer *)gesture;
- (void)entityCardCell:(EntityCardCell *)cell didChangeResizeWithGesture:(UIPanGestureRecognizer *)gesture;
- (void)entityCardCell:(EntityCardCell *)cell didEndResizeWithGesture:(UIPanGestureRecognizer *)gesture;
@end

@end