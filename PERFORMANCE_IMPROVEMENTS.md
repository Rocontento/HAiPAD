# Real-time Performance Improvements

## Overview

HAiPAD now includes iOS 18 Home app-like real-time updates with configurable performance settings. The app responds instantly to user interactions and automatically shows changes made from other devices.

## Key Improvements

### ⚡ Instant Response Times
- **5x faster** service call response (1.5s → 0.3s)
- **Immediate visual feedback** on entity interactions
- **Optimistic UI updates** before server confirmation

### 🔄 Real-time Synchronization  
- **WebSocket connection** for instant updates
- **Automatic polling fallback** every 2 seconds
- **No manual refresh needed** - changes appear automatically

### 🎯 iOS 18 Home App Experience
- Sub-second update latency
- Smooth animations during state changes
- Seamless synchronization across devices
- Modern, responsive interface

## Configuration Options

Advanced users can customize performance via NSUserDefaults:

### Auto Refresh Interval
```objective-c
// Default: 2.0 seconds
[[NSUserDefaults standardUserDefaults] setDouble:1.0 forKey:@"ha_auto_refresh_interval"];
```

### Service Call Delay
```objective-c  
// Default: 0.3 seconds
[[NSUserDefaults standardUserDefaults] setDouble:0.1 forKey:@"ha_service_call_delay"];
```

### WebSocket Enable/Disable
```objective-c
// Default: YES
[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ha_websocket_enabled"];
```

## Performance Presets

### Maximum Performance
```objective-c
[defaults setDouble:1.0 forKey:@"ha_auto_refresh_interval"];  // 1s polling
[defaults setDouble:0.1 forKey:@"ha_service_call_delay"];     // 0.1s delay
[defaults setBool:YES forKey:@"ha_websocket_enabled"];        // WebSocket on
```

### Battery Saving
```objective-c
[defaults setDouble:5.0 forKey:@"ha_auto_refresh_interval"];  // 5s polling  
[defaults setDouble:0.5 forKey:@"ha_service_call_delay"];     // 0.5s delay
[defaults setBool:NO forKey:@"ha_websocket_enabled"];         // WebSocket off
```

## Testing the Improvements

1. **Instant Feedback**: Tap any light/switch - should change immediately
2. **Real-time Updates**: Change entity from another device - should appear within 1-2 seconds
3. **WebSocket Connection**: Check console for "WebSocket connected" message
4. **Smooth Performance**: No lag during normal operations

## Compatibility

### iOS Version Support

The real-time improvements are designed to work across all supported iOS versions:

- **iOS 13.0+**: Full WebSocket + HTTP polling for maximum performance
- **iOS 9.3-12.x**: HTTP polling only (WebSocket automatically disabled)
- **All versions**: Faster service call response and optimistic UI updates

### Automatic Fallback

The app automatically detects iOS version capabilities:

```objective-c
// WebSocket only available on iOS 13+
BOOL wsAvailable = [[HomeAssistantClient sharedClient] isWebSocketAvailable];
if (!wsAvailable) {
    NSLog(@"Using HTTP polling fallback for iOS < 13.0");
}
```

On older iOS versions, the app will:
- Log "WebSocket not available on iOS < 13.0, using HTTP polling only"
- Use faster HTTP polling (2-second intervals by default)
- Still provide 5x faster service call response times
- Maintain optimistic UI updates for instant feedback

## Troubleshooting

- **App crashes on iOS < 13**: Fixed with automatic WebSocket API detection
- **Slow updates**: Reduce auto refresh interval to 1.0 seconds
- **High battery usage**: Increase interval to 5.0 seconds or disable WebSocket
- **Connection issues**: Temporarily disable WebSocket, check Home Assistant logs

For detailed configuration guide, see the complete documentation in the project files.