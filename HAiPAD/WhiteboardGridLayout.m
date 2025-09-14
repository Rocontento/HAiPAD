//
//  WhiteboardGridLayout.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "WhiteboardGridLayout.h"

@interface WhiteboardGridLayout ()
@property (nonatomic, strong) NSMutableDictionary *layoutAttributes;
@property (nonatomic, strong) NSMutableSet *occupiedPositions;
@property (nonatomic, strong) NSMutableDictionary *gridSizes; // indexPath -> gridSize
@property (nonatomic, strong) NSMutableDictionary *emptySlotGridPositions; // indexPath -> NSValue(CGPoint)
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, assign) CGSize cellSize;
@end

@implementation WhiteboardGridLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.gridColumns = 4;  // Default 4 columns for iPad
    self.gridRows = 6;     // Default 6 rows
    self.cellSpacing = 12.0;
    self.gridInsets = UIEdgeInsetsMake(16, 16, 16, 16);
    self.showEmptySlots = YES;
    self.showGridOverlay = NO;
    self.allowsReordering = YES;
    
    self.layoutAttributes = [NSMutableDictionary dictionary];
    self.occupiedPositions = [NSMutableSet set];
    self.gridSizes = [NSMutableDictionary dictionary];
    self.emptySlotGridPositions = [NSMutableDictionary dictionary];
}

#pragma mark - UICollectionViewLayout Override Methods

- (void)prepareLayout {
    [super prepareLayout];
    
    [self.layoutAttributes removeAllObjects];
    [self.occupiedPositions removeAllObjects];
    [self.emptySlotGridPositions removeAllObjects];
    
    // Calculate cell size based on collection view dimensions
    [self calculateCellSize];
    [self calculateContentSize];
    
    // Prepare layout attributes for each item
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    for (NSInteger section = 0; section < numberOfSections; section++) {
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
        
        for (NSInteger item = 0; item < numberOfItems; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
            
            if (attributes) {
                NSString *key = [NSString stringWithFormat:@"%ld-%ld", (long)section, (long)item];
                self.layoutAttributes[key] = attributes;
            }
        }
    }
}

- (CGSize)collectionViewContentSize {
    return self.contentSize;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attributesArray = [NSMutableArray array];
    
    // Add item attributes
    [self.layoutAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, UICollectionViewLayoutAttributes *attributes, BOOL *stop) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [attributesArray addObject:attributes];
        }
    }];
    
    // Add empty slot attributes if enabled
    if (self.showEmptySlots) {
        NSMutableSet *emptyPositions = [NSMutableSet set];
        
        // Find all empty positions
        for (NSInteger row = 0; row < self.gridRows; row++) {
            for (NSInteger col = 0; col < self.gridColumns; col++) {
                NSString *positionKey = [NSString stringWithFormat:@"%ld-%ld", (long)col, (long)row];
                if (![self.occupiedPositions containsObject:positionKey]) {
                    [emptyPositions addObject:positionKey];
                }
            }
        }
        
        // Create attributes for empty positions that intersect with rect
        NSInteger slotIndex = 0;
        for (NSString *positionKey in emptyPositions) {
            NSArray *components = [positionKey componentsSeparatedByString:@"-"];
            NSInteger col = [components[0] integerValue];
            NSInteger row = [components[1] integerValue];
            
            CGRect slotFrame = [self frameForGridPosition:CGPointMake(col, row) size:CGSizeMake(1, 1)];
            
            if (CGRectIntersectsRect(slotFrame, rect)) {
                UICollectionViewLayoutAttributes *emptySlotAttributes = 
                    [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:@"EmptySlot"
                                                                                     withIndexPath:[NSIndexPath indexPathForItem:slotIndex inSection:0]];
                emptySlotAttributes.frame = slotFrame;
                emptySlotAttributes.zIndex = -1; // Behind regular items
                
                // Store grid position for this empty slot
                NSIndexPath *emptySlotIndexPath = [NSIndexPath indexPathForItem:slotIndex inSection:0];
                self.emptySlotGridPositions[emptySlotIndexPath] = [NSValue valueWithCGPoint:CGPointMake(col, row)];
                
                [attributesArray addObject:emptySlotAttributes];
                slotIndex++;
            }
        }
    }
    
    return attributesArray;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    // Get grid position from delegate or use auto-placement
    CGPoint gridPosition = CGPointMake(0, 0);
    CGSize gridSize = CGSizeMake(1, 1); // Default to 1x1 grid cell
    
    if ([self.delegate respondsToSelector:@selector(gridPositionForItemAtIndexPath:)]) {
        gridPosition = [self.delegate gridPositionForItemAtIndexPath:indexPath];
    } else {
        // Auto-place in the first available position
        gridPosition = [self findNextAvailablePosition];
    }
    
    if ([self.delegate respondsToSelector:@selector(gridSizeForItemAtIndexPath:)]) {
        gridSize = [self.delegate gridSizeForItemAtIndexPath:indexPath];
    }
    
    // Validate and adjust position if necessary
    if (![self isGridPositionValid:gridPosition withSize:gridSize]) {
        gridPosition = [self findNextAvailablePosition];
    }
    
    // Mark positions as occupied
    [self markPositionsAsOccupied:gridPosition withSize:gridSize];
    
    // Calculate frame
    CGRect frame = [self frameForGridPosition:gridPosition size:gridSize];
    attributes.frame = frame;
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([elementKind isEqualToString:@"EmptySlot"]) {
        UICollectionViewLayoutAttributes *attributes = 
            [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
        
        // This will be set properly in layoutAttributesForElementsInRect
        attributes.frame = CGRectZero;
        attributes.zIndex = -1;
        
        return attributes;
    }
    
    return nil;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return !CGSizeEqualToSize(newBounds.size, self.collectionView.bounds.size);
}

#pragma mark - Grid Calculation Methods

- (void)calculateCellSize {
    CGFloat availableWidth = self.collectionView.bounds.size.width - self.gridInsets.left - self.gridInsets.right - ((self.gridColumns - 1) * self.cellSpacing);
    CGFloat cellWidth = availableWidth / self.gridColumns;
    
    CGFloat availableHeight = self.collectionView.bounds.size.height - self.gridInsets.top - self.gridInsets.bottom - ((self.gridRows - 1) * self.cellSpacing);
    CGFloat cellHeight = availableHeight / self.gridRows;
    
    // For cards, maintain a reasonable aspect ratio (prefer square-ish cards)
    CGFloat cardHeight = MAX(cellHeight, 100.0); // Minimum height
    
    self.cellSize = CGSizeMake(cellWidth, cardHeight);
}

- (void)calculateContentSize {
    CGFloat contentWidth = self.gridInsets.left + (self.gridColumns * self.cellSize.width) + ((self.gridColumns - 1) * self.cellSpacing) + self.gridInsets.right;
    CGFloat contentHeight = self.gridInsets.top + (self.gridRows * self.cellSize.height) + ((self.gridRows - 1) * self.cellSpacing) + self.gridInsets.bottom;
    
    self.contentSize = CGSizeMake(contentWidth, contentHeight);
}

- (CGRect)frameForGridPosition:(CGPoint)gridPosition size:(CGSize)gridSize {
    CGFloat x = self.gridInsets.left + (gridPosition.x * (self.cellSize.width + self.cellSpacing));
    CGFloat y = self.gridInsets.top + (gridPosition.y * (self.cellSize.height + self.cellSpacing));
    
    CGFloat width = (gridSize.width * self.cellSize.width) + ((gridSize.width - 1) * self.cellSpacing);
    CGFloat height = (gridSize.height * self.cellSize.height) + ((gridSize.height - 1) * self.cellSpacing);
    
    return CGRectMake(x, y, width, height);
}

- (CGPoint)gridPositionFromPoint:(CGPoint)point {
    // Adjust point for grid insets
    point.x -= self.gridInsets.left;
    point.y -= self.gridInsets.top;
    
    // Calculate grid position with improved accuracy
    // Use center-point calculation to determine which cell the point falls into
    CGFloat cellWidthWithSpacing = self.cellSize.width + self.cellSpacing;
    CGFloat cellHeightWithSpacing = self.cellSize.height + self.cellSpacing;
    
    // Calculate column and row based on which cell center the point is closest to
    NSInteger column = (NSInteger)((point.x + self.cellSize.width * 0.5) / cellWidthWithSpacing);
    NSInteger row = (NSInteger)((point.y + self.cellSize.height * 0.5) / cellHeightWithSpacing);
    
    // Clamp to grid bounds
    column = MAX(0, MIN(column, self.gridColumns - 1));
    row = MAX(0, MIN(row, self.gridRows - 1));
    
    return CGPointMake(column, row);
}

- (CGPoint)gridPositionFromPoint:(CGPoint)point forCardSize:(CGSize)cardSize {
    // Adjust point for grid insets
    point.x -= self.gridInsets.left;
    point.y -= self.gridInsets.top;
    
    CGFloat cellWidthWithSpacing = self.cellSize.width + self.cellSpacing;
    CGFloat cellHeightWithSpacing = self.cellSize.height + self.cellSpacing;
    
    // For multi-cell cards, we want to calculate the optimal position
    // such that the card fits completely within the grid
    NSInteger column = (NSInteger)(point.x / cellWidthWithSpacing);
    NSInteger row = (NSInteger)(point.y / cellHeightWithSpacing);
    
    // Ensure the card fits within grid bounds
    column = MAX(0, MIN(column, self.gridColumns - (NSInteger)cardSize.width));
    row = MAX(0, MIN(row, self.gridRows - (NSInteger)cardSize.height));
    
    return CGPointMake(column, row);
}

- (BOOL)isGridPositionValid:(CGPoint)gridPosition withSize:(CGSize)gridSize {
    return [self isGridPositionValid:gridPosition withSize:gridSize excludingIndexPath:nil];
}

- (BOOL)isGridPositionValid:(CGPoint)gridPosition withSize:(CGSize)gridSize excludingIndexPath:(NSIndexPath *)excludingIndexPath {
    // Check bounds
    if (gridPosition.x < 0 || gridPosition.y < 0) return NO;
    if (gridPosition.x + gridSize.width > self.gridColumns) return NO;
    if (gridPosition.y + gridSize.height > self.gridRows) return NO;
    
    // Check for overlaps with occupied positions
    for (NSInteger row = gridPosition.y; row < gridPosition.y + gridSize.height; row++) {
        for (NSInteger col = gridPosition.x; col < gridPosition.x + gridSize.width; col++) {
            NSString *positionKey = [NSString stringWithFormat:@"%ld-%ld", (long)col, (long)row];
            if ([self.occupiedPositions containsObject:positionKey]) {
                // If excluding an index path, check if this position belongs to that item
                if (excludingIndexPath) {
                    BOOL belongsToExcluded = [self doesPosition:CGPointMake(col, row) belongToIndexPath:excludingIndexPath];
                    if (!belongsToExcluded) {
                        return NO;
                    }
                } else {
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

- (BOOL)doesPosition:(CGPoint)position belongToIndexPath:(NSIndexPath *)indexPath {
    // Get the grid position and size for the index path
    CGPoint gridPosition = CGPointMake(0, 0);
    CGSize gridSize = CGSizeMake(1, 1);
    
    if ([self.delegate respondsToSelector:@selector(gridPositionForItemAtIndexPath:)]) {
        gridPosition = [self.delegate gridPositionForItemAtIndexPath:indexPath];
    }
    
    if ([self.delegate respondsToSelector:@selector(gridSizeForItemAtIndexPath:)]) {
        gridSize = [self.delegate gridSizeForItemAtIndexPath:indexPath];
    }
    
    // Check if position falls within the item's grid area
    return (position.x >= gridPosition.x && position.x < gridPosition.x + gridSize.width &&
            position.y >= gridPosition.y && position.y < gridPosition.y + gridSize.height);
}

- (void)setGridSize:(CGSize)gridSize forIndexPath:(NSIndexPath *)indexPath {
    NSString *key = [NSString stringWithFormat:@"%ld-%ld", (long)indexPath.section, (long)indexPath.item];
    self.gridSizes[key] = [NSValue valueWithCGSize:gridSize];
}

- (CGSize)gridSizeForIndexPath:(NSIndexPath *)indexPath {
    NSString *key = [NSString stringWithFormat:@"%ld-%ld", (long)indexPath.section, (long)indexPath.item];
    NSValue *sizeValue = self.gridSizes[key];
    if (sizeValue) {
        return [sizeValue CGSizeValue];
    }
    
    // Ask delegate or return default
    if ([self.delegate respondsToSelector:@selector(gridSizeForItemAtIndexPath:)]) {
        return [self.delegate gridSizeForItemAtIndexPath:indexPath];
    }
    
    return CGSizeMake(1, 1); // Default size
}

- (void)markPositionsAsOccupied:(CGPoint)gridPosition withSize:(CGSize)gridSize {
    for (NSInteger row = gridPosition.y; row < gridPosition.y + gridSize.height; row++) {
        for (NSInteger col = gridPosition.x; col < gridPosition.x + gridSize.width; col++) {
            NSString *positionKey = [NSString stringWithFormat:@"%ld-%ld", (long)col, (long)row];
            [self.occupiedPositions addObject:positionKey];
        }
    }
}

- (CGPoint)findNextAvailablePosition {
    for (NSInteger row = 0; row < self.gridRows; row++) {
        for (NSInteger col = 0; col < self.gridColumns; col++) {
            CGPoint position = CGPointMake(col, row);
            if ([self isGridPositionValid:position withSize:CGSizeMake(1, 1)]) {
                return position;
            }
        }
    }
    
    // If no position found, return (0,0) - this shouldn't happen in normal usage
    return CGPointMake(0, 0);
}

#pragma mark - Property Setters

- (void)setGridColumns:(NSInteger)gridColumns {
    _gridColumns = gridColumns;
    [self invalidateLayout];
}

- (void)setGridRows:(NSInteger)gridRows {
    _gridRows = gridRows;
    [self invalidateLayout];
}

- (void)setCellSpacing:(CGFloat)cellSpacing {
    _cellSpacing = cellSpacing;
    [self invalidateLayout];
}

- (void)setGridInsets:(UIEdgeInsets)gridInsets {
    _gridInsets = gridInsets;
    [self invalidateLayout];
}

#pragma mark - Grid Overlay Methods

- (void)showGridOverlayInView:(UIView *)view {
    if (!view || self.gridOverlayView) return; // Don't create multiple overlays
    
    self.showGridOverlay = YES;
    
    // Create overlay view
    self.gridOverlayView = [[UIView alloc] initWithFrame:view.bounds];
    self.gridOverlayView.backgroundColor = [UIColor clearColor];
    self.gridOverlayView.userInteractionEnabled = NO;
    
    // Create grid lines
    [self drawGridLinesInOverlay];
    
    // Add to view
    [view addSubview:self.gridOverlayView];
    
    // Animate in
    self.gridOverlayView.alpha = 0.0;
    [UIView animateWithDuration:0.3 animations:^{
        self.gridOverlayView.alpha = 1.0;
    }];
}

- (void)hideGridOverlay {
    if (!self.gridOverlayView) return;
    
    self.showGridOverlay = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.gridOverlayView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.gridOverlayView removeFromSuperview];
        self.gridOverlayView = nil;
    }];
}

- (void)drawGridLinesInOverlay {
    if (!self.gridOverlayView) return;
    
    // Remove existing grid lines
    for (UIView *subview in self.gridOverlayView.subviews) {
        [subview removeFromSuperview];
    }
    
    CGFloat overlayWidth = self.gridOverlayView.bounds.size.width;
    CGFloat overlayHeight = self.gridOverlayView.bounds.size.height;
    
    // Safety check for zero dimensions
    if (overlayWidth <= 0 || overlayHeight <= 0 || self.gridColumns <= 0 || self.gridRows <= 0) {
        return;
    }
    
    // Calculate cell size for the overlay
    CGFloat cellWidth = (overlayWidth - self.gridInsets.left - self.gridInsets.right - ((self.gridColumns - 1) * self.cellSpacing)) / self.gridColumns;
    CGFloat cellHeight = (overlayHeight - self.gridInsets.top - self.gridInsets.bottom - ((self.gridRows - 1) * self.cellSpacing)) / self.gridRows;
    
    // Safety check for negative cell sizes
    if (cellWidth <= 0 || cellHeight <= 0) {
        return;
    }
    
    // Draw vertical lines
    for (NSInteger col = 0; col <= self.gridColumns; col++) {
        CGFloat x = self.gridInsets.left + (col * (cellWidth + self.cellSpacing));
        if (col == self.gridColumns) {
            x = overlayWidth - self.gridInsets.right; // Adjust last line to account for inset
        }
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(x, self.gridInsets.top, 1, overlayHeight - self.gridInsets.top - self.gridInsets.bottom)];
        line.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5];
        [self.gridOverlayView addSubview:line];
    }
    
    // Draw horizontal lines
    for (NSInteger row = 0; row <= self.gridRows; row++) {
        CGFloat y = self.gridInsets.top + (row * (cellHeight + self.cellSpacing));
        if (row == self.gridRows) {
            y = overlayHeight - self.gridInsets.bottom; // Adjust last line to account for inset
        }
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(self.gridInsets.left, y, overlayWidth - self.gridInsets.left - self.gridInsets.right, 1)];
        line.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5];
        [self.gridOverlayView addSubview:line];
    }
}

- (void)highlightGridCells:(CGPoint)position size:(CGSize)size {
    if (!self.gridOverlayView) return;
    
    // Safety checks
    if (size.width <= 0 || size.height <= 0) return;
    if (position.x < 0 || position.y < 0) return;
    
    // Remove existing highlights
    NSArray *subviews = [self.gridOverlayView.subviews copy];
    for (UIView *subview in subviews) {
        if (subview.tag == 999) { // Highlight views have tag 999
            [subview removeFromSuperview];
        }
    }
    
    // Calculate frame for highlighted area using overlay dimensions
    CGFloat overlayWidth = self.gridOverlayView.bounds.size.width;
    CGFloat overlayHeight = self.gridOverlayView.bounds.size.height;
    
    // Safety check for zero dimensions
    if (overlayWidth <= 0 || overlayHeight <= 0 || self.gridColumns <= 0 || self.gridRows <= 0) {
        return;
    }
    
    CGFloat cellWidth = (overlayWidth - self.gridInsets.left - self.gridInsets.right - ((self.gridColumns - 1) * self.cellSpacing)) / self.gridColumns;
    CGFloat cellHeight = (overlayHeight - self.gridInsets.top - self.gridInsets.bottom - ((self.gridRows - 1) * self.cellSpacing)) / self.gridRows;
    
    // Safety check for negative cell sizes
    if (cellWidth <= 0 || cellHeight <= 0) {
        return;
    }
    
    CGFloat x = self.gridInsets.left + (position.x * (cellWidth + self.cellSpacing));
    CGFloat y = self.gridInsets.top + (position.y * (cellHeight + self.cellSpacing));
    CGFloat width = (size.width * cellWidth) + ((size.width - 1) * self.cellSpacing);
    CGFloat height = (size.height * cellHeight) + ((size.height - 1) * self.cellSpacing);
    
    CGRect highlightFrame = CGRectMake(x, y, width, height);
    
    // Ensure frame is within bounds
    if (CGRectIsEmpty(highlightFrame) || highlightFrame.size.width <= 0 || highlightFrame.size.height <= 0) {
        return;
    }
    
    // Create highlight view
    UIView *highlight = [[UIView alloc] initWithFrame:highlightFrame];
    highlight.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.3];
    highlight.layer.borderWidth = 2.0;
    highlight.layer.borderColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.8].CGColor;
    highlight.layer.cornerRadius = 4.0;
    highlight.tag = 999; // Tag for easy removal
    
    [self.gridOverlayView addSubview:highlight];
    
    // Add size label only if the highlight is large enough
    if (highlight.frame.size.width >= 60 && highlight.frame.size.height >= 30) {
        UILabel *sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, MIN(highlight.frame.size.width, 80), 30)];
        sizeLabel.text = [NSString stringWithFormat:@"%.0fx%.0f", size.width, size.height];
        sizeLabel.textAlignment = NSTextAlignmentCenter;
        sizeLabel.font = [UIFont boldSystemFontOfSize:14];
        sizeLabel.textColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
        sizeLabel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
        sizeLabel.layer.cornerRadius = 4.0;
        sizeLabel.layer.masksToBounds = YES;
        
        // Center the label
        CGPoint center = CGPointMake(highlight.frame.size.width / 2, highlight.frame.size.height / 2);
        sizeLabel.center = center;
        
        [highlight addSubview:sizeLabel];
    }
    
    // Animate highlight
    highlight.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.2 animations:^{
        highlight.transform = CGAffineTransformIdentity;
    }];
}

- (CGPoint)gridPositionFromTouchPoint:(CGPoint)point inCollectionView:(UICollectionView *)collectionView {
    // Convert the touch point to a grid position considering the collection view's content offset
    CGPoint adjustedPoint = CGPointMake(point.x + collectionView.contentOffset.x, 
                                       point.y + collectionView.contentOffset.y);
    return [self gridPositionFromPoint:adjustedPoint];
}

- (CGPoint)gridPositionForEmptySlotAtIndexPath:(NSIndexPath *)indexPath {
    NSValue *positionValue = self.emptySlotGridPositions[indexPath];
    if (positionValue) {
        return [positionValue CGPointValue];
    }
    return CGPointMake(-1, -1); // Invalid position
}

@end