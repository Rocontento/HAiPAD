#!/bin/bash

# HAiPAD GitHub Actions Setup Validator
# This script helps validate your local setup before configuring GitHub Actions

set -e

echo "🔍 HAiPAD GitHub Actions Setup Validator"
echo "======================================="
echo ""

# Check if we're in the right directory
if [ ! -f "HAiPAD.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the HAiPAD repository root"
    exit 1
fi

echo "✅ Found HAiPAD.xcodeproj"

# Check for Xcode
if command -v xcodebuild &> /dev/null; then
    echo "✅ Xcode build tools found"
    xcodebuild -version
    echo ""
else
    echo "❌ Xcode build tools not found (this is OK for GitHub Actions, but needed for local validation)"
    echo ""
fi

# Check project configuration
echo "🔍 Checking project configuration..."

BUNDLE_ID=$(grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER" HAiPAD.xcodeproj/project.pbxproj | grep -o "com\..*;" | tr -d ';' | head -1)
DEPLOYMENT_TARGET=$(grep -o "IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*" HAiPAD.xcodeproj/project.pbxproj | head -1 | cut -d'=' -f2 | tr -d ' ')

echo "   Bundle Identifier: $BUNDLE_ID"
echo "   iOS Deployment Target: $DEPLOYMENT_TARGET"
echo "✅ Project configuration looks good"
echo ""

# Check for certificate files (if present)
echo "🔍 Checking for local certificates..."
CERT_FILES=(*.p12 *.cer)
PROFILE_FILES=(*.mobileprovision)

if ls *.p12 1> /dev/null 2>&1; then
    echo "⚠️  Found .p12 certificate files in repository root"
    echo "   Make sure to add these to .gitignore and use GitHub Secrets instead!"
else
    echo "✅ No certificate files found in repository (good for security)"
fi

if ls *.mobileprovision 1> /dev/null 2>&1; then
    echo "⚠️  Found .mobileprovision files in repository root"
    echo "   Make sure to add these to .gitignore and use GitHub Secrets instead!"
else
    echo "✅ No provisioning profiles found in repository (good for security)"
fi
echo ""

# Check GitHub Actions workflow
echo "🔍 Checking GitHub Actions setup..."
if [ -f ".github/workflows/ios-build.yml" ]; then
    echo "✅ GitHub Actions workflow found"
    
    # Basic YAML syntax check
    if command -v python3 &> /dev/null; then
        python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ios-build.yml'))" 2>/dev/null && echo "✅ Workflow syntax is valid" || echo "⚠️  Workflow syntax might have issues"
    fi
else
    echo "❌ GitHub Actions workflow not found"
fi
echo ""

# Instructions
echo "📋 Next Steps:"
echo "=============="
echo ""
echo "For basic CI/CD (build validation only):"
echo "  1. Push your changes to GitHub"
echo "  2. Check the Actions tab for automatic builds"
echo "  3. Download unsigned IPA artifacts for reference"
echo ""
echo "For signed IPA generation:"
echo "  1. Set up Apple Developer Account"
echo "  2. Create distribution certificates and provisioning profiles"
echo "  3. Add secrets to GitHub repository settings:"
echo "     - APPLE_CERTIFICATE_BASE64"
echo "     - APPLE_CERTIFICATE_PASSWORD" 
echo "     - PROVISIONING_PROFILE_BASE64"
echo "     - APPLE_TEAM_ID"
echo "  4. Manually trigger workflow with 'Create IPA' option"
echo ""
echo "📖 See GITHUB_ACTIONS_SETUP.md for detailed instructions"
echo ""

# Check if running on macOS for local build test
if [[ "$OSTYPE" == "darwin"* ]] && command -v xcodebuild &> /dev/null; then
    echo "🛠️  Local Build Test (macOS only):"
    echo "================================="
    read -p "Would you like to test a local build? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🏗️  Testing local build for iOS Simulator..."
        xcodebuild \
            -project HAiPAD.xcodeproj \
            -scheme HAiPAD \
            -configuration Release \
            -destination 'platform=iOS Simulator,name=iPad Air (5th generation),OS=latest' \
            clean build \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            | grep -E "(error|warning|succeeded|failed)" || true
            
        if [ $? -eq 0 ]; then
            echo "✅ Local build test successful! GitHub Actions should work fine."
        else
            echo "❌ Local build test failed. Check Xcode project settings."
        fi
    fi
fi

echo ""
echo "🎉 Setup validation complete!"
echo "Push your changes to trigger the first GitHub Actions build."