# Use Debian Bookworm slim image for a smaller footprint
FROM debian:bookworm-slim

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install system utilities, Java (JDK 17), and build dependencies
RUN apt-get update -y && apt-get install -y \
    # Core utilities and build tools
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    # Headless JDK for Android builds
    openjdk-17-jdk-headless \
    # Android Debug Bridge
    adb \
    # Clean up apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/*

# 2. Configure Android SDK and Flutter environment variables
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:/opt/flutter/bin"

# 3. Download and install Android Command Line Tools (v11076708)
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && curl -o sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip sdk.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm sdk.zip

# 4. Accept Android SDK licenses
RUN yes | sdkmanager --licenses

# 5. Install Flutter SDK (Stable channel)
RUN git clone https://github.com/flutter/flutter.git -b stable /opt/flutter

# Ensure tar operations don't run into permission/UID mapping issues
ENV TAR_OPTIONS="--no-same-owner"

# 6. Pre-download Flutter dependencies and perform a diagnostic check
RUN flutter doctor -v

# Set the default working directory
WORKDIR /workspaces
