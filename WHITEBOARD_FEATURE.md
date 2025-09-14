# HAiPAD Whiteboard Feature Implementation

## Overview
This document describes the implementation of the whiteboard-style dashboard feature that allows users to freely position Home Assistant entity cards on a grid-based layout, similar to iOS 18 widgets.

## Key Components

### 1. WhiteboardLayout.h/.m
Custom UICollectionViewLayout that replaces UICollectionViewFlowLayout:

**Key Features:**
- Grid-based positioning system
- Free positioning of cards within predetermined grid slots
- Snap-to-grid functionality
- Position persistence
- iOS 9.3.5 compatible implementation

**Key Methods:**
- `setPosition:forItemAtIndexPath:` - Sets position for a specific card
- `snapToGrid:` - Snaps coordinates to nearest grid position
- `availableGridPositions` - Returns available empty grid positions
- `isGridPositionOccupied:` - Checks if grid position is occupied

### 2. DashboardViewController Updates

**New Properties:**
- `whiteboardLayout` - Instance of WhiteboardLayout
- `longPressGesture` - For initiating drag operations
- `panGesture` - For handling drag movement
- `draggingIndexPath` - Currently dragging item
- `draggingView` - Visual representation during drag

**New Methods:**
- `setupGestureRecognizers` - Configures drag and drop gestures
- `handleLongPress:` - Initiates drag operation
- `handlePan:` - Handles drag movement
- `startDraggingItemAtIndexPath:withLocation:` - Begins drag operation
- `finishDragging:` - Completes drag operation with position save
- `loadCardPositions` / `saveCardPositions` - Position persistence

### 3. User Interaction Flow

1. **Normal Tap**: Toggles entity state (lights, switches, etc.)
2. **Long Press (0.5s)**: Initiates drag mode
   - Creates visual snapshot of card
   - Scales card up 1.1x with shadow
   - Enables pan gesture
3. **Drag**: Card follows finger movement
   - Visual feedback with shadow
   - Real-time position updates
4. **Drop**: Position snaps to nearest grid slot
   - Animates to final position
   - Saves position to UserDefaults
   - Updates layout

## Grid System

**Configuration:**
- Grid size: 160x120 points per card
- Grid spacing: 20 points between cards
- Margins: 20 points from edges
- Content area: Scrollable canvas larger than screen

**Position Calculation:**
- Grid coordinates are calculated based on touch position
- Positions snap to nearest valid grid intersection
- Grid accommodates both portrait and landscape orientations

## Persistence

Card positions are stored in NSUserDefaults with key `ha_card_positions`:
- Format: Dictionary of indexPath keys to [x, y] coordinate arrays
- Positions are loaded on app startup
- Positions are saved after each drag operation

## iOS 9.3.5 Compatibility

**Techniques Used:**
- `UILongPressGestureRecognizer` and `UIPanGestureRecognizer` for drag and drop
- `snapshotViewAfterScreenUpdates:` for visual feedback
- `CALayer` properties for shadows and visual effects
- `UIView` animation blocks for smooth transitions
- NSUserDefaults for simple persistence

**Avoided Modern APIs:**
- No drag and drop APIs (iOS 11+)
- No collection view interactive movement (iOS 9+)
- No advanced layout guides

## Benefits

1. **Flexible Layout**: Users can arrange cards however they prefer
2. **Visual Feedback**: Clear indication during drag operations
3. **Persistent**: Card positions are remembered between app launches
4. **Intuitive**: Similar to iOS home screen widget positioning
5. **Accessible**: Works with iOS 9.3.5 and older devices

## Usage Instructions

1. **View Cards**: Cards appear in default grid positions initially
2. **Move Card**: Long press any card for 0.5 seconds to enter drag mode
3. **Drag**: While in drag mode, move finger to desired position
4. **Drop**: Release finger to snap card to nearest grid position
5. **Interact**: Single tap cards to control devices (lights, switches, etc.)

The implementation provides a modern, iOS widget-like experience while maintaining compatibility with older iOS versions and preserving all existing Home Assistant functionality.