//
//  WhiteboardLayout.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

@interface WhiteboardLayout : UICollectionViewLayout

@property (nonatomic, assign) CGSize gridSize;
@property (nonatomic, assign) CGFloat gridSpacing;
@property (nonatomic, strong) NSMutableDictionary *itemPositions;

- (void)setPosition:(CGPoint)position forItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGPoint)positionForItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGPoint)snapToGrid:(CGPoint)position;
- (NSArray *)availableGridPositions;
- (BOOL)isGridPositionOccupied:(CGPoint)gridPosition;

@end