#! /bin/bash

# This script delete/purge bad or invalid ROMs files.
declare -r script_name="$(basename "${0}")"

shopt -s nullglob

declare -r MAME_BIN="${MAME_BIN:-"$(which mame)"}"
declare -r MAME_ROMS_DIR="${MAME_ROMS_DIR:-"/usr/share/games/mame/roms"}"

declare -r OPTION="${1}"

echo "${script_name}[INFO]: Detecting bad roms..."
declare -a bad_roms=()
declare -i detected_roms=0
while read -r line; do
    bad_rom=$(echo "${line}" | awk '/is bad/ {print $2".zip"}')
    if [ -n "${bad_rom}" ]; then
        echo "${script_name}[INFO]: ${bad_rom} is bad"
        bad_roms+=("${bad_rom}")
        ((detected_roms++))
    fi
done < <(stdbuf -oL "${MAME_BIN}" -verifyroms)
echo "${script_name}[INFO]: Detected ${detected_roms} bad roms."

if [ "${OPTION,,}" = "delete" ]; then
    declare -i deleted_roms=0
    for rom in "${bad_roms[@]}"; do
        declare rom_path="${MAME_ROMS_DIR}/${rom}"
        if [ -f "${rom_path}" ]; then
            sudo rm "${rom_path}"
            echo "${script_name}[INFO]: Deleted '${rom_path}'"
            ((deleted_roms++))
        else
            echo "${script_name}[ERROR]: Could not find file '${rom_path}'"
        fi
    done
    echo "${script_name}[INFO]: Deleted ${deleted_roms} roms"
fi
