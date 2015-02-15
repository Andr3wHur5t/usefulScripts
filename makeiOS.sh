#!/bin/bash
# Compiles code using autogen, and make into iOS architectures.

# Colors
Green='\033[0;32m'
Red='\033[0;31m'
Orange='\033[0;33m'
NC='\033[0m' # No Color


# This script will change the current path so keep a reference to the origin path
ORIGIN_PATH="${PWD}"

# Arguments used in the script
OUTPUT_DIR="${PWD}/iOS/"
SOURCE_DIR="${PWD}"
OUTPUT_NAME=""
CONFIGURE_SCRIPT_PATH=""
MAKE_DEVICE=0
MAKE_SIMULATOR=0
MIN_SDK="8.0"

# This shows help for the command
show_help () {
    echo -e "Compiles code using autogen, and make into iOS architectures";
    echo "Copyright (c) 2015 Andrew Hurst <andr3whur5t@live.com> under MIT license.";
    echo "    -h Shows help description of the script.";
    echo "    -d compiles for device architectures (armv7, armv7s, and arm64).";
    echo "    -s compiles for simulator architectures (x86_64, and i368).";
    echo "    -o The output folder.";
    echo "    -i The source folder.";
}

# This compiles the currently configured architecture


#need to set -miphoneos-version-min=${MIN_SDK}

## Compiler Config
# Static Configurations
CC_PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
PHONE_SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/"
SIM_SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/"
CC_FLAGS=" -Wno-error -Wno-implicit-function-declaration  -no-integrated-as"
OUTPUT_SUB_PATH="usr/local/lib/"
HEADER_PATH="/include"

# Process Input
while getopts "hvdsi:o:n:" opt; do
    case "$opt" in
        h)
            show_help
            exit 0
            ;;
        v)  verbose=$((verbose+1))
            ;;
        o)  OUTPUT_DIR=$OPTARG
            ;;
        i)  SOURCE_DIR=$OPTARG
            ;;
        n)  OUTPUT_NAME=$OPTARG
            ;;
        d)  MAKE_DEVICE=1
            ;;
        s)  MAKE_SIMULATOR=1
            ;;
        '?')
            show_help >&2
            exit 1
            ;;
    esac
done

# Validate Inputs
if [ "${SOURCE_DIR}" == "" ]; then
    echo -e "${Red}A source directory is required.${NC}";
    exit 1;
fi

if [ "${OUTPUT_DIR}" == "" ]; then
    echo -e "${Red}A output directory is required.${NC}";
    exit 1;
fi

if [ "${OUTPUT_NAME}" == "" ]; then
    echo -e "${Red}A output name is required.${NC}";
    exit 1;
fi

if [ "${MIN_SDK}" == "" ]; then
    echo -e "${Red}A min SDK version is required.${NC}";
    exit 1;
fi

# Detect Mode
if [ ${MAKE_DEVICE} -eq 0 ]; then if [ ${MAKE_SIMULATOR} -eq 0 ]; then
    # Inform the user that they should be explicit
    echo -e "${Orange}No modes specified building universal instead.${NC}";
    MAKE_DEVICE=1;
    MAKE_SIMULATOR=1;
fi
fi

# Set correct configurations
CONFIGURE_PATH="${SOURCE_DIR}/configure"
AUTOTOOL_SCRIPT_PATH="${SOURCE_DIR}/configure"

# Output Paths
INTERMEDIATE_DIR="${SOURCE_DIR}/Intermediates"
ARMV7_OUTPUT="${INTERMEDIATE_DIR}/armv7"
ARM64_OUTPUT="${INTERMEDIATE_DIR}/arm64"
SIM86_OUTPUT="${INTERMEDIATE_DIR}/x86_64"
SIM368_OUTPUT="${INTERMEDIATE_DIR}/i368"


# Enter source dir for make
echo -e "${Green}Entering source directory.${NC}"
cd "${SOURCE_DIR}"

# Check For Existence of configure script
if [ ! -f "${CONFIGURE_PATH}" ]; then
    echo -e "${Orange}Failed to find configure script Looking for autogen script.${NC}"
    if [ -f "${SOURCE_DIR}/autogen.sh" ]; then
        echo -e "${Green}Executing autogen script.${NC}"
        "${SOURCE_DIR}/autogen.sh"
    else
        echo -e "${Red}Failed to find configure, and autogen script aborting.${NC}"
        cd "${ORIGIN_PATH}"
        exit 1;
    fi
fi


# Prepare Intermediate Directory
if [ ! -d "${INTERMEDIATE_DIR}" ]; then
    echo -e "${Green}Making Intermediate Directory.${NC}"
    mkdir -p "${INTERMEDIATE_DIR}"
fi

# Make Device Architectures
if [ ${MAKE_DEVICE} -eq 1 ]; then

    # Run Configuration
    echo -e "${Green}Configuring armv7, and armv7s.${NC}"
    ARCH_STRING="-arch armv7s -arch armv7"
    CC_HOST="arm-apple-darwin"
    "${CONFIGURE_PATH}" CC="${CC_PATH}" CFLAGS="-isysroot ${PHONE_SDK_PATH}${CC_FLAGS} -miphoneos-version-min=${MIN_SDK} ${ARCH_STRING}" --host="${CC_HOST}" --enable-static --disable-shared

    echo -e "${Green}Making armv7, and armv7s.${NC}"
    make

    echo -e "${Green}Installing armv7, and armv7s in Intermediates.${NC}"
    make install DESTDIR="${ARMV7_OUTPUT}"

    echo -e "${Green}Purging generated files.${NC}"
    make distclean

    # Verify Output Exists
    echo "${ARMV7_OUTPUT}/${OUTPUT_SUB_PATH}${OUTPUT_NAME}"
    if [ -f "${ARMV7_OUTPUT}/${OUTPUT_SUB_PATH}${OUTPUT_NAME}" ]; then
        echo -e "${Green}Installation verified.${NC}";
    else
        echo -e "${Red}Failed to verify installation aborting.\nEnsure the entered name matches the output name.${NC}";
        cd "${ORIGIN_PATH}"
        exit 1;
    fi

    echo -e "${Orange}Skiping arm64.${NC}"
    # TODO: Make arm64 support
#    echo -e "${Green}Making arm64.${NC}"

    # Verify Output Exists
fi

if [ ${MAKE_SIMULATOR} -eq 1 ]; then
    # x86_64
    echo -e "${Green}Configuring x86_64.${NC}"
    ARCH_STRING="-arch x86_64"
    CC_HOST="x86_64-apple-darwin"
    "${CONFIGURE_PATH}" CC="${CC_PATH}" CFLAGS="-isysroot ${SIM_SDK_PATH}${CC_FLAGS} -miphoneos-version-min=${MIN_SDK} ${ARCH_STRING}" --host="${CC_HOST}" --enable-static --disable-shared

    echo -e "${Green}Making x86_64.${NC}"
    make

    echo -e "${Green}Installing x86_64 in Intermediates.${NC}"
    make install DESTDIR="${SIM86_OUTPUT}"

    echo -e "${Green}Purging generated files.${NC}"
    make distclean

    # Verify Output Exists
    if [ -f "${SIM86_OUTPUT}/${OUTPUT_SUB_PATH}${OUTPUT_NAME}" ]; then
        echo -e "${Green}Installation verified.${NC}";
    else
        echo -e "${Red}Failed to verify installation aborting.\nEnsure the entered name matches the output name.${NC}";
        cd "${ORIGIN_PATH}"
        exit 1;
    fi

    # i386
    echo -e "${Green}Configuring i386.${NC}"
    ARCH_STRING="-arch i386"
    CC_HOST="x86_64-apple-darwin"
    "${CONFIGURE_PATH}" CC="${CC_PATH}" CFLAGS="-isysroot ${SIM_SDK_PATH}${CC_FLAGS} -miphoneos-version-min=${MIN_SDK} ${ARCH_STRING}" --host="${CC_HOST}" --enable-static --disable-shared

    echo -e "${Green}Making i386.${NC}"
    make ARCH=i386

    echo -e "${Green}Installing i386 in Intermediates.${NC}"
    make install DESTDIR="${SIM368_OUTPUT}"

    echo -e "${Green}Purging generated files.${NC}"
    make distclean

    # Verify Output Exists
    if [ -f "${SIM368_OUTPUT}/${OUTPUT_SUB_PATH}${OUTPUT_NAME}" ]; then
        echo -e "${Green}Installation verified.${NC}";
    else
        echo -e "${Red}Failed to verify installation aborting.\nEnsure the entered name matches the output name.${NC}";
        cd "${ORIGIN_PATH}"
        exit 1;
    fi
fi


# Create Output Dirs
if [ ! -d "${OUTPUT_DIR}" ]; then
    echo -e "${Green}Creating output directory.${NC}"
    mkdir -p "${OUTPUT_DIR}/${HEADER_PATH}"

    # Verify That it was created
    if [ ! -d "${OUTPUT_DIR}/${HEADER_PATH}" ]; then
        echo -e "${Red}Failed to create output directory aborting.${NC}"
        exit 1;
    fi
fi

# Combine Built Objects
echo -e "${Green}Combining intermediates into a single fat file.${NC}"
lipo -create "${ARMV7_OUTPUT}/${OUTPUT_SUB_PATH}${OUTPUT_NAME}" "${SIM86_OUTPUT}/${OUTPUT_SUB_PATH}${OUTPUT_NAME}" "${SIM368_OUTPUT}/${OUTPUT_SUB_PATH}${OUTPUT_NAME}" -output "${OUTPUT_DIR}/${OUTPUT_NAME}"


if  [ -f "${OUTPUT_DIR}/${OUTPUT_NAME}" ]; then
    echo -e "${Green}Validated output.${NC}"
else
    echo -e "${Orange}Failed to validate output.${NC}"
fi

# Copy Headers
echo -e "${Green}Copying headers.${NC}"
cp -R "${ARMV7_OUTPUT}/${OUTPUT_SUB_PATH}..${HEADER_PATH}" "${OUTPUT_DIR}/${HEADER_PATH}"

# Clean up intermediates
echo -e "${Green}Cleaning up intermediates.${NC}"
rm -r "${INTERMEDIATE_DIR}"
if [ -d "${INTERMEDIATE_DIR}" ]; then
    echo -e "${Red}Failed to remove intermediate dir!${NC}";
    cd "${ORIGIN_PATH}"
    exit 1;
fi

xcrun -sdk iphoneos lipo -info "${OUTPUT_DIR}${OUTPUT_NAME}"
cd "${ORIGIN_PATH}"