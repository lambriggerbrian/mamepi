#! /bin/bash

# This script launches the selected application (front-end or MAME emulator) and restarts it if required

declare -r script_name="$(basename "${0}")"

# Get SETTINGS_FILE location from environment variable, default to ~/settings
declare SETTINGS_FILE="${SETTINGS_FILE:-"$(realpath ~/settings)"}"
source "${SETTINGS_FILE}"

declare -r MAME_BIN="${MAME_BIN:-"$(which mame)"}"
declare -r MAME_ROMS_DIR="${MAME_ROMS_DIR:-"/usr/share/games/mame/roms"}"
declare -r MAME_STDOUT="${MAME_STDOUT:-$(realpath ~/mame.stdout)}"
declare -r MAME_STDERR="${MAME_STDERR:-$(realpath ~/mame.stderr)}"
declare -r MAME_AUTOROM="${MAME_AUTOROM:-${AUTOROM}}" # Sourced from SETTINGS_FILE

# Set audiodevice to hw 3.5mm jack by default
export AUDIODEV="hw"

# Start MAME GUI or automatic ROM Launch mode if AUTOROM is set
declare autorom="${MAME_AUTOROM}"

# Clear output files
echo "" | tee "${MAME_STDOUT}" "${MAME_STDERR}"

# Warn if ROM file doesn't exist (TODO: Check all configured ROM search paths)
if [ -n "${autorom}" ] && [ ! -f "${MAME_ROMS_DIR}/${autorom}.zip" ]; then
    echo "${script_name}[WARN]: No ROM '${autorom}' found in ROMS dir '${MAME_ROMS_DIR}'. Launching mame without AUTOROM..." | tee "${MAME_STDOUT}"
    autorom=""
fi

# Launch MAME
echo "${script_name}[INFO]: Launching mame! (autorom: ${autorom})" | tee "${MAME_STDOUT}"
if "${MAME_BIN}" "${autorom}" >>"${MAME_STDOUT}" 2>>"${MAME_STDERR}"; then
    echo "${script_name}[INFO]: Clean shutdown of mame completed." | tee "${MAME_STDOUT}"
    return 0
else
    echo "${script_name}[ERROR]: Unclean shutdown of mame completed." | tee "${MAME_STDERR}"
    return 1
fi
