#!/bin/bash

# Function to display the help message
function show_help() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo "Options:"
    echo "  -u, --url          YouTube URL of the video you want to download (required)"
    echo "  -s, --start-time   Timecode of the start of the clip to extract in format HH:MM:SS (required)"
    echo "  -e, --end-time     Timecode of the end of the clip to extract in format HH:MM:SS (required)"
    echo "  -o, --output       Output filename for the clip (required)"
    echo "  -h, --help         Show this help message and exit"
}

# Function to install packages using apt
function install_apt_packages() {
    sudo apt update
    sudo apt install -y "$@"
}

function install_choco_packages() {
    if ! command -v choco &> /dev/null; then
        echo "Error: Chocolatey package manager not found on the current system."
        exit 1
    fi

    choco install -y "$@"
}

# Function to install packages using yum
function install_yum_packages() {
    sudo yum install -y "$@"
}

function install_pacman_packages() {
    if ! command -v pacman &> /dev/null; then
        echo "Error: pacman package manager not found on the current system."
        exit 1
    fi

    pacman -S --noconfirm "$@"
}

# Function to check if packages are installed
function check_packages() {
    local packages=("$@")

    local missing_packages=()
    local package_manager

    if command -v pacman &> /dev/null; then
        package_manager="pacman"
    elif command -v apt &> /dev/null; then
        package_manager="apt"
    elif command -v yum &> /dev/null; then
        package_manager="yum"
    elif command -v choco &> /dev/null; then
        package_manager="choco"
    else
        echo "Error: Package manager not found on the current system."
        echo "Operating System: $(uname -s)"
        echo "Missing packages: ${packages[*]}"
        echo "To install the required packages, please use the package manager specific to your OS."
        exit 1
    fi

    for package in "${packages[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            missing_packages+=("$package")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo "The following packages are required but not installed: ${missing_packages[*]}"
        echo "To install the required packages, please use the package manager specific to your OS."
        exit 1
    fi
}

# Function to prompt for user confirmation
function confirm_command() {
    local required_packages=("yt-dlp" "ffmpeg")
    local found_packages=()
    local missing_packages=()

    for package in "${required_packages[@]}"; do
        if command -v "$package" &> /dev/null; then
            found_packages+=("$package: $(command -v "$package")")
        else
            missing_packages+=("$package")
        fi
    done

    echo "The following packages are required for this script:"
    for ((i = 0; i < ${#required_packages[@]}; i++)); do
        echo "$((i + 1)). ${required_packages[$i]}"
    done

    if [ ${#found_packages[@]} -gt 0 ]; then
        echo "The following packages have been found:"
        for package_info in "${found_packages[@]}"; do
            echo "  - $package_info"
        done
    fi

    if [ ${#missing_packages[@]} -eq 0 ]; then
        read -r -p "Do you want to proceed with the video processing? (y/n): " response
        case "$response" in
            [yY][eE][sS] | [yY])
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    else
        echo "The following packages are missing and need to be installed:"
        for package in "${missing_packages[@]}"; do
            echo "  - $package"
        done

        local package_manager

        if command -v pacman &> /dev/null; then
            package_manager="pacman"
        elif command -v apt &> /dev/null; then
            package_manager="apt"
        elif command -v yum &> /dev/null; then
            package_manager="yum"
        elif command -v choco &> /dev/null; then
            package_manager="choco"
        else
            echo "Error: Package manager not found on the current system."
            echo "Operating System: $(uname -s)"
            echo "Recommended steps to install the missing packages:"
            echo "Please use the package manager specific to your OS."
            return 1
        fi

        echo "Recommended steps to install the missing packages:"
        case "$package_manager" in
            "pacman")
                echo "  To install the missing packages, run: sudo pacman -S ${missing_packages[*]}"
                ;;
            "apt")
                echo "  To install the missing packages, run: sudo apt update && sudo apt install ${missing_packages[*]}"
                ;;
            "yum")
                echo "  To install the missing packages, run: sudo yum install ${missing_packages[*]}"
                ;;
            "choco")
                echo "  To install the missing packages, run: choco install ${missing_packages[*]}"
                ;;
        esac

        return 1
    fi
}

# Parse command-line arguments using getopts
while getopts ":u:s:e:o:h" opt; do
    case $opt in
        u | --url)
            YOUTUBE_URL="$OPTARG"
            ;;
        s | --start-time)
            START_TIME="$OPTARG"
            ;;
        e | --end-time)
            END_TIME="$OPTARG"
            ;;
        o | --output)
            OUTPUT_FILENAME="$OPTARG"
            ;;
        h | --help)
            show_help
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            show_help
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            show_help
            exit 1
            ;;
    esac
done

function check_permissions() {
    if [ "$OS" == "Linux" ]; then
        if [ "$EUID" -ne 0 ]; then
            echo "Error: You need root permissions to install packages."
            echo "You can try running the script with 'sudo' or as the 'root' user."
            exit 1
        fi
    elif [ "$OS" == "Windows" ]; then
        # Check for MINGW64 on Windows
        if [ "$MINGW_PREFIX" == "MINGW64" ]; then
            # Check if the script is running without administrator permissions
            if ! net session &>/dev/null; then
                echo "Error: You need administrator permissions to install packages in MINGW64."
                echo "You can try running the script as an administrator."
                exit 1
            fi
        else
            # For regular Windows environments, check for administrator permissions
            local is_admin=$(net session &>/dev/null && echo "true" || echo "false")
            if [ "$is_admin" == "false" ]; then
                echo "Error: You need administrator permissions to install packages in Windows."
                echo "You can try running the script as an administrator."
                exit 1
            fi
        fi
    fi
}

# Function to detect the operating system
function detect_os() {
    if [ "$(uname)" == "Linux" ]; then
        OS="Linux"
    elif [ "$(uname -s)" == "MINGW32_NT-10.0" ] || [ "$(uname -s)" == "MINGW64_NT-10.0" ]; then
        OS="Windows"
    else
        OS="Other"
    fi
}

# Detect the operating system
detect_os

# Check if the user has the required permissions
check_permissions

# Check if required arguments are provided
if [ -z "$YOUTUBE_URL" ] || [ -z "$START_TIME" ] || [ -z "$END_TIME" ] || [ -z "$OUTPUT_FILENAME" ]; then
    echo "Error: Missing required argument(s)." >&2
    show_help
    exit 1
fi

# Check if required packages are installed
check_packages "yt-dlp" "ffmpeg"

# Confirm the command before proceeding
if ! confirm_command; then
    echo "Video processing canceled by user."
    exit 0
fi

if [ -f "$OUTPUT_FILENAME" ]; then
    read -r -p "The output file '$OUTPUT_FILENAME' already exists. Do you want to delete it and continue? (y/n): " response
    case "$response" in
        [yY][eE][sS] | [yY])
            rm "$OUTPUT_FILENAME"
            ;;
        *)
            echo "Video processing canceled by user."
            rm "temp_video.mp4"
            exit 0
            ;;
    esac
fi

# Validate time format
if ! [[ $START_TIME =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] || ! [[ $END_TIME =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    echo "Error: Invalid time format. Please use HH:MM:SS format for start and end times."
    exit 1
fi

# Step 1: Download the YouTube video using yt-dlp
if ! yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' -o "temp_video.mp4" "$YOUTUBE_URL"; then
    echo "Error: Failed to download the video from the provided URL."
    exit 1
fi

# Step 2: Extract the clip using ffmpeg
if ! ffmpeg -i "temp_video.mp4" -ss "$START_TIME" -to "$END_TIME" -vf "scale=-2:480" -c:v libx264 -preset ultrafast -crf 23 -c:a aac "$OUTPUT_FILENAME"; then
    echo "Error: Failed to extract the clip. Please check the start and end times."
    rm "temp_video.mp4"
    exit 1
fi

# Step 3: Clean up temporary files
rm "temp_video.mp4"

echo "Clip extracted successfully: $OUTPUT_FILENAME"

read -r -p "Press Enter to continue and read any logs or errors..."