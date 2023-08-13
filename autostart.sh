#! /bin/bash

# This script launches the selected application (front-end or MAME emulator) and restarts it if required

declare -r script_name="$(basename "${0}")"

# Get SETTINGS_FILE location from environment variable, default to ~/settings
declare SETTINGS_FILE="${SETTINGS_FILE:-"$(realpath ~/settings)"}"
source "${SETTINGS_FILE}"

# If ALWAYS_RESTART is 1, then restart regardless of exit code
declare -r RESTART="${RESTART:-no}" # Sourced from SETTINGS_FILE

# start_mame.sh script
declare -r START_MAME_SCRIPT="${START_MAME_SCRIPT:-"$(realpath ~/mamepi/start_mame.sh)"}"

handle_mame() {
    echo "${script_name}[INFO]: Launching mame frontend..." | tee "${main_stdout}"
    if "${START_MAME_SCRIPT}"; then
        # On clean exit, don't restart if RESTART is no or on-error (meaning ONLY restart on-error)
        if [ "${RESTART}" = "no" ] || [ "${RESTART}" = "on-error" ]; then
            return 1
        fi
    else
        # On unclean exit, don't restart if RESTART is no or on-clean (meaning ONLY restart on-clean)
        if [ "${RESTART}" = "no" ] || [ "${RESTART}" = "on-clean" ]; then
            return 1
        fi
    fi
}

main() {
    local -r main_stdout="$(realpath ~/"${script_name}".stdout)"
    local -r main_stderr="$(realpath ~/"${script_name}".stderr)"
    # Clear output files
    echo "" | tee "${main_stdout}" "${main_stderr}"

    # Let systemd know we're ready (for type=notify services)
    systemd-notify --ready
    if [ -n "${FRONTEND}" ]; then
        local do_restart="yes"
        while [ "${do_restart}" = "yes" ]; do
            case ${FRONTEND,,} in
            attract) # Attract Mode (UNIMPLEMENTED)
                echo "${script_name}[INFO]: Launching attract frontend..." | tee "${main_stdout}"
                ;;
            advance) #AdvanceMENU (UNIMPLEMENTED)
                echo "${script_name}[INFO]: Launching advance frontend..." | tee "${main_stdout}"
                ;;
            mame) # MAME GUI or Automatic ROM Launch mode if AUTOROM is set
                # handle_mame returns non-zero if we shouldn't restart
                if ! handle_mame; then
                    do_restart="no"
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
declare exit_code="$?"
# Let systemd know we're stopping (for type=notify services)
systemd-notify --stopping
exit "${exit_code}"
