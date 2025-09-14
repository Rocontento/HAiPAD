//
//  EmptyGridSlotView.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

@interface EmptyGridSlotView : UICollectionReusableView

@property (nonatomic, assign) BOOL highlighted;

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;

@end