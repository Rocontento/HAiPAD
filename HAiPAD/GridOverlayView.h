//
//  GridOverlayView.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

@interface GridOverlayView : UIView

@property (nonatomic, assign) CGSize gridSize;
@property (nonatomic, assign) CGFloat gridSpacing;
@property (nonatomic, assign) BOOL showGrid;

- (void)setGridVisible:(BOOL)visible animated:(BOOL)animated;

@end