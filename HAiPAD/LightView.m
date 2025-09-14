//
//  LightView.m
//  HAiPAD
//
//  Created on iOS Home Assistant Dashboard
//  Compatible with iOS 9.3.5
//

#import "LightView.h"
#import "UIColor+HAiPAD.h"

@implementation LightView

- (void)setupEntitySpecificUI {
    // Create toggle switch
    self.toggleSwitch = [[UISwitch alloc] init];
    self.toggleSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toggleSwitch addTarget:self action:@selector(toggleSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.cardContainer addSubview:self.toggleSwitch];
    
    // Create brightness slider
    self.brightnessSlider = [[UISlider alloc] init];
    self.brightnessSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.brightnessSlider.minimumValue = 0.0;
    self.brightnessSlider.maximumValue = 255.0;
    self.brightnessSlider.minimumTrackTintColor = [UIColor ha_systemYellowColor];
    [self.brightnessSlider addTarget:self action:@selector(brightnessSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.cardContainer addSubview:self.brightnessSlider];
    
    // Create brightness label
    self.brightnessLabel = [[UILabel alloc] init];
    self.brightnessLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.brightnessLabel.font = [UIFont systemFontOfSize:10];
    self.brightnessLabel.textColor = [UIColor grayColor];
    self.brightnessLabel.textAlignment = NSTextAlignmentCenter;
    self.brightnessLabel.text = @"Brightness";
    [self.cardContainer addSubview:self.brightnessLabel];
    
    // Create color preview
    self.colorPreview = [[UIView alloc] init];
    self.colorPreview.translatesAutoresizingMaskIntoConstraints = NO;
    self.colorPreview.backgroundColor = [UIColor ha_systemYellowColor];
    self.colorPreview.layer.cornerRadius = 8.0;
    self.colorPreview.layer.borderWidth = 1.0;
    self.colorPreview.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [self.cardContainer addSubview:self.colorPreview];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Toggle switch in top-right
        [self.toggleSwitch.topAnchor constraintEqualToAnchor:self.cardContainer.topAnchor constant:12],
        [self.toggleSwitch.trailingAnchor constraintEqualToAnchor:self.cardContainer.trailingAnchor constant:-12],
        
        // Color preview in top-left
        [self.colorPreview.topAnchor constraintEqualToAnchor:self.cardContainer.topAnchor constant:12],
        [self.colorPreview.leadingAnchor constraintEqualToAnchor:self.cardContainer.leadingAnchor constant:12],
        [self.colorPreview.widthAnchor constraintEqualToConstant:24],
        [self.colorPreview.heightAnchor constraintEqualToConstant:24],
        
        // Brightness label
        [self.brightnessLabel.centerXAnchor constraintEqualToAnchor:self.cardContainer.centerXAnchor],
        [self.brightnessLabel.bottomAnchor constraintEqualToAnchor:self.nameLabel.topAnchor constant:-4],
        
        // Brightness slider
        [self.brightnessSlider.leadingAnchor constraintEqualToAnchor:self.cardContainer.leadingAnchor constant:16],
        [self.brightnessSlider.trailingAnchor constraintEqualToAnchor:self.cardContainer.trailingAnchor constant:-16],
        [self.brightnessSlider.bottomAnchor constraintEqualToAnchor:self.brightnessLabel.topAnchor constant:-4]
    ]];
}

- (void)updateWithEntity:(NSDictionary *)entity {
    [super updateWithEntity:entity];
    
    NSString *state = [self state];
    BOOL isOn = [state isEqualToString:@"on"];
    
    self.toggleSwitch.on = isOn;
    
    // Update brightness
    NSNumber *brightness = [self attributes][@"brightness"];
    if (brightness) {
        self.brightnessSlider.value = brightness.floatValue;
        self.brightnessSlider.enabled = isOn;
        self.brightnessSlider.alpha = isOn ? 1.0 : 0.5;
        self.brightnessLabel.text = [NSString stringWithFormat:@"Brightness %d%%", (int)((brightness.floatValue / 255.0) * 100)];
    } else {
        self.brightnessSlider.enabled = NO;
        self.brightnessSlider.alpha = 0.5;
        self.brightnessLabel.text = @"Brightness";
    }
    
    // Update color preview
    NSArray *rgbColor = [self attributes][@"rgb_color"];
    if (rgbColor && rgbColor.count >= 3 && isOn) {
        UIColor *color = [UIColor colorWithRed:[rgbColor[0] floatValue]/255.0
                                        green:[rgbColor[1] floatValue]/255.0
                                         blue:[rgbColor[2] floatValue]/255.0
                                        alpha:1.0];
        self.colorPreview.backgroundColor = color;
    } else {
        self.colorPreview.backgroundColor = isOn ? [UIColor ha_systemYellowColor] : [UIColor lightGrayColor];
    }
    
    // Update state label
    if (isOn) {
        if (brightness) {
            self.stateLabel.text = [NSString stringWithFormat:@"On • %d%%", (int)((brightness.floatValue / 255.0) * 100)];
        } else {
            self.stateLabel.text = @"On";
        }
    } else {
        self.stateLabel.text = @"Off";
    }
}

- (UIColor *)colorForEntityState {
    NSString *state = [self state];
    if ([state isEqualToString:@"on"]) {
        return [UIColor colorWithRed:1.0 green:0.98 blue:0.85 alpha:1.0]; // Warm light color
    }
    return [UIColor whiteColor];
}

#pragma mark - Actions

- (void)toggleSwitchChanged:(UISwitch *)sender {
    NSString *service = sender.isOn ? @"turn_on" : @"turn_off";
    
    if ([self.delegate respondsToSelector:@selector(entityView:didRequestServiceCall:service:entityId:parameters:)]) {
        [self.delegate entityView:self didRequestServiceCall:@"light" service:service entityId:[self entityId] parameters:nil];
    }
}

- (void)brightnessSliderChanged:(UISlider *)sender {
    if (![self.toggleSwitch isOn]) {
        return; // Don't change brightness if light is off
    }
    
    NSDictionary *parameters = @{@"brightness": @((int)sender.value)};
    
    if ([self.delegate respondsToSelector:@selector(entityView:didRequestServiceCall:service:entityId:parameters:)]) {
        [self.delegate entityView:self didRequestServiceCall:@"light" service:@"turn_on" entityId:[self entityId] parameters:parameters];
    }
}

@end