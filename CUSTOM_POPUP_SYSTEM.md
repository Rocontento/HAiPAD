# Custom Popup System

This document describes the custom popup system implemented to replace iOS system dialogs (UIAlertController) with a more modern, app-specific design that matches the Home Assistant app's card-based UI.

## Overview

The custom popup system provides a consistent, modern alternative to system dialogs that better integrates with the app's visual design. The popups feature:

- Semi-transparent background overlay (similar to Apple Home app)
- Modern card-style containers with rounded corners and shadows
- Smooth spring animations for presentation/dismissal
- Responsive layout that works on different screen sizes
- Support for multiple content types and interaction patterns
- Full iOS 9.3.5 compatibility

## Architecture

### CustomPopupViewController

The main popup view controller that handles:
- Background overlay with tap-to-dismiss functionality
- Popup container with modern card styling
- Content layout based on popup type
- Button management and actions
- Smooth animations

### Popup Types

1. **CustomPopupTypeInfo**: General information display (entity details, errors)
2. **CustomPopupTypeClimateControl**: Climate entity controls (temperature adjustment, on/off)
3. **CustomPopupTypeCoverControl**: Cover entity controls (open/close/stop)
4. **CustomPopupTypeLockControl**: Lock entity controls (lock/unlock)
5. **CustomPopupTypeSensorInfo**: Sensor information display (enhanced with timestamps)

### Button Styles

1. **CustomPopupButtonStylePrimary**: Blue background, white text (for primary actions)
2. **CustomPopupButtonStyleSecondary**: Light gray background, dark text (for secondary actions)
3. **CustomPopupButtonStyleCancel**: Darker gray background, gray text (for cancel actions)

## Usage Examples

### Basic Info Popup
```objc
NSDictionary *entity = // ... entity data
CustomPopupViewController *popup = [CustomPopupViewController popupWithEntity:entity
                                                                         type:CustomPopupTypeInfo
                                                                 actionHandler:nil];
[popup presentFromViewController:self animated:YES];
```

### Climate Control Popup
```objc
CustomPopupViewController *popup = [CustomPopupViewController popupWithEntity:entity
                                                                         type:CustomPopupTypeClimateControl
                                                                 actionHandler:^(NSString *action, NSDictionary *parameters) {
    if ([action isEqualToString:@"increase_temp"]) {
        NSNumber *temperature = parameters[@"temperature"];
        // Handle temperature increase
    }
    // Handle other actions...
}];
[popup presentFromViewController:self animated:YES];
```

## Design Features

### Visual Design
- **Background**: Semi-transparent black overlay (40% opacity)
- **Container**: White background with 16pt corner radius
- **Shadow**: Subtle shadow (20pt blur radius, 8pt offset)
- **Typography**: System font with appropriate weights
- **Buttons**: 44pt height with 8pt corner radius, proper spacing

### Animations
- **Presentation**: Spring animation with scale effect (0.8 to 1.0 scale)
- **Dismissal**: Quick fade out with slight scale down (0.9 scale)
- **Duration**: 0.3s for presentation, 0.2s for dismissal

### Layout
- **Maximum width**: 340pt
- **Minimum width**: 280pt
- **Maximum height**: 500pt (scrollable content)
- **Margins**: 20pt from screen edges
- **Content padding**: 20pt internal padding
- **Button spacing**: 12pt between buttons

## Replaced System Dialogs

The following UIAlertController instances have been replaced:

1. **DashboardViewController**:
   - Entity info display (info button taps)
   - Climate control interface
   - Cover control interface
   - Lock control interface
   - Sensor information display
   - Connection error alerts

2. **ConfigurationViewController**:
   - Validation error alerts (missing URL/token)

## Benefits Over System Dialogs

1. **Visual Consistency**: Matches the app's modern card-based design
2. **Better UX**: Larger touch targets, clearer visual hierarchy
3. **More Information**: Scrollable content allows for detailed information
4. **Custom Styling**: Can be themed to match app design
5. **Enhanced Animations**: Smooth spring animations vs basic fade
6. **Future Extensibility**: Easy to add new popup types and features

## iOS 9.3.5 Compatibility

The implementation uses only APIs available in iOS 9.3.5:
- UIKit Auto Layout with NSLayoutConstraint
- CALayer properties for shadows and rounded corners
- Standard UIView animation APIs
- UIFont system font with weight (available since iOS 8.2)
- Standard UIKit components throughout

## Future Enhancements

Potential improvements for future versions:
- Haptic feedback for user interactions
- More sophisticated animations
- Dark mode support
- Accessibility improvements
- Additional popup types for new entity types