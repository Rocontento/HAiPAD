//
//  EmptyGridSlotView.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

@class EmptyGridSlotView;

@protocol EmptyGridSlotViewDelegate <NSObject>
@optional
- (void)emptyGridSlotViewWasTapped:(EmptyGridSlotView *)slotView atGridPosition:(CGPoint)gridPosition;
@end

@interface EmptyGridSlotView : UICollectionReusableView

@property (nonatomic, weak) id<EmptyGridSlotViewDelegate> delegate;
@property (nonatomic, assign) BOOL highlighted;
@property (nonatomic, assign) CGPoint gridPosition;

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;

@end