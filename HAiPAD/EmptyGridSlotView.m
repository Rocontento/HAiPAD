//
//  EmptyGridSlotView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "EmptyGridSlotView.h"

@implementation EmptyGridSlotView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupView];
}

- (void)setupView {
    self.backgroundColor = [UIColor clearColor];
    
    // Add subtle border to indicate drop zone
    self.layer.borderWidth = 2.0;
    self.layer.borderColor = [UIColor colorWithWhite:0.80 alpha:0.6].CGColor;
    self.layer.cornerRadius = 8.0;
    self.layer.masksToBounds = YES;
    
    // Create dashed border effect for iOS 9.3.5
    // Since we can't use layer.lineDashPattern directly on all iOS 9 versions,
    // we'll create a visual dashed effect using multiple sublayers
    [self createDashedBorderEffect];
    
    // Add a subtle plus icon to indicate this is a drop zone
    [self addPlusIcon];
}

- (void)createDashedBorderEffect {
    // Remove any existing border layers
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    // Create dashed appearance using multiple small border segments
    CGFloat dashLength = 8.0;
    CGFloat gapLength = 4.0;
    
    // We'll draw dashes around the perimeter
    CGRect bounds = self.bounds;
    if (CGRectIsEmpty(bounds)) {
        bounds = CGRectMake(0, 0, 100, 100); // Default size for initial setup
    }
    
    // For simplicity on iOS 9.3.5, we'll use a simpler approach:
    // A solid border with reduced opacity to create a subtle appearance
    self.layer.borderColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.3].CGColor;
}

- (void)addPlusIcon {
    // Add a subtle plus (+) icon in the center to indicate this is a drop zone
    UILabel *plusLabel = [[UILabel alloc] init];
    plusLabel.text = @"+";
    plusLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightLight];
    plusLabel.textColor = [UIColor colorWithWhite:0.7 alpha:0.6];
    plusLabel.textAlignment = NSTextAlignmentCenter;
    plusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:plusLabel];
    
    // Center the plus icon
    [self addConstraint:[NSLayoutConstraint constraintWithItem:plusLabel
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:plusLabel
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self setHighlighted:NO animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted {
    [self setHighlighted:highlighted animated:YES];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    _highlighted = highlighted;
    
    UIColor *borderColor = highlighted ? 
        [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.8] : 
        [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.3];
    
    UIColor *backgroundColor = highlighted ?
        [UIColor colorWithRed:0.9 green:0.95 blue:1.0 alpha:0.7] :
        [UIColor clearColor];
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.layer.borderColor = borderColor.CGColor;
            self.backgroundColor = backgroundColor;
        }];
    } else {
        self.layer.borderColor = borderColor.CGColor;
        self.backgroundColor = backgroundColor;
    }
}

@end