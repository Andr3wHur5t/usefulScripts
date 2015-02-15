#!/bin/bash

# Colors
Black='\033[0;30m'
Blue='\033[0;34m'
Green='\033[0;32m'
Cyan='\033[0;36m'
Red='\033[0;31m'
Purple='\033[0;35m'
Orange='\033[0;33m'
LightGray='\033[0;37m'
NC='\033[0m' # No Color

# Arguments used in the script
OUTPUT_DISK=""
SOURCE_FILE=""
REMOVE_CONVERSION=1

# This shows help for the command
show_help () {
    echo "Mounts the inputed iso file to the output usb.";
    echo "Copyright (c) 2015 Andrew Hurst <andr3whur5t@live.com> under MIT license.";
    echo "    -h Shows help description of the script.";
    echo "    -i The path of the iso file to mount.";
    echo "    -o The drive to mount the iso to.";
    echo "    -n States that the conversions shouldn't be cleaned.";
}

# Process Input
while getopts "hni:o:" opt; do
    case "$opt" in
        h)
            show_help
            exit 0
            ;;
        o)  OUTPUT_DISK=$OPTARG
            ;;
        i)  SOURCE_FILE=$OPTARG
            ;;
        n)  REMOVE_CONVERSION=0
            ;;
        '?')
            show_help >&2
            exit 1
            ;;
    esac
done

# Check if there was a source file provided.
if [ "${SOURCE_FILE}" == "" ]; then
    echo -e "${Red}Must provide the path of the iso to mount.${NC}";
    exit 1;
fi

# Check Extension
if [ "${SOURCE_FILE:(-3)}" != "iso" ]; then
    echo -e "${Red}The file must be an iso.${NC}";
    exit 1;
fi

# Check if the file exists.
if [ ! -f "${SOURCE_FILE}" ]; then
    echo -e "${Red}The provided file doesn't exist.${NC}";
    exit 1;
fi

# Check for output disk.
if [ "${OUTPUT_DISK}" == "" ]; then
    echo -e "${Red}Must provide the disk to mount to.${NC}";
    diskutil list;
    exit 1;
fi



# Converts the iso into a img
echo -e "${Green}Converting iso to img.${NC}";
hdiutil convert -format UDRW -o "${SOURCE_FILE:0:${#SOURCE_FILE}-4}" "${SOURCE_FILE}"

# Check if we converted
if [ ! -f "${SOURCE_FILE:0:${#SOURCE_FILE}-4}.dmg" ]; then
    echo -e "${Red}Failed to convert iso.dmg.${NC}";
    exit 1;
fi


# Unmount's the disk
echo -e "${Green}Un-mounting ${OUTPUT_DISK}.${NC}";
diskutil unmountDisk "${OUTPUT_DISK}"

# mounts the iso to the drive
echo -e "${Green}Mounting image to ${OUTPUT_DISK}.";
echo -e "This can take several minutes depending on the iso size.${NC}";
sudo dd if="${SOURCE_FILE:0:${#SOURCE_FILE}-4}.dmg" of="${OUTPUT_DISK}" bs=1m
echo -e "${Green}Finished mounting image to ${OUTPUT_DISK}.${NC}";

# Eject the disk
echo -e "${Green}Ejecting ${OUTPUT_DISK}.${NC}";
diskutil eject "${OUTPUT_DISK}"

# Cleanup if needed
if [ ${REMOVE_CONVERSION} -eq 1 ]; then
    echo -e "${Green}Removing converted image.${NC}";
    rm "${SOURCE_FILE:0:${#SOURCE_FILE}-4}.dmg"

    # Check for file
    if [ -f "${SOURCE_FILE:0:${#SOURCE_FILE}-4}.dmg" ]; then
        echo -e "${Red}Failed to delete generated file '${SOURCE_FILE:0:${#SOURCE_FILE}-4}.dmg'.${NC}";
        exit 1;
    else
        echo -e "${Green}Deleted generated files.${NC}";
        exit 0;
    fi
fi