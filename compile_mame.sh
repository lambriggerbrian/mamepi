#!/bin/bash

# Build the latest MAME version without X11 dependency.

declare -r script_name="$(basename "${0}")"

# Get MAME_LATEST_URL from environment variable, default to https://api.github.com/repos/mamedev/mame/releases/latest
declare -r MAME_LATEST_URL="${MAME_LATEST_URL:-https://api.github.com/repos/mamedev/mame/releases/latest}"
# Get MAME_CURRENT_VERSION from environment variable or set to NONE
declare MAME_CURRENT_VERSION="${MAME_CURRENT_VERSION:-NONE}"
declare MAME_LATEST_VERSION=""
declare MAME_LATEST_TAG=""

# Get MAME_GIT_URL from environment variable, default to https://github.com/mamedev/mame
declare -r MAME_GIT_URL="${MAME_GIT_URL:-https://github.com/mamedev/mame}"
declare -a MAME_BUILD_DEPS=("build-essential" "git" "python3" "fontconfig" "libfontconfig-dev" "libx11-dev" "libpulse-dev" "qtbase5-dev" "qtbase5-dev-tools" "qtchooser" "qt5-qmake")
declare -a MAME_MAKE_OPTS=("TARGETOS=linux" "NO_X11=1" "NOWERROR=1" "NO_USE_XINPUT=1" "NO_USE_XINPUT_WII_LIGHTGUN_HACK=1" "NO_OPENGL=1" "USE_QTDEBUG=0" "DEBUG=0" "REGENIE=1" "NO_BGFX=1" "FORCE_DRC_C_BACKEND=1" "NO_USE_PORTAUDIO=1" "SYMBOLS=0")
declare -r MAX_THREAD=2

check_latest_version() {
    MAME_LATEST_JSON="$(curl -s "${MAME_LATEST_URL}")"
    MAME_LATEST_TAG="$(echo "${MAME_LATEST_JSON}" | jq -r .tag_name)"
    MAME_LATEST_NAME="$(echo "${MAME_LATEST_JSON}" | jq -r .name)"
    if [ -z "${MAME_LATEST_TAG}" ]; then
        echo "check_latest_version[ERROR]: Could not get latest MAME release tag."
        return 1
    fi

    MAME_LATEST_VERSION="${MAME_LATEST_NAME#"MAME "}" # MAME tags are in the form 'MAME X.XXX', so strip 'MAME '
    if [ -z "${MAME_LATEST_VERSION}" ]; then
        echo "check_latest_version[ERROR]: Could not get latest MAME version."
        return 1
    fi

    echo "check_latest_version[INFO]: Latest MAME version is ${MAME_LATEST_VERSION}"
}

main() {
    # Installing jq for version check
    sudo apt update
    sudo apt install -y jq

    # Check MAME versions
    echo "${script_name}[INFO]: Checking MAME versions."
    check_latest_version
    echo "${script_name}[INFO]: Current version [${MAME_CURRENT_VERSION}], latest version [${MAME_LATEST_VERSION}]"
    if [ "${MAME_CURRENT_VERSION}" = "${MAME_LATEST_VERSION}" ]; then
        echo "${script_name}[INFO]: MAME is already at the latest version (${MAME_CURRENT_VERSION})."
        return 0
    fi

    # Clone MAME repo and checkout latest tag
    echo "${script_name}[INFO]: Cloning MAME repo and checking out latest tag [${MAME_LATEST_TAG}]"
    git clone "${MAME_GIT_URL}"
    cd "./mame" || return # return if we're not in the dir we expect as a precaution
    git checkout "${MAME_LATEST_TAG}"

    # Configure and build
    echo "${script_name}[INFO]: Installing build dependencies..."
    sudo apt install -y "${MAME_BUILD_DEPS[@]}"
    echo "${script_name}[INFO]: Buiding MAME ${MAME_LATEST_VERSION}..."
    make -j "${MAX_THREAD}" "${MAME_MAKE_OPTS[@]}"

    # Install artifacts
    # sudo make install
}

main "$@"
