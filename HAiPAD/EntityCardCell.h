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

- (void)configureWithEntity:(NSDictionary *)entity;

@end