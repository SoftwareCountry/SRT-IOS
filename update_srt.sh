#!/bin/sh

OPENSSL_DIR_NAME="OpenSSL"
SRT_DIR_NAME="SRT"

clean()
{
    cleanOpenSSL
    cleanSRT
}

cleanOpenSSL()
{
    echo "Remove Open SSL..."
    if [ -d "$OPENSSL_PATH" ]; then
        rm -rf "$OPENSSL_PATH"
    fi
}

cleanSRT()
{
    echo "Remove SRT..."
    if [ -d "$SRT_PATH" ]; then
        rm -rf "$SRT_PATH"
    fi
}

gitCloneOpenSSL()
{
    echo "Get OpenSSL sources..."
    git clone https://github.com/x2on/OpenSSL-for-iPhone.git "$OPENSSL_DIR_NAME"
}

gitCloneSRT()
{
    echo "Get SRT sources..."
    git clone https://github.com/Haivision/srt.git -b "$SRT_VERSION" "$SRT_DIR_NAME"
}

buildOpenSSL()
{
    echo "Build OpenSSL..."
    cd "$OPENSSL_PATH"
    
    ./build-libssl.sh --cleanup --targets="ios-sim-cross-x86_64 ios64-cross-arm64"
    
    cd "$CURRENT_PATH"
}

buildSRT()
{
    if [ -d "$SRT_PATH/bin" ]; then
        rm -rf "$SRT_PATH/bin"
    fi
    
    IOS_SDKVERSION=$(xcrun -sdk iphoneos --show-sdk-version)
    
    IOS_OPENSSL_SDK="$OPENSSL_PATH/bin/iPhoneOS$IOS_SDKVERSION-arm64.sdk"
    IOS_SIM_OPENSSL_SDK="$OPENSSL_PATH/bin/iPhoneSimulator$IOS_SDKVERSION-x86_64.sdk"
    
    # Fix SRT/scripts/iOS.cmake to set required iOS target version
    sed -i'' -e "s/CMAKE_OSX_DEPLOYMENT_TARGET \"\"/CMAKE_OSX_DEPLOYMENT_TARGET \"$IOS_TARGET_VERSION\"/g" "$SRT_PATH/scripts/iOS.cmake"
    
    echo "Build SRT for ARM64 iOS device..."
    mkdir -p "$SRT_PATH/bin/arm64"
    cd "$SRT_PATH/bin/arm64"
    ../../configure --cmake-prefix-path="$IOS_OPENSSL_SDK" --use-openssl-pc=OFF --cmake-toolchain-file=scripts/iOS.cmake --ios-platform=OS --ios-arch=arm64
    make
    mkdir "${SRT_PATH}/bin/arm64/headers"
    cp -a "${SRT_PATH}/bin/arm64/version.h" "${SRT_PATH}/bin/arm64/headers"
    cp -a "${SRT_PATH}/srtcore"/*.h "${SRT_PATH}/bin/arm64/headers"
    cp -a "${SRT_PATH}/haicrypt"/*.h "${SRT_PATH}/bin/arm64/headers"
    
    echo "Build SRT for iOS simulator..."
    mkdir -p "$SRT_PATH/bin/sim64"
    cd "$SRT_PATH/bin/sim64"
    ../../configure --cmake-prefix-path="$IOS_SIM_OPENSSL_SDK" --use-openssl-pc=OFF --cmake-toolchain-file=scripts/iOS.cmake --ios-platform=SIMULATOR64
    make
    mkdir "${SRT_PATH}/bin/sim64/headers"
    cp -a "${SRT_PATH}/bin/sim64/version.h" "${SRT_PATH}/bin/sim64/headers"
    cp -a "${SRT_PATH}/srtcore"/*.h "${SRT_PATH}/bin/sim64/headers"
    cp -a "${SRT_PATH}/haicrypt"/*.h "${SRT_PATH}/bin/sim64/headers"
}

buildUniversal()
{
    echo "Create universal SRT lib..."
    mkdir -p "$SRT_PATH/bin/universal"
    lipo -create "$SRT_PATH/bin/arm64/libsrt.a" "$SRT_PATH/bin/sim64/libsrt.a" -output "$SRT_PATH/bin/universal/libsrt.a"
    mkdir "${SRT_PATH}/bin/universal/headers"
    cp -a "${SRT_PATH}/bin/arm64/headers/" "${SRT_PATH}/bin/universal/headers"
}

createXcframework()
{
    if [ -d "${CURRENT_PATH}/SRT-IOS/XCFrameworks/libsrt.xcframework" ]; then
        rm -rf "${CURRENT_PATH}/SRT-IOS/XCFrameworks/libsrt.xcframework"
    fi

    mkdir -p "${CURRENT_PATH}/SRT-IOS/XCFrameworks"

    xcodebuild -create-xcframework \
    -library "${SRT_PATH}/bin/arm64/libsrt.a" -headers "${SRT_PATH}/bin/arm64/headers" \
    -library "${SRT_PATH}/bin/sim64/libsrt.a" -headers "${SRT_PATH}/bin/sim64/headers" \
    -output "${CURRENT_PATH}/SRT-IOS/XCFrameworks/libsrt.xcframework"
}

createFramework()
{
    if [ -d "${CURRENT_PATH}/SRT-IOS/Frameworks/srt.framework" ]; then
        rm -rf "${CURRENT_PATH}/SRT-IOS/Frameworks/srt.framework"
    fi
    
    local FRAMEWORK_PATH="${CURRENT_PATH}/SRT-IOS/Frameworks/srt.framework"
    
    mkdir -p "${FRAMEWORK_PATH}/Versions/A/Headers"
    
    ln -sfh A "${FRAMEWORK_PATH}/Versions/Current"
    ln -sfh Versions/Current/Headers "${FRAMEWORK_PATH}/Headers"
    ln -sfh Versions/Current/srt "${FRAMEWORK_PATH}/srt"
    
    cp -a "${SRT_PATH}/bin/arm64/version.h" "${FRAMEWORK_PATH}/Versions/A/Headers"
    cp -a "${SRT_PATH}/srtcore"/*.h "${FRAMEWORK_PATH}/Versions/A/Headers"
    cp -a "${SRT_PATH}/haicrypt"/*.h "${FRAMEWORK_PATH}/Versions/A/Headers"
    
    cp "${SRT_PATH}/bin/universal/libsrt.a" "${FRAMEWORK_PATH}/Versions/A/srt"
}

printCorrectExample()
{
    echo "Example: sh srt.sh --srt-version=\"v1.4.4\" --ios-target-version=\"13.0\" --clean-after"
}

CURRENT_PATH=$(pwd)
OPENSSL_PATH="$CURRENT_PATH/$OPENSSL_DIR_NAME"
SRT_PATH="$CURRENT_PATH/$SRT_DIR_NAME"

SRT_VERSION=""
IOS_TARGET_VERSION=""
CLEAN_AFTER=false

# Read options
for i in "$@"
do
    case $i in
        --srt-version=*)
            SRT_VERSION="${i#*=}"
            shift
        ;;
        --ios-target-version=*)
            IOS_TARGET_VERSION="${i#*=}"
            shift
        ;;
        --clean-after)
            CLEAN_AFTER=true
        ;;
        *)
            echo "Unknown argument: ${i}"
            printCorrectExample
            exit 1
        ;;
    esac
done

# Validate SRT version
if [ x$SRT_VERSION == x ]; then
    echo "Error: Empty SRT version. Use --srt-version option to set correct SRT version. As version value use tags names from SRT GitHub(https://github.com/Haivision/srt/releases)."
    printCorrectExample
    exit 1
fi

SRT_VERSION_COUNT=0
SRT_VERSION_COUNT=$(git ls-remote --tags https://github.com/Haivision/srt.git "$SRT_VERSION" | grep "$SRT_VERSION" -c)

if [ $SRT_VERSION_COUNT != 1 ]; then
    echo "Error: Invalid SRT version '$SRT_VERSION'. Use --srt-version option to set correct SRT version. As version value use tags names from SRT GitHub(https://github.com/Haivision/srt/releases)."
    printCorrectExample
    exit 1
fi

# Validate iOS target version
if [ x$IOS_TARGET_VERSION == x ]; then
    echo "Error: Empty iOS target version. Use --ios-target-version option to set iOS target version. You can find the correct value in your project settings. Copy it from the 'iOS Deployment Target'."
    printCorrectExample
    exit 1
fi

clean

gitCloneOpenSSL
buildOpenSSL

gitCloneSRT
buildSRT

buildUniversal
createFramework
createXcframework

if [ $CLEAN_AFTER == true ]; then
    echo "Clean all after build..."
    clean
fi