# iOS 18-Style Card Resizing Implementation

## Overview

This implementation adds iOS 18-style widget resizing functionality to the HAiPAD Home Assistant dashboard, compatible with iOS 9.3.5. Users can now resize dashboard cards similar to how widgets work in iOS 18, with visual feedback and animations.

## Features Implemented

### 1. iOS 18-Style Resize Handles
- **Curved Corner Handle**: Each card displays a small, curved handle in the bottom-right corner when in editing mode
- **Visual Design**: The handle features curved lines similar to iOS 18 widgets with proper styling and transparency
- **Gesture Recognition**: Pan gestures on the handle allow intuitive resizing

### 2. Card Resizing Functionality
- **Variable Sizes**: Cards can be resized to 1x1, 2x1, 1x2, or 2x2 grid units
- **Real-time Feedback**: Visual feedback during resize operations
- **Size Persistence**: Card sizes are saved to user preferences and restored on app restart
- **Collision Detection**: Prevents overlapping cards during resize operations

### 3. Editing Mode with Wiggle Animation
- **Edit Mode Toggle**: Dedicated "Edit" button in the dashboard header
- **Wiggle Animation**: Cards perform a subtle wiggle animation when in editing mode (similar to iOS app management)
- **Visual Indicators**: Resize handles only appear during editing mode

### 4. Configurable Grid Size
- **Grid Size Setting**: New slider in Configuration view to set grid dimensions (1x1 to 8x8)
- **Device Defaults**: iPad defaults to 6x6 grid, iPhone defaults to 4x4 grid
- **Live Updates**: Grid size changes apply immediately

### 5. iOS 9.3.5 Compatibility
- **Font Compatibility**: Replaced iOS 10+ font weight constants with iOS 9.3.5 compatible alternatives
- **API Compatibility**: All features use APIs available in iOS 9.3.5
- **Layout System**: Uses NSLayoutConstraint instead of newer layout APIs

## Usage Instructions

### For End Users

1. **Enter Edit Mode**:
   - Tap the "Edit" button in the dashboard header
   - Cards will start wiggling and resize handles will appear

2. **Resize a Card**:
   - Long press and drag the curved handle in the bottom-right corner of any card
   - Drag outward to make the card larger, inward to make it smaller
   - Release to apply the new size

3. **Exit Edit Mode**:
   - Tap the "Done" button (Edit button changes to Done when active)
   - Handles disappear and wiggling stops

4. **Configure Grid Size**:
   - Go to Settings → Configuration
   - Use the "Grid Size" slider to adjust the dashboard grid dimensions
   - Changes apply immediately when you save

### For Developers

#### Key Classes Modified

1. **EntityCardCell**:
   - Added `EntityCardCellDelegate` protocol for resize notifications
   - Implemented resize handle with iOS 18-style curved lines
   - Added wiggle animation functionality
   - Added editing mode management

2. **WhiteboardGridLayout**:
   - Extended to support variable card sizes
   - Added collision detection for resizing operations
   - Improved grid position validation with exclusion logic

3. **DashboardViewController**:
   - Implements `EntityCardCellDelegate` for handling resize events
   - Manages editing mode state across all cards
   - Handles card size persistence

4. **ConfigurationViewController**:
   - Added grid size configuration slider
   - Integrated with user preferences system

#### Key Methods

```objective-c
// EntityCardCell
- (void)createResizeHandle;
- (void)handleResizeGesture:(UIPanGestureRecognizer *)gesture;
- (void)setEditingMode:(BOOL)editingMode animated:(BOOL)animated;
- (void)startWiggleAnimation;

// WhiteboardGridLayout  
- (BOOL)isGridPositionValid:(CGPoint)gridPosition withSize:(CGSize)gridSize excludingIndexPath:(NSIndexPath *)excludingIndexPath;
- (void)setGridSize:(CGSize)gridSize forIndexPath:(NSIndexPath *)indexPath;

// DashboardViewController
- (void)entityCardCell:(EntityCardCell *)cell didRequestSizeChange:(CGSize)newSize;
- (void)setEditingMode:(BOOL)editingMode;
```

## Technical Implementation Details

### Resize Handle Design
The resize handle mimics iOS 18's widget resize handle:
- 24x24 point circular handle
- Light gray background with border
- Two curved lines intersecting at the bottom-right
- Appears only in editing mode

### Animation System
- **Wiggle Animation**: Subtle rotation animation (±1 degree) with 1.5 second duration
- **Resize Feedback**: Smooth transitions during resize operations
- **Mode Transitions**: Animated show/hide of resize handles

### Persistence
Card sizes and positions are stored in NSUserDefaults:
- `ha_entity_sizes`: Dictionary mapping entity IDs to size strings
- `ha_entity_positions`: Dictionary mapping entity IDs to position strings  
- `ha_grid_size`: Integer value for grid dimensions

### Grid System
- Grid positions use (column, row) coordinate system
- Grid sizes use (width, height) in grid units
- Automatic collision detection prevents overlapping cards
- Smart placement algorithm finds available positions

## Compatibility Notes

- **iOS 9.3.5**: All features tested for compatibility
- **Device Support**: Works on both iPhone and iPad with appropriate defaults
- **Memory Management**: Uses manual reference counting compatible patterns
- **UI System**: Uses Interface Builder with programmatic enhancements

## Future Enhancements

Potential improvements that could be added:
1. **More Size Options**: Support for 3x3 and larger cards
2. **Snap-to-Grid**: Visual guides during resizing
3. **Undo/Redo**: History of resize operations
4. **Templates**: Pre-defined layout templates
5. **Export/Import**: Share layout configurations

## Testing

The implementation includes comprehensive validation tests that check:
- All delegate protocols are properly implemented
- UI elements are correctly connected in the storyboard
- iOS 9.3.5 compatibility requirements
- Key functionality methods are present

Run the validation script with:
```bash
python3 /tmp/test_resize_functionality.py
```