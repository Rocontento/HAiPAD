//
//  AlarmControlPanelView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "AlarmControlPanelView.h"

@implementation AlarmControlPanelView

- (void)setupEntitySpecificUI {
    // TODO: Implement specific UI for AlarmControlPanelView
    // For now, fallback to basic sensor display
    
    // Create a placeholder label
    UILabel *placeholderLabel = [[UILabel alloc] init];
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    placeholderLabel.text = @"AlarmControlPanelView";
    placeholderLabel.font = [UIFont systemFontOfSize:16];
    placeholderLabel.textColor = [UIColor grayColor];
    placeholderLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardContainer addSubview:placeholderLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [placeholderLabel.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [placeholderLabel.centerYAnchor constraintEqualToAnchor:self.cardContainer.centerYAnchor constant:-10]
    ]];
}

@end
