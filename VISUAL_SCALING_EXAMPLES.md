# Visual Examples of iOS-like Background Image Scaling

## How the Algorithm Works

The new algorithm ensures ANY image fills the entire screen by using `MAX(scaleX, scaleY)` and perfect centering, just like iOS wallpaper selection.

## Example 1: Wide Image (HD Video 1920x1080) on iPad (1024x768)

```
Original Image (1920x1080):
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                        HD VIDEO                             │
│                     (wide format)                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘

iPad Screen (1024x768):
┌─────────────────────────────┐
│                             │
│           SCREEN            │
│                             │
└─────────────────────────────┘

After iOS-like Scaling (fills height, crops width):
┌─────────────────────────────┐
│         HD VIDEO            │ <- Image fills entire screen
│       (wide format)         │    Excess width is cropped
│                             │    symmetrically
└─────────────────────────────┘
Scale used: 0.7111 (screen_height / image_height)
Final size: 1365x768 (crops 341px from each side)
```

## Example 2: Tall Image (Portrait 1080x1920) on iPad (1024x768)

```
Original Image (1080x1920):
┌──────────────────┐
│                  │
│                  │
│    PORTRAIT      │
│     PHOTO        │
│   (tall format)  │
│                  │
│                  │
│                  │
│                  │
└──────────────────┘

iPad Screen (1024x768):
┌─────────────────────────────┐
│                             │
│           SCREEN            │
│                             │
└─────────────────────────────┘

After iOS-like Scaling (fills width, crops height):
┌─────────────────────────────┐
│       PORTRAIT PHOTO        │ <- Image fills entire screen
│      (tall format)          │    Excess height is cropped
│                             │    symmetrically
└─────────────────────────────┘
Scale used: 0.9481 (screen_width / image_width)
Final size: 1024x1820 (crops 526px from top and bottom)
```

## Example 3: Square Image (2000x2000) on iPhone Portrait (375x667)

```
Original Image (2000x2000):
┌─────────────────────┐
│                     │
│      SQUARE         │
│      IMAGE          │
│                     │
└─────────────────────┘

iPhone Screen (375x667):
┌──────────────┐
│              │
│    SCREEN    │
│   (portrait) │
│              │
│              │
└──────────────┘

After iOS-like Scaling (fills height, crops width):
┌──────────────┐
│  SQUARE IMG  │ <- Image fills entire screen
│              │    Excess width is cropped
│              │    symmetrically  
│              │
│              │
└──────────────┘
Scale used: 0.3335 (screen_height / image_height)
Final size: 667x667 (crops 146px from each side)
```

## Key Benefits

### ✅ Always Fills Screen
- No black bars or empty space
- Consistent behavior regardless of image aspect ratio
- Perfect for dashboard backgrounds

### ✅ Smart Cropping
- Excess content is cropped symmetrically
- Most important part (center) always visible
- User can adjust positioning in preview

### ✅ iOS-like Experience
- Matches familiar wallpaper selection behavior
- Preview shows exactly what user will see
- Intuitive zoom and pan controls

### ✅ Handles All Cases
- Tiny images: Scaled up to fill screen
- Huge images: Scaled down efficiently
- Wide images: Height fills, width crops
- Tall images: Width fills, height crops
- Square images: Fills larger dimension
- Extreme ratios: Still fills completely

## Implementation Details

The algorithm is implemented in two key places:

1. **DashboardViewController.m** - `applyBackgroundImage` method
   - Applies the final background to the dashboard
   - Uses saved positioning or smart defaults

2. **ImagePreviewViewController.m** - `setupZoom` method
   - Provides iOS-like preview experience
   - Starts with fill-screen scale
   - Allows user adjustment

Both use the same core principle:
```objective-c
CGFloat scaleX = viewSize.width / imageSize.width;
CGFloat scaleY = viewSize.height / imageSize.height;
CGFloat fillScale = MAX(scaleX, scaleY); // Key: use MAX for coverage
```

This ensures **ANY** image will **ALWAYS** fill the **ENTIRE** screen, just like iOS wallpapers!