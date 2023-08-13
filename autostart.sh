#! /bin/bash

# This script launch the selected application (front-end or MAME emulator) and respawn it if quit unexpectedly.

declare -r script_name="$(basename "${0}")"

# Get SETTINGS_FILE location from environment variable, default to ~/settings
declare SETTINGS_FILE="${SETTINGS_FILE:-"$(realpath ~/settings)"}"
source "${SETTINGS_FILE}"

# Get ATTRACT_EMULATORS_DIR location from environment variable, default to ~/.attract/emulators
# NOTE: realpath -m will make canonical path whether parent dirs exist or not so that
#       error messages are more helpful as to where ATTRACT_EMULATORS_DIR is looking
declare ATTRACT_EMULATORS_DIR="${ATTRACT_EMULATORS_DIR:-"$(realpath -m ~/.attract/emulators)"}"
declare -r ATTRACT_BIN="${ATTRACT_BIN:-"$(which attract)"}"

declare -r ADVANCE_BIN="${ADVANCE_BIN:-"$(realpath -m ~/frontend/advance/advmenu)"}"

declare -r MAME_BIN="${MAME_BIN:-"$(which mame)"}"
declare -r MAME_ROMS_DIR="${MAME_ROMS_DIR:-"/usr/local/share/games/mame/roms"}"
declare -r MAME_STDOUT="${MAME_STDOUT:-$(realpath ~/mame.stdout)}"
declare -r MAME_STDERR="${MAME_STDERR:-$(realpath ~/mame.stderr)}"
declare -r MAME_AUTOROM="${MAME_AUTOROM:-AUTOROM}" # Sourced from SETTINGS_FILE

# Set audiodevice to hw 3.5mm jack by default
export AUDIODEV="hw"

main() {
    local -r main_stdout="$(realpath ~/"${script_name}".stdout)"
    local -r main_stderr="$(realpath ~/"${script_name}".stderr)"
    # Clear output files
    echo "" | tee "${main_stdout}" "${main_stderr}"

    if [ -n "${FRONTEND}" ]; then
        local -i continue_loop=1
        while [ "${continue_loop}" = 1 ]; do
            case ${FRONTEND,,} in
            attract) # Attract Mode (UNIMPLEMENTED)
                # if [ -n "${AUTOROM}" ] && [ -n "${EMULATOR}" ]; then
                #     local -r EMULATOR_CFG="${ATTRACT_EMULATORS_DIR}/${EMULNAME}.cfg"
                #     if [ -f $CFGFILE ]; then
                #         while read var value; do
                #             [ ! -z $var ] && [ " ${var:0:1} " != " # " ] && export " $var " = " $value "
                #         done <$CFGFILE
                #         ARGS= ${args// \[ name \] / $ROMNAME }
                #         ARGS=${ARGS// \$ HOME / $HOME }
                #         EXEC= ${executable// \$ HOME / $HOME }
                #         FRAMEFILE= $(sed ' s/^.*\s-framefile\s\(\S*\) \s.*$/\1/ ' <<<$ARGS)
                #     fi
                #     if [ ! -z $FRAMEFILE ] && [ -f $FRAMEFILE ] && [ ! -z $EXEC ] && [ -x $EXEC ]; then # Automatic ROM Launch mode
                #         $EXEC $ARGS -nolog >/dev/null 2>/dev/null
                #     else
                #         stty-echo
                #         /usr/local/bin/attract --loglevel silent >/dev/null 2>&1
                #     fi
                # else
                #     stty-echo
                #     /usr/local/bin/attract --loglevel silent >/dev/null 2>&1
                # fi
                echo "${script_name}[INFO]: Launching attract frontend..." | tee "${main_stdout}"
                ;;
            advance) #AdvanceMENU (UNIMPLEMENTED)
                echo "${script_name}[INFO]: Launching advance frontend..." | tee "${main_stdout}"
                # local -r advance_stdout="$(realpath ~/mame.stdout)"
                # local -r advance_stderr="$(realpath ~/mame.stderr)"
                # # Clear output files
                # echo "" | tee "${advance_stdout}" "${advance_stderr}"
                # "${ADVANCE_BIN}" >>"${advance_stdout}" 2>>"${advance_stderr}"
                ;;
            mame) # MAME GUI or Automatic ROM Launch mode if AUTOROM is set
                echo "${script_name}[INFO]: Launching mame frontend..." | tee "${main_stdout}"

                # Clear output files
                echo "" | tee "${MAME_STDOUT}" "${MAME_STDERR}"
                if [ -n "${mame_autorom}" ] && [ ! -f "${MAME_ROMS_DIR}/${mame_autorom}.zip" ]; then
                    echo "${script_name}[WARN]: No ROM '${mame_autorom}' found in ROMS dir '${MAME_ROMS_DIR}'"
                fi
                if "${MAME_BIN}" "${mame_autorom}" >>"${MAME_STDOUT}" 2>>"${MAME_STDERR}"; then
                    # Only break the loop if we exit cleanly (exit code 0)
                    continue_loop=0
                fi
                ;;
            esac
        done
        return 0
    else
        echo "${script_name}[INFO]: FRONTEND is not defined!" | tee "${main_stdout}"
        return 1
    fi
}

main "$@"
