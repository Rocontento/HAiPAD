//
//  GridOverlayView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "GridOverlayView.h"

@implementation GridOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO; // Allow touches to pass through
        self.gridSize = CGSizeMake(160, 120);
        self.gridSpacing = 20;
        self.showGrid = NO;
        self.alpha = 0.0;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    if (!self.showGrid) return;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return;
    
    // Set grid line appearance
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.8 alpha:0.5].CGColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextSetLineDash(context, 0, (CGFloat[]){3.0, 3.0}, 2);
    
    // Calculate grid parameters
    CGFloat cellWidth = self.gridSize.width + self.gridSpacing;
    CGFloat cellHeight = self.gridSize.height + self.gridSpacing;
    CGFloat marginX = 20;
    CGFloat marginY = 20;
    
    // Draw vertical lines
    for (CGFloat x = marginX; x < rect.size.width; x += cellWidth) {
        CGContextMoveToPoint(context, x, 0);
        CGContextAddLineToPoint(context, x, rect.size.height);
    }
    
    // Draw horizontal lines
    for (CGFloat y = marginY; y < rect.size.height; y += cellHeight) {
        CGContextMoveToPoint(context, 0, y);
        CGContextAddLineToPoint(context, rect.size.width, y);
    }
    
    CGContextStrokePath(context);
    
    // Draw grid cells (optional - shows potential card positions)
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.9 alpha:0.2].CGColor);
    
    NSInteger maxColumns = (rect.size.width - 2 * marginX) / cellWidth;
    NSInteger maxRows = (rect.size.height - 2 * marginY) / cellHeight;
    
    for (NSInteger row = 0; row < maxRows; row++) {
        for (NSInteger col = 0; col < maxColumns; col++) {
            CGFloat x = marginX + (col * cellWidth);
            CGFloat y = marginY + (row * cellHeight);
            CGRect gridRect = CGRectMake(x, y, self.gridSize.width, self.gridSize.height);
            
            if (CGRectIntersectsRect(gridRect, rect)) {
                CGContextFillRect(context, gridRect);
            }
        }
    }
}

- (void)setGridVisible:(BOOL)visible animated:(BOOL)animated {
    self.showGrid = visible;
    [self setNeedsDisplay];
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = visible ? 1.0 : 0.0;
        }];
    } else {
        self.alpha = visible ? 1.0 : 0.0;
    }
}

- (void)setGridSize:(CGSize)gridSize {
    _gridSize = gridSize;
    [self setNeedsDisplay];
}

- (void)setGridSpacing:(CGFloat)gridSpacing {
    _gridSpacing = gridSpacing;
    [self setNeedsDisplay];
}

@end