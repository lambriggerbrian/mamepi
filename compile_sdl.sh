#!/bin/bash

# Build the latest SDL2 version without X11 dependency.

declare -r script_name="$(basename "${0}")"

# Get SDL_LATEST_URL from environment variable, default to https://api.github.com/repos/libsdl-org/SDL/releases/latest
declare -r SDL_LATEST_URL="${SDL_LATEST_URL:-https://api.github.com/repos/libsdl-org/SDL/releases/latest}"
# Get SDL_CURRENT_VERSION from environment variable or set to NONE
declare SDL_CURRENT_VERSION="${SDL_CURRENT_VERSION:-NONE}"
declare SDL_LATEST_VERSION=""
declare SDL_LATEST_TAG=""

# Get SDL_GIT_URL from environment variable, default to https://github.com/libsdl-org/SDL
declare -r SDL_GIT_URL="${SDL_GIT_URL:-https://github.com/libsdl-org/SDL}"
declare -a SDL_BUILD_DEPS=("build-essential" "gcc-aarch64-linux-gnu")
declare -a SDL_CONFIG_OPTS=("--disable-video-opengl" "--disable-video-opengles1" "--disable-video-x11" "--disable-pulseaudio" "--disable-esd" "--disable-video-wayland" "--disable-video-rpi" "--disable-video-vulkan" "--enable-video-kmsdrm" "--enable-video-opengles2" "--enable-alsa" "--disable-joystick-virtual" "--enable-arm-neon" "--enable-arm-simd")

# If sdl2-config is installed, set SDL_CURRENT_VERSION to its output
if [ -n "$(which sdl2-config)" ]; then
    SDL_CURRENT_VERSION="$(sdl2-config --version)"
else
    echo "${script_name}[WARN]: No sdl2-config binary found!"
fi

check_latest_version() {
    SDL_LATEST_TAG="$(curl -s "${SDL_LATEST_URL}" | jq -r .tag_name)"
    if [ -z "${SDL_LATEST_TAG}" ]; then
        echo "check_latest_version[ERROR]: Could not get latest SDL release tag."
        return 1
    fi

    SDL_LATEST_VERSION="${SDL_LATEST_TAG#release-}" # SDL tags are in the form release-X.XX.X, so strip 'release-'
    if [ -z "${SDL_LATEST_VERSION}" ]; then
        echo "check_latest_version[ERROR]: Could not get latest SDL version."
        return 1
    fi

    echo "check_latest_version[INFO]: Latest SDL2 version is ${SDL_LATEST_VERSION}"
}

main() {
    # Installing jq for version check
    sudo apt update
    sudo apt install -y jq

    # Check SDL versions
    echo "${script_name}[INFO]: Checking SDL versions."
    check_latest_version
    echo "${script_name}[INFO]: Current version [${SDL_CURRENT_VERSION}], latest version [${SDL_LATEST_VERSION}]"
    if [ "${SDL_CURRENT_VERSION}" = "${SDL_LATEST_VERSION}" ]; then
        echo "${script_name}[INFO]: SDL2 is already at the latest version (${SDL_CURRENT_VERSION})."
        return 0
    fi

    # Clone SDL repo and checkout latest tag
    echo "${script_name}[INFO]: Cloning SDL repo and checking out latest tag [${SDL_LATEST_TAG}]"
    git clone "${SDL_GIT_URL}"
    cd "./SDL" || return # return if we're not in the dir we expect as a precaution
    git checkout "${SDL_LATEST_TAG}"

    # Configure and build
    echo "${script_name}[INFO]: Installing build dependencies..."
    sudo apt install -y "${SDL_BUILD_DEPS[@]}"
    echo "${script_name}[INFO]: Buiding SDL2 ${SDL_LATEST_VERSION}..."
    ./configure "${SDL_CONFIG_OPTS[@]}"
    make -j "$(nproc)"

    # Install artifacts
    sudo make install

    # Install SDL2_TTF
    sudo apt install -y libsdl2-ttf-dev
}

main "$@"
