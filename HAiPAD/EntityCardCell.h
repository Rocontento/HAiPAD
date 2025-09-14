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

@property (nonatomic, assign) BOOL editModeEnabled;

- (void)configureWithEntity:(NSDictionary *)entity;
- (void)setEditModeEnabled:(BOOL)enabled animated:(BOOL)animated;

@end