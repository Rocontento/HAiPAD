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
    self.allowsReordering = YES;
    
    self.layoutAttributes = [NSMutableDictionary dictionary];
    self.occupiedPositions = [NSMutableSet set];
}

#pragma mark - UICollectionViewLayout Override Methods

- (void)prepareLayout {
    [super prepareLayout];
    
    [self.layoutAttributes removeAllObjects];
    [self.occupiedPositions removeAllObjects];
    
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
    
    // Calculate grid position
    NSInteger column = (NSInteger)(point.x / (self.cellSize.width + self.cellSpacing));
    NSInteger row = (NSInteger)(point.y / (self.cellSize.height + self.cellSpacing));
    
    // Clamp to grid bounds
    column = MAX(0, MIN(column, self.gridColumns - 1));
    row = MAX(0, MIN(row, self.gridRows - 1));
    
    return CGPointMake(column, row);
}

- (BOOL)isGridPositionValid:(CGPoint)gridPosition withSize:(CGSize)gridSize {
    // Check bounds
    if (gridPosition.x < 0 || gridPosition.y < 0) return NO;
    if (gridPosition.x + gridSize.width > self.gridColumns) return NO;
    if (gridPosition.y + gridSize.height > self.gridRows) return NO;
    
    // Check for overlaps with occupied positions
    for (NSInteger row = gridPosition.y; row < gridPosition.y + gridSize.height; row++) {
        for (NSInteger col = gridPosition.x; col < gridPosition.x + gridSize.width; col++) {
            NSString *positionKey = [NSString stringWithFormat:@"%ld-%ld", (long)col, (long)row];
            if ([self.occupiedPositions containsObject:positionKey]) {
                return NO;
            }
        }
    }
    
    return YES;
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

@end