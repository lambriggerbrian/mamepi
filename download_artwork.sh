#! /bin/bash

# This script download the missing artwork files (snapshots, titles screens, marquees,
# control panels and cabinet pictures) based on the content of the ROMs path (ROM files).

# Usage: when a romname is passed (without the .zip extension), only the artwork for this
#         rom is downloaded.

declare -r script_name="$(basename "${0}")"

declare -r URL_PREFIX="http://adb.arcadeitalia.net/media/mame.current"
declare -r SNAP_PREFIX="${URL_PREFIX}/ingames"

declare -r MAME_DIR="${MAME_DIR:-"/home/admin/.mame"}"
declare -r MAME_ROMS_DIR="${MAME_ROMS_DIR:-"/usr/share/games/mame/roms"}"

get_artwork() {
    # $1 is romname (without .zip ideally, but we'll strip it just in case)
    local -r rom_name="${1%.zip}"
    local -r rom_png="${rom_name}.png"
    if [ -z "${rom_name}" ]; then
        return 1
    fi
    for type in snap titles marquees cpanels cabinets flyers; do
        local url target_dir target
        case $type in
        snap)
            # Snapshot is special case (it's called "artpreview" in MAME UI)
            url="${SNAP_PREFIX}/${rom_png}"
            target_dir="${MAME_DIR}/artpreview/${rom_name}"
            ;;
        *)
            url="${URL_PREFIX}/${type}/${rom_png}"
            target_dir="${MAME_DIR}/${type}/${rom_name}"
            ;;
        esac
        target="${target_dir}/${rom_png}"
        # Make sure our target directory exists
        mkdir -p "${target_dir}"
        if [ -f "${target}" ]; then
            echo "get_artwork[INFO]: File ${target} already exists, nothing to do"
        else
            echo "get_artwork[INFO]: Downloading ${type} for ${rom_name}..."
            if ! wget -q "${url}" -P "${target_dir}"; then
                echo "get_artwork[ERROR]: Could not download ${type} for ${rom_name}"
                return 1
            fi
        fi
    done
    echo "get_artwork[INFO]: Artwork downloaded for ${rom_name}"
}

main() {
    local -a rom_names=("$@")
    local info_names=""
    local -i exit_code=0
    if ((${#rom_names[@]} == 0)); then
        readarray -d '' rom_names < <(find "${MAME_ROMS_DIR}" -type f -name "*.zip" -print0)
        local -i num_roms=${#rom_names[@]}
        [ ${num_roms} -gt 5 ] && info_names="${num_roms} games" || info_names="${rom_names[*]}"
    fi
    echo "${script_name}[INFO]: Downloading artwork for [ ${info_names} ]"
    for rom in "${rom_names[@]}"; do
        if ! get_artwork "${rom}"; then
            exit_code=$?
        fi
    done
    return ${exit_code}
}

main "$@"
exit "$?"
