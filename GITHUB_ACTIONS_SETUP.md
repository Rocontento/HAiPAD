# GitHub Actions CI/CD Setup for iOS

This document explains how to set up GitHub Actions for building and creating IPA files for the HAiPAD iOS application.

## 🚀 Quick Start

The GitHub Actions workflow is already configured and will automatically:
- ✅ Build the project for iOS Simulator
- ✅ Build the project for iOS Device (unsigned)
- ✅ Create unsigned IPA for development testing
- 🔐 Create signed IPA (when certificates are configured)

## 📋 Current Capabilities

### Without Apple Developer Account
- **Build Validation**: Ensures your code compiles successfully
- **Simulator Testing**: Builds that can run on iOS Simulator
- **Unsigned IPA**: Created for development reference (cannot install on devices)

### With Apple Developer Account (Optional Setup)
- **Signed IPA**: Ready for device installation and testing
- **Distribution**: Prepared for TestFlight or App Store
- **Automatic Signing**: Handles code signing in CI/CD

## 🔧 Basic Usage

The workflow triggers automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` branch
- Manual trigger via GitHub Actions tab

### Manual Trigger with IPA Creation
1. Go to **Actions** tab in your GitHub repository
2. Select **iOS Build and Archive** workflow
3. Click **Run workflow**
4. Check **"Create IPA file"** if you have signing certificates configured
5. Click **Run workflow**

## 🔐 Advanced Setup: Code Signing (Optional)

To create signed IPAs that can be installed on devices, you need to set up Apple Developer certificates.

### Prerequisites
- Active Apple Developer Account ($99/year)
- Xcode on a Mac for initial certificate generation
- Access to your repository settings

### Step 1: Generate Certificates and Provisioning Profiles

#### A. Create Distribution Certificate
1. Open **Keychain Access** on Mac
2. **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
3. Enter your email and name, select **"Saved to disk"**
4. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates)
5. Create new **iOS Distribution** certificate using the CSR file
6. Download the certificate (.cer file)
7. Double-click to install in Keychain Access

#### B. Export Certificate for CI
1. In **Keychain Access**, find your distribution certificate
2. Right-click → **Export**
3. Choose **Personal Information Exchange (.p12)**
4. Set a strong password (you'll need this for GitHub secrets)
5. Save the .p12 file

#### C. Create Provisioning Profile
1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/profiles)
2. Create new **Ad Hoc** or **App Store** profile
3. Select your App ID (or create one matching `com.haipad.homeassistant`)
4. Choose your distribution certificate
5. Select devices (for Ad Hoc) or skip (for App Store)
6. Download the .mobileprovision file

### Step 2: Configure GitHub Secrets

Go to your repository **Settings** → **Secrets and variables** → **Actions** and add:

| Secret Name | Description | How to Get Value |
|-------------|-------------|------------------|
| `APPLE_CERTIFICATE_BASE64` | Base64 encoded .p12 certificate | `base64 -i YourCertificate.p12 \| pbcopy` |
| `APPLE_CERTIFICATE_PASSWORD` | Password for .p12 certificate | The password you set when exporting |
| `PROVISIONING_PROFILE_BASE64` | Base64 encoded .mobileprovision | `base64 -i YourProfile.mobileprovision \| pbcopy` |
| `APPLE_TEAM_ID` | Your Apple Developer Team ID | Found in Apple Developer Portal |

#### Getting Base64 Values (Mac/Linux):
```bash
# For certificate
base64 -i YourCertificate.p12 | pbcopy

# For provisioning profile  
base64 -i YourProfile.mobileprovision | pbcopy
```

#### Getting Base64 Values (Windows):
```powershell
# For certificate
[Convert]::ToBase64String([IO.File]::ReadAllBytes("YourCertificate.p12")) | Set-Clipboard

# For provisioning profile
[Convert]::ToBase64String([IO.File]::ReadAllBytes("YourProfile.mobileprovision")) | Set-Clipboard
```

### Step 3: Update Bundle Identifier (if needed)

If your App ID differs from `com.haipad.homeassistant`, update it in:
1. **HAiPAD.xcodeproj** → **Build Settings** → **Product Bundle Identifier**
2. Make sure it matches your provisioning profile

## 📱 Workflow Outputs

### Build Artifacts
The workflow creates downloadable artifacts:
- **HAiPAD-unsigned.ipa**: For development reference
- **HAiPAD.ipa**: Signed version (when certificates configured)
- **dSYM files**: For crash symbolication

### Accessing Artifacts
1. Go to **Actions** tab
2. Click on a completed workflow run
3. Scroll down to **Artifacts** section
4. Download **ios-build-artifacts.zip**

## 🔍 Troubleshooting

### Common Issues

#### "No code signing identity found"
- **Cause**: Missing or incorrect certificates
- **Solution**: Verify `APPLE_CERTIFICATE_BASE64` and `APPLE_CERTIFICATE_PASSWORD` secrets

#### "No provisioning profile found"
- **Cause**: Missing or incorrect provisioning profile
- **Solution**: Verify `PROVISIONING_PROFILE_BASE64` secret and bundle identifier match

#### "Build failed for iOS device"
- **Cause**: Code signing issues or deployment target mismatch
- **Solution**: Check Xcode project settings and ensure iOS 9.3+ compatibility

#### Workflow doesn't trigger
- **Cause**: Workflow file syntax or permissions
- **Solution**: Check YAML syntax and repository permissions

### Debug Steps
1. Check **Actions** tab for detailed logs
2. Look for red ❌ steps in the workflow
3. Expand failed steps to see error messages
4. Compare your setup with the requirements above

## 🔄 Workflow Customization

### Changing Triggers
Edit `.github/workflows/ios-build.yml`:
```yaml
on:
  push:
    branches: [ main, develop, feature/* ]  # Add more branches
  schedule:
    - cron: '0 2 * * 1'  # Weekly builds on Monday 2AM
```

### Different Export Methods
Update `ExportOptions.plist` in the workflow:
- `ad-hoc`: For device testing
- `app-store`: For App Store submission
- `enterprise`: For enterprise distribution

### Custom Build Settings
Modify the `xcodebuild` commands to add custom flags:
```yaml
xcodebuild \
  -project "${{ env.XCODE_PROJECT }}" \
  -scheme "${{ env.SCHEME }}" \
  -configuration "${{ env.CONFIGURATION }}" \
  ENABLE_BITCODE=NO \
  SWIFT_VERSION=5.0
```

## 📚 Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [GitHub Actions for iOS](https://docs.github.com/en/actions/guides/building-and-testing-ios)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review GitHub Actions logs for specific error messages
3. Ensure all prerequisites are met
4. Verify secret values are correctly encoded

The workflow is designed to be informative - check the build summary in each run for specific guidance on next steps.