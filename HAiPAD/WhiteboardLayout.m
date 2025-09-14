//
//  WhiteboardLayout.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "WhiteboardLayout.h"

@interface WhiteboardLayout ()
@property (nonatomic, strong) NSMutableDictionary *layoutAttributes;
@property (nonatomic, assign) CGSize contentSize;
@end

@implementation WhiteboardLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        // Default grid configuration
        self.gridSize = CGSizeMake(160, 120); // Default card size
        self.gridSpacing = 20;
        self.itemPositions = [NSMutableDictionary dictionary];
        self.layoutAttributes = [NSMutableDictionary dictionary];
        
        // Initialize content size for iPad-like interface
        self.contentSize = CGSizeMake(1024, 768);
    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];
    
    // Clear existing layout attributes
    [self.layoutAttributes removeAllObjects];
    
    // Calculate content size based on collection view bounds
    if (self.collectionView) {
        CGFloat availableWidth = self.collectionView.bounds.size.width - 40; // 20px margin on each side
        CGFloat availableHeight = self.collectionView.bounds.size.height - 40;
        
        // Update content size to be larger than the visible area for scrolling
        self.contentSize = CGSizeMake(MAX(availableWidth, 800), MAX(availableHeight, 1000));
    }
    
    // Calculate layout attributes for each item
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
    
    for (NSInteger i = 0; i < numberOfItems; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        
        if (attributes) {
            self.layoutAttributes[indexPath] = attributes;
        }
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    // Get stored position or calculate default position
    CGPoint position = [self positionForItemAtIndexPath:indexPath];
    
    if (CGPointEqualToPoint(position, CGPointZero)) {
        // No stored position, calculate default grid position
        position = [self defaultPositionForItemAtIndex:indexPath.item];
        [self setPosition:position forItemAtIndexPath:indexPath];
    }
    
    // Set frame based on position and grid size
    attributes.frame = CGRectMake(position.x, position.y, self.gridSize.width, self.gridSize.height);
    
    return attributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attributesArray = [NSMutableArray array];
    
    for (UICollectionViewLayoutAttributes *attributes in self.layoutAttributes.allValues) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [attributesArray addObject:attributes];
        }
    }
    
    return attributesArray;
}

- (CGSize)collectionViewContentSize {
    return self.contentSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    // Only invalidate if the size changes significantly
    CGRect oldBounds = self.collectionView.bounds;
    return !CGSizeEqualToSize(oldBounds.size, newBounds.size);
}

#pragma mark - Position Management

- (void)setPosition:(CGPoint)position forItemAtIndexPath:(NSIndexPath *)indexPath {
    // Snap to grid
    CGPoint snappedPosition = [self snapToGrid:position];
    
    // Store position
    NSString *key = [NSString stringWithFormat:@"%ld-%ld", (long)indexPath.section, (long)indexPath.item];
    self.itemPositions[key] = [NSValue valueWithCGPoint:snappedPosition];
    
    // Invalidate layout for this item
    [self invalidateLayout];
}

- (CGPoint)positionForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *key = [NSString stringWithFormat:@"%ld-%ld", (long)indexPath.section, (long)indexPath.item];
    NSValue *positionValue = self.itemPositions[key];
    
    if (positionValue) {
        return [positionValue CGPointValue];
    }
    
    return CGPointZero; // Return zero point if no position is stored
}

- (CGPoint)snapToGrid:(CGPoint)position {
    // Calculate grid cell size including spacing
    CGFloat cellWidth = self.gridSize.width + self.gridSpacing;
    CGFloat cellHeight = self.gridSize.height + self.gridSpacing;
    
    // Add margin offset
    CGFloat marginX = 20;
    CGFloat marginY = 20;
    
    // Snap to nearest grid position
    NSInteger gridX = round((position.x - marginX) / cellWidth);
    NSInteger gridY = round((position.y - marginY) / cellHeight);
    
    // Ensure we don't go negative
    gridX = MAX(0, gridX);
    gridY = MAX(0, gridY);
    
    // Calculate final position
    CGFloat snappedX = marginX + (gridX * cellWidth);
    CGFloat snappedY = marginY + (gridY * cellHeight);
    
    return CGPointMake(snappedX, snappedY);
}

- (CGPoint)defaultPositionForItemAtIndex:(NSInteger)index {
    // Calculate default grid position for new items
    CGFloat cellWidth = self.gridSize.width + self.gridSpacing;
    CGFloat cellHeight = self.gridSize.height + self.gridSpacing;
    CGFloat marginX = 20;
    CGFloat marginY = 20;
    
    // Determine how many columns fit in the available width
    CGFloat availableWidth = self.collectionView.bounds.size.width - (2 * marginX);
    NSInteger columnsPerRow = MAX(1, (NSInteger)(availableWidth / cellWidth));
    
    // Calculate row and column for this index
    NSInteger row = index / columnsPerRow;
    NSInteger column = index % columnsPerRow;
    
    // Calculate position
    CGFloat x = marginX + (column * cellWidth);
    CGFloat y = marginY + (row * cellHeight);
    
    return CGPointMake(x, y);
}

- (NSArray *)availableGridPositions {
    NSMutableArray *positions = [NSMutableArray array];
    
    CGFloat cellWidth = self.gridSize.width + self.gridSpacing;
    CGFloat cellHeight = self.gridSize.height + self.gridSpacing;
    CGFloat marginX = 20;
    CGFloat marginY = 20;
    
    // Calculate available positions in the content area
    CGFloat availableWidth = self.contentSize.width - (2 * marginX);
    CGFloat availableHeight = self.contentSize.height - (2 * marginY);
    
    NSInteger maxColumns = (NSInteger)(availableWidth / cellWidth);
    NSInteger maxRows = (NSInteger)(availableHeight / cellHeight);
    
    for (NSInteger row = 0; row < maxRows; row++) {
        for (NSInteger col = 0; col < maxColumns; col++) {
            CGFloat x = marginX + (col * cellWidth);
            CGFloat y = marginY + (row * cellHeight);
            CGPoint position = CGPointMake(x, y);
            
            if (![self isGridPositionOccupied:position]) {
                [positions addObject:[NSValue valueWithCGPoint:position]];
            }
        }
    }
    
    return positions;
}

- (BOOL)isGridPositionOccupied:(CGPoint)gridPosition {
    for (NSValue *positionValue in self.itemPositions.allValues) {
        CGPoint occupiedPosition = [positionValue CGPointValue];
        if (CGPointEqualToPoint(occupiedPosition, gridPosition)) {
            return YES;
        }
    }
    return NO;
}

@end