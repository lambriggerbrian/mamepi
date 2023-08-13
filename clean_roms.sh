#! /bin/bash

# This script delete/purge bad or invalid ROMs files.
declare -r script_name="$(basename "${0}")"

shopt -s nullglob

declare -r MAME_BIN="${MAME_BIN:-"$(which mame)"}"
declare -r MAME_ROMS_DIR="${MAME_ROMS_DIR:-"/usr/share/games/mame/roms"}"

for rom in $(${MAME_BIN} -verifyroms | grep ' is bad ' | awk ' {print $2 ".zip"} '); do
    declare rom_path="${MAME_ROMS_DIR}/${rom}"
    declare -i deleted_roms=0
    if [ -f "${rom_path}" ]; then
        sudo rm "${rom_path}"
        echo "${script_name}[INFO]: Deleted '${rom_path}'"
        ((deleted_roms++))
    else
        echo "${script_name}[ERROR]: Could not find file '${rom_path}'"
    fi
done
echo "${script_name}[INFO]: Deleted ${deleted_roms} roms"
