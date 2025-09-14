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

## Troubleshooting

- **Slow updates**: Reduce auto refresh interval to 1.0 seconds
- **High battery usage**: Increase interval to 5.0 seconds or disable WebSocket
- **Connection issues**: Temporarily disable WebSocket, check Home Assistant logs

For detailed configuration guide, see the complete documentation in the project files.