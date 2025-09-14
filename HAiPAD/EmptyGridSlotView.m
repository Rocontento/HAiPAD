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
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    self.layer.cornerRadius = 8.0;
    self.layer.masksToBounds = YES;
    
    // Add dashed border pattern (iOS 9.3.5 compatible approach)
    self.layer.lineDashPattern = @[@4, @4];
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
        [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0] : 
        [UIColor colorWithWhite:0.85 alpha:1.0];
    
    UIColor *backgroundColor = highlighted ?
        [UIColor colorWithRed:0.9 green:0.95 blue:1.0 alpha:0.5] :
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