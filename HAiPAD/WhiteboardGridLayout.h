//
//  WhiteboardGridLayout.h
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import <UIKit/UIKit.h>

@protocol WhiteboardGridLayoutDelegate <NSObject>

@optional
// Return the grid position for an item (row, column)
- (CGPoint)gridPositionForItemAtIndexPath:(NSIndexPath *)indexPath;

// Return the size in grid units for an item (width, height in grid cells)
- (CGSize)gridSizeForItemAtIndexPath:(NSIndexPath *)indexPath;

// Called when user moves an item to a new grid position
- (void)didMoveItemAtIndexPath:(NSIndexPath *)indexPath toGridPosition:(CGPoint)gridPosition;

// Called when user resizes an item
- (void)didResizeItemAtIndexPath:(NSIndexPath *)indexPath toSize:(CGSize)gridSize;

// Check if a position and size is valid for placement
- (BOOL)canPlaceItemAtGridPosition:(CGPoint)gridPosition withSize:(CGSize)gridSize excludingIndexPath:(NSIndexPath *)excludingIndexPath;

@end

@interface WhiteboardGridLayout : UICollectionViewLayout

@property (nonatomic, weak) id<WhiteboardGridLayoutDelegate> delegate;

// Grid configuration
@property (nonatomic, assign) NSInteger gridColumns;    // Number of columns in the grid
@property (nonatomic, assign) NSInteger gridRows;      // Number of rows in the grid
@property (nonatomic, assign) CGFloat cellSpacing;     // Spacing between grid cells
@property (nonatomic, assign) UIEdgeInsets gridInsets; // Insets around the grid

// Visual feedback
@property (nonatomic, assign) BOOL showEmptySlots;     // Show visual indicators for empty grid slots

// Interaction
@property (nonatomic, assign) BOOL allowsReordering;   // Enable drag-and-drop reordering

- (CGPoint)gridPositionFromPoint:(CGPoint)point;
- (CGRect)frameForGridPosition:(CGPoint)gridPosition size:(CGSize)gridSize;
- (BOOL)isGridPositionValid:(CGPoint)gridPosition withSize:(CGSize)gridSize excludingIndexPath:(NSIndexPath *)excludingIndexPath;

@end