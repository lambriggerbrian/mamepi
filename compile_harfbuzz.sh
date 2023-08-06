#!/bin/bash

# Build the latest HarfBuzz version.

declare -r script_name="$(basename "${0}")"

# Get HARFBUZZ_LATEST_URL from environment variable, default to https://api.github.com/repos/harfbuzz/harfbuzz/releases/latest
declare -r HARFBUZZ_LATEST_URL="${HARFBUZZ_LATEST_URL:-https://api.github.com/repos/harfbuzz/harfbuzz/releases/latest}"
# Get HARFBUZZ_CURRENT_VERSION from environment variable or set to NONE
declare HARFBUZZ_CURRENT_VERSION="${HARFBUZZ_CURRENT_VERSION:-NONE}"
declare HARFBUZZ_LATEST_VERSION=""
declare HARFBUZZ_LATEST_TAG=""

# Get HARFBUZZ_GIT_URL from environment variable, default to https://github.com/harfbuzz/harfbuzz
declare -r HARFBUZZ_GIT_URL="${HARFBUZZ_GIT_URL:-https://github.com/harfbuzz/harfbuzz}"
declare -a HARFBUZZ_BUILD_DEPS=("meson" "pkg-config" "ragel" "gtk-doc-tools" "gcc" "g++" "libfreetype6-dev" "libglib2.0-dev" "libcairo2-dev")

check_latest_version() {
    HARFBUZZ_LATEST_TAG="$(curl -s "${HARFBUZZ_LATEST_URL}" | jq -r .tag_name)"
    if [ -z "${HARFBUZZ_LATEST_TAG}" ]; then
        echo "check_latest_version[ERROR]: Could not get latest HARFBUZZ release tag."
        return 1
    fi

    HARFBUZZ_LATEST_VERSION="${HARFBUZZ_LATEST_TAG}" # HARFBUZZ tags are just the version name X.X.X
    if [ -z "${HARFBUZZ_LATEST_VERSION}" ]; then
        echo "check_latest_version[ERROR]: Could not get latest HARFBUZZ version."
        return 1
    fi

    echo "check_latest_version[INFO]: Latest HARFBUZZ version is ${HARFBUZZ_LATEST_VERSION}"
}

main() {
    # Installing jq for version check
    sudo apt update
    sudo apt install -y jq

    # Check HARFBUZZ versions
    echo "${script_name}[INFO]: Checking HARFBUZZ versions."
    check_latest_version
    echo "${script_name}[INFO]: Current version [${HARFBUZZ_CURRENT_VERSION}], latest version [${HARFBUZZ_LATEST_VERSION}]"
    if [ "${HARFBUZZ_CURRENT_VERSION}" = "${HARFBUZZ_LATEST_VERSION}" ]; then
        echo "${script_name}[INFO]: HarfBuzz is already at the latest version (${HARFBUZZ_CURRENT_VERSION})."
        return 0
    fi

    # Clone HARFBUZZ repo and checkout latest tag
    echo "${script_name}[INFO]: Cloning HarfBuzz repo and checking out latest tag [${HARFBUZZ_LATEST_TAG}]"
    git clone "${HARFBUZZ_GIT_URL}"
    cd "./harfbuzz" || return # return if we're not in the dir we expect as a precaution
    git checkout "${HARFBUZZ_LATEST_TAG}"

    # Configure and build
    echo "${script_name}[INFO]: Installing build dependencies..."
    sudo apt install -y "${HARFBUZZ_BUILD_DEPS[@]}"
    echo "${script_name}[INFO]: Buiding HARFBUZZ ${HARFBUZZ_LATEST_VERSION}..."
    meson build && meson test -Cbuild
}

main "$@"
