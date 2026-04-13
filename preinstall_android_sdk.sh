#!/bin/bash

# --- 1. Project Selection ---
echo "Listing available Flutter projects..."
projects=( $(find . -maxdepth 2 -name "pubspec.yaml" -exec dirname {} \;) )

if [ ${#projects[@]} -eq 0 ]; then echo "No Flutter projects found!"; exit 1; fi
for i in "${!projects[@]}"; do echo "$i) ${projects[$i]}"; done
read -p "Select project index: " proj_idx
PROJECT_PATH=${projects[$proj_idx]}
cd "$PROJECT_PATH"

# --- 2. Dynamic Version Extraction ---
# Find Flutter SDK path from local.properties
FLUTTER_SDK_PATH=$(grep "flutter.sdk" android/local.properties | cut -d'=' -f2)
# The source of truth for "default" versions in Flutter
VERSION_FILE="$FLUTTER_SDK_PATH/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt"

extract_val() {
    local var_name=$1
    # Check project's build.gradle* first
    local val=$(grep "$var_name" android/app/build.gradle* | awk '{print $NF}' | tr -d '="' | xargs)
    
    # If project uses "flutter.compileSdkVersion", find the actual number in Flutter SDK
    if [[ "$val" == *"flutter."* ]] || [ -z "$val" ]; then
        local sdk_var=$(echo $val | cut -d'.' -f2)
        # Handle cases where project doesn't even have the line (use sdk default)
        [ -z "$sdk_var" ] && sdk_var="$var_name" 
        
        # This regex captures numbers inside quotes or raw integers from FlutterExtension.kt
        grep -P "$sdk_var.*=" "$VERSION_FILE" | head -1 | grep -oP '(?<==\s)("[^"]+"|[0-9.]+)' | tr -d ' "'
    else
        echo "$val"
    fi
}

# 3. Resolve actual versions
COMPILE_SDK=$(extract_val "compileSdkVersion")
[ -z "$COMPILE_SDK" ] && COMPILE_SDK=$(extract_val "compileSdk") # Support new Gradle syntax

# NDK is usually defined in the SDK if not in build.gradle
NDK_VERSION=$(extract_val "ndkVersion")

# CMake and BuildTools are often NOT in the Kotlin file. 
# We fetch the latest available if empty, which is the standard Android behavior.
BUILD_TOOLS=$(extract_val "buildToolsVersion")
[ -z "$BUILD_TOOLS" ] && BUILD_TOOLS="latest"

echo "--- Detected Requirements ---"
echo "Android SDK:  $COMPILE_SDK"
echo "Build Tools:  $BUILD_TOOLS"
echo "NDK Version:  ${NDK_VERSION:-[Not Specified]}"

# --- 4. Smart Installation ---
echo "Accepting licenses..."
yes | sdkmanager --licenses > /dev/null

# Build the install command dynamically
INSTALL_CMD="platforms;android-$COMPILE_SDK platform-tools"
[ "$BUILD_TOOLS" != "latest" ] && INSTALL_CMD="$INSTALL_CMD build-tools;$BUILD_TOOLS"
[ ! -z "$NDK_VERSION" ] && INSTALL_CMD="$INSTALL_CMD ndk;$NDK_VERSION"
# Flutter's current recommended CMake
INSTALL_CMD="$INSTALL_CMD cmake;3.22.1" 

echo "Running: sdkmanager $INSTALL_CMD"
sdkmanager $INSTALL_CMD

# --- 5. Final Preparation ---
flutter precache --android
flutter pub get

echo "Setup Complete. You can now build without internet downloads."
