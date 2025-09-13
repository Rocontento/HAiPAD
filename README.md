# HAiPAD

HAiPAD is an iOS 9.3.5 compatible Home Assistant dashboard application that connects directly to your local Home Assistant instance.

## Features

- **iOS 9.3.5 Compatible**: Designed specifically to work with older iPad devices running iOS 9.3.5
- **Local Connection**: Connects directly to your Home Assistant instance on your local network
- **Dashboard View**: Display and control entities like lights, switches, sensors, and more
- **Real-time Updates**: Fetch current states from Home Assistant API
- **Simple Configuration**: Easy setup with URL and access token
- **Entity Control**: Toggle lights, switches, and other controllable entities directly from the app

## Setup

### Prerequisites

1. **Home Assistant Instance**: You need a running Home Assistant instance accessible on your local network
2. **Long-lived Access Token**: Create a long-lived access token in Home Assistant
   - Go to your Home Assistant Profile → Long-Lived Access Tokens
   - Click "Create Token" and give it a name like "HAiPAD"
   - Copy the generated token

### Installation

1. Open the project in Xcode
2. Set the deployment target to iOS 9.3 or later
3. Build and run on your iOS device or simulator

### Configuration

1. Launch the HAiPAD app
2. Tap the "Config" button in the top-right corner
3. Enter your Home Assistant details:
   - **URL**: Your Home Assistant URL (e.g., `http://192.168.1.100:8123`)
   - **Access Token**: The long-lived access token you created
4. Tap "Test Connection" to verify the connection
5. Tap "Save" to store the configuration

## Usage

- The main screen shows a list of your Home Assistant entities
- Tap on lights, switches, or fans to toggle them on/off
- Pull down to refresh the entity states
- Tap the "ⓘ" button next to an entity to see detailed information
- Use the "Refresh" button to manually update entity states

## Supported Entity Types

The app displays and allows interaction with:
- **Lights** (`light.*`) - Toggle on/off
- **Switches** (`switch.*`) - Toggle on/off  
- **Fans** (`fan.*`) - Toggle on/off
- **Sensors** (`sensor.*`) - Read-only display
- **Binary Sensors** (`binary_sensor.*`) - Read-only display
- **Climate** (`climate.*`) - Read-only display
- **Covers** (`cover.*`) - Display only
- **Locks** (`lock.*`) - Display only

## Technical Details

- **Language**: Objective-C for maximum iOS 9.3.5 compatibility
- **Architecture**: MVC pattern with delegation
- **Networking**: NSURLSession for HTTP requests
- **Storage**: NSUserDefaults for configuration persistence
- **UI**: UIKit with Storyboards

## Troubleshooting

### Connection Issues

1. **Check Network**: Ensure your device is on the same network as Home Assistant
2. **Verify URL**: Make sure the URL is correct and accessible from your device
3. **Token Validity**: Ensure your long-lived access token is still valid
4. **HTTP vs HTTPS**: The app allows arbitrary loads for local connections

### App Transport Security

The app includes `NSAllowsArbitraryLoads` to support HTTP connections to local Home Assistant instances.

## License

This project is open source and available under the MIT License.