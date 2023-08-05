#!/bin/bash

# Get SETTINGS_FILE location from environment variable, default to ~/settings
declare SETTINGS_FILE=${SETTINGS_FILE:-"$(realpath ~/settings)"};
# Get ATTRACT_EMULATORS_DIR location from environment variable, default to ~/.attract/emulators
# NOTE: realpath -m will make canonical path whether parent dirs exist or not so that
#       error messages are more helpful as to where ATTRACT_EMULATORS_DIR is looking
declare ATTRACT_EMULATORS_DIR=${ATTRACT_EMULATORS_DIR:-"$(realpath -m ~/.attract/emulators)"}

# Update setting in if it exists in SETTINGS_FILE, else append it
#   Usage: update_settings setting_name setting_value
#       setting_name: the name of the setting to update
#       setting_value: the value to update, defaults to nothing
update_settings(){ 
    local -r setting_name="${1}";
    local -r setting_value="${2:-}"; # Set to nothing as default
    local -r output_line="${setting_name}=${setting_value}";
    # Check for setting_name and setting_value
    if [ -z "${setting_name}" ]; then
        echo "update_settings[ERR]: Must pass setting_name.";
        return 1;
    fi
    if [ ! -f "${SETTINGS_FILE}" ]; then
        echo "update_settings[INFO]: No SETTINGS_FILE found at ${SETTINGS_FILE}. Creating it now."
        touch "${SETTINGS_FILE}"; # Ensure settings file exists
    fi
    # If setting_name in SETTINGS_FILE at beginning of a line with = after, update with setting_value
    # else append setting_name=setting_value to SETTINGS_FILE
    # NOTE: This would update all matching occurrences of setting_name in SETTINGS_FILE
    if grep -q "^${setting_name}=" "${SETTINGS_FILE}"; then
        sed -i "s/^${setting_name}=.*$/${output_line}/g" "$(readlink -f ${SETTINGS_FILE})";
    else
        echo "${output_line}" | tee -a "${SETTINGS_FILE}";
    fi
};

# Set the ROM to run with MAME or unset
#   Usage: set_mame rom_name
#       rom_name: name of the ROM to launch at start or 'none' to unset
set_mame(){
    local -r rom_name="${1}"
    # Check that we have a rom_name
    if [ -z "${rom_name}" ]; then
        echo "set_mame[ERR]: Must pass rom_name or NONE to use the MAME frontend.";
        return 1;
    fi
    # Set FRONTEND to mame
    update_settings FRONTEND mame;
    echo "set_mame[INFO]: Frontend set to mame (reboot to apply).";
    # Unset AUTOROM if rom_name is 'none'
    if [ "${rom_name}" = "none" ]; then
        echo "set_mame[INFO]: Unsetting AUTOROM value.";
        update_settings AUTOROM;
        return 0;
    fi
    # Set AUTOROM to rom_name
    update_settings AUTOROM "${rom_name}";
    echo "set_mame[INFO]: Automatic ROM Launch set to: ${rom_name}.";
}

# Set the ROM to run with attract
#   Usage: set_attract rom_name emulator name
#       rom_name: name of the ROM to launch at start
#       emulator_name: name of the emulator to use
set_attract(){
    local -r rom_name="${1}"
    local -r emulator_name="${2}"
    # Check that we have a rom_name and an emulator_name
    if [[ -z "${rom_name}" || -z "${emulator_name}" ]]; then
        echo "set_attract[ERR]: must pass rom_name and emulator_name to use attract frontend.";
        return 1;
    fi
    # Check that attract has a config file for emulator_name
    local -r emulator_file="${ATTRACT_EMULATORS_DIR}/${emulator_name}.cfg";
    if [ ! -f "${emulator_file}" ]; then
        echo "ERROR: could not find config file for emulator ${emulator_name} at ${emulator_file}"
        return 1;
    fi
    # Set FRONTEND to attract
    update_settings FRONTEND attract;
    echo "Frontend set to attract (reboot to apply).";
    # Set AUTOROM with the emulator_name and rom_name
    update_settings AUTOROM "AUTOROM=\"${emulator_name} ${rom_name}\"";
    echo "Automatic ROM Launch set to: ${rom_name} (emulator ${emulator_name}).";
}

# Set which frontend program is run at start
#   Usage: set_frontend frontend_program rom_name [emulator_name]
#       frontend_program: name of frontend program to run (options - mame, attract)
#       rom_name: name of ROM to launch at start or NONE to unset for MAME
#       emulator_name: emulator to use (only used if FRONTEND_PROGRAM is attract)
# $3: ROM to launch with emulator $2
set_frontend(){ 
    local -r frontend_program="${1,,}";
    local -r rom_name="${2,,}";
    local -r emulator_name="${3,,}";
    case "${frontend_program}" in
        mame)
            if [ -z "${rom_name}" ]; then
                echo "ERROR: must pass rom_name or 'none' to unset";
                return 1;
            fi
            set_mame "${rom_name}";
            ;;
        attract)
            if [[ -z "${rom_name}" || -z "${emulator_name}" ]]; then
                echo "ERROR: must pass rom_name and emulator_name to use attract frontend.";
                return 1;
            fi
            set_attract "${rom_name}" "${emulator_name}"
            ;;
        *)
            echo "ERROR: Invalid or missing argument. Try: mame [rom], attract [emulator rom] or advance";
            return 1;

    esac;
}; 

# Echo the clockspeed of the CPU
cpufreq() {
    echo "Clock Speed=$(($(/usr/bin/vcgencmd measure_clock arm | awk -F '=' '{print $2}')/1000000)) MHz"
}

# Utility aliases
alias system_update='sudo apt-get update && sudo apt-get upgrade -y' 
alias cputemp='/usr/bin/vcgencmd measure_temp' 

# Aliases to switch between Arcade Mode and Service Mode 
alias set_arcademode='sudo systemctl enable mame-autostart.service' 
alias set_servicemode='sudo systemctl disable mame-autostart.service' 
alias get_mode='echo -n "The system is currently in " ; systemctl -q is-active mame-autostart.service && echo -n ARCADE || echo -n SERVICE; echo "mode."'