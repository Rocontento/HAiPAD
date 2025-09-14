# HAiPAD Whiteboard Usage Guide

## How to Use the New Whiteboard Feature

### Basic Interaction

**Normal Card Interaction:**
- **Single Tap**: Toggles lights, switches, fans (same as before)
- **Single Tap Info Button (ⓘ)**: Shows detailed entity information
- **Pull to Refresh**: Updates all entity states

### Whiteboard Features

**Moving Cards:**
1. **Long Press** any card for 0.5 seconds
2. Grid lines will appear to show available positions
3. **Drag** the card to your desired location
4. **Release** to snap the card to the nearest grid position
5. Grid lines will fade away automatically

**Grid Visibility:**
- **Double Tap** empty space to toggle grid lines on/off
- Grid helps you see available positions for cards
- Useful for planning your layout

### Visual Feedback

**During Drag:**
- Card scales up 10% and becomes slightly transparent
- Drop shadow appears for depth
- Grid overlay shows valid drop positions
- Card follows your finger smoothly

**Grid System:**
- 160x120 point cards with 20 point spacing
- Automatic snap-to-grid positioning
- Scrollable canvas larger than screen
- Support for both portrait and landscape

### Position Memory

- Card positions are automatically saved
- Positions persist between app launches
- Each entity remembers its custom position
- Reset by moving cards back to default positions

### Compatibility

**iOS 9.3.5 Features:**
- Uses legacy gesture recognizers for maximum compatibility
- Compatible shadow and animation APIs
- UserDefaults for simple persistence
- Works on original iPad models

**Performance:**
- Smooth 60fps dragging on older devices
- Efficient grid calculations
- Minimal memory usage
- Optimized for older hardware

### Tips for Best Experience

1. **Layout Planning**: Use double-tap to show grid, plan your layout
2. **Logical Grouping**: Group related devices (lights, sensors, etc.)
3. **Accessibility**: Keep frequently used controls easily reachable
4. **Visual Balance**: Distribute cards across the available space

### Troubleshooting

**If dragging feels unresponsive:**
- Make sure to hold for the full 0.5 seconds
- Try lifting your finger and trying again
- Check that you're not dragging too quickly

**If positions don't save:**
- Positions save automatically on successful drop
- Try force-closing and reopening the app
- Check iOS storage permissions

This whiteboard feature transforms HAiPAD into a truly customizable dashboard, similar to iOS 18 widgets, while maintaining full compatibility with older iPad devices.