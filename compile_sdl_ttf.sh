#!/bin/bash

# Build the latest SDL_ttf version

declare -r script_name="$(basename "${0}")"

# Get SDL_TTF_URL from environment variable, default to https://api.github.com/repos/libsdl-org/SDL/releases/latest
declare -r SDL_TTF_LATEST_URL="${SDL_TTF_LATEST_URL:-https://api.github.com/repos/libsdl-org/SDL_ttf/releases/latest}"
# Get SDL_TTF_CURRENT_VERSION from environment variable or set to NONE
declare SDL_TTF_CURRENT_VERSION="${SDL_TTF_CURRENT_VERSION:-NONE}"
declare SDL_TTF_LATEST_VERSION=""
declare SDL_TTF_LATEST_TAG=""

# Get SDL_TTF_GIT_URL from environment variable, default to https://github.com/libsdl-org/SDL_ttf
declare -r SDL_TTF_GIT_URL="${SDL_TTF_GIT_URL:-https://github.com/libsdl-org/SDL_ttf}"
declare -a SDL_TTF_BUILD_DEPS=("build-essential" "gcc-aarch64-linux-gnu")

check_latest_version() {
    SDL_TTF_LATEST_TAG="$(curl -s "${SDL_TTF_LATEST_URL}" | jq -r .tag_name)"
    if [ -z "${SDL_TTF_LATEST_TAG}" ]; then
        echo "check_latest_version[ERROR]: Could not get latest SDL_ttf release tag."
        return 1
    fi

    SDL_TTF_LATEST_VERSION="${SDL_TTF_LATEST_TAG#release-}" # SDL_TTF tags are in the form release-X.XX.X, so strip 'release-'
    if [ -z "${SDL_TTF_LATEST_VERSION}" ]; then
        echo "check_latest_version[ERROR]: Could not get latest SDL_ttf version."
        return 1
    fi

    echo "check_latest_version[INFO]: Latest SDL_ttf version is ${SDL_TTF_LATEST_VERSION}"
}

main() {
    # Installing jq for version check
    sudo apt update
    sudo apt install -y jq

    # Check SDL_ttf versions
    echo "${script_name}[INFO]: Checking SDL_ttf versions."
    check_latest_version
    echo "${script_name}[INFO]: Current version [${SDL_TTF_CURRENT_VERSION}], latest version [${SDL_TTF_LATEST_VERSION}]"
    if [ "${SDL_TTF_CURRENT_VERSION}" = "${SDL_TTF_LATEST_VERSION}" ]; then
        echo "${script_name}[INFO]: SDL_ttf is already at the latest version (${SDL_TTF_CURRENT_VERSION})."
        return 0
    fi

    # Clone SDL_ttf repo and checkout latest tag
    echo "${script_name}[INFO]: Cloning SDL_ttf repo and checking out latest tag [${SDL_TTF_LATEST_TAG}]"
    git clone "${SDL_TTF_GIT_URL}"
    cd "./SDL_ttf" || return # return if we're not in the dir we expect as a precaution
    git checkout "${SDL_TTF_LATEST_TAG}"

    # Configure and build
    echo "${script_name}[INFO]: Installing build dependencies..."
    sudo apt install -y "${SDL_TTF_BUILD_DEPS[@]}"
    echo "${script_name}[INFO]: Buiding SDL_ttf ${SDL_TTF_LATEST_VERSION}..."
    ./configure
    make -j "$(nproc)"

    # Install artifacts
    sudo make install
    sudo ldconfig -v
}

main "$@"
