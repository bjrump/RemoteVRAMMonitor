#!/bin/bash

APP_NAME="RemoteVRAMMonitor"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"

echo "Closing existing application..."
pkill -f "$APP_NAME"
sleep 1

echo "Cleaning build artifacts..."
swift package clean
rm -rf .build
rm -rf "$APP_BUNDLE"

echo "Building release version..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi

echo "Creating App Bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.github.bjrump.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "Done! App updated."
echo "You can now run: open $APP_BUNDLE"
