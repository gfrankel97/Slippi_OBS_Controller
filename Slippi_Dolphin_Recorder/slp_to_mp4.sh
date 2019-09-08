#!/bin/bash
COLOR_BLUE='\033[0;34m'
COLOR_BLACK='\033[30m'
COLOR_CYAN='\033[0;36m'
COLOR_DARK_GRAY='\033[0;90m'
COLOR_GREEN='\033[0;32m'
COLOR_LIGHT_BLUE='\033[1;34m'
COLOR_LIGHT_CYAN='\033[1;36m'
COLOR_LIGHT_GRAY='\033[0;37m'
COLOR_LIGHT_GREEN='\033[1;32m'
COLOR_LIGHT_MAGENTA='\033[1;35m'
COLOR_LIGHT_RED='\033[1;31m'
COLOR_LIGHT_YELLOW='\033[1;33m'
COLOR_MAGENTA='\033[0;35m'
COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[1;37m'
COLOR_YELLOW='\033[0;33m'
COLOR_NONE='\033[0m'


function validate_and_set_settings {
    path_to_slp_files=$(jq -r .path_to_slp_files $(pwd)/settings/settings.json)
    if [[ $path_to_slp_files = null ]]; then
        echo -e "[${COLOR_RED}Setting Missing${COLOR_NONE}]: Setting not found (check settings.json - path_to_slp_files)"
        exit 1
    fi

    path_to_dolphin_app_user_dir=$(jq -r .path_to_dolphin_app_user_dir $(pwd)/settings/settings.json)
    if [[ $path_to_dolphin_app_user_dir = null ]]; then
        echo -e "[${COLOR_RED}Setting Missing${COLOR_NONE}]: Setting not found (check settings.json - path_to_dolphin_app_user_dir)"
        exit 1
    fi

    path_to_dolphin_app_config_dir=$(jq -r .path_to_dolphin_app_config_dir $(pwd)/settings/settings.json)
    if [[ $path_to_dolphin_app_config_dir = null ]]; then
        echo -e "[${COLOR_RED}Setting Missing${COLOR_NONE}]: Setting not found (check settings.json - path_to_dolphin_app_config_dir)"
        exit 1
    fi


    path_to_slippi_desktop_app=$(jq -r .path_to_slippi_desktop_app $(pwd)/settings/settings.json)
    if [[ $path_to_slippi_desktop_app = null ]]; then
        echo -e "[${COLOR_RED}Setting Missing${COLOR_NONE}]: Setting not found (check settings.json - path_to_slippi_desktop_app)"
        exit 1
    fi

    path_to_slippi_desktop_app_data_dir=$(jq -r .path_to_slippi_desktop_app_data_dir $(pwd)/settings/settings.json)
    if [[ $path_to_slippi_desktop_app_data_dir = null ]]; then
        echo -e "[${COLOR_RED}Setting Missing${COLOR_NONE}]: Setting not found (check settings.json - path_to_slippi_desktop_app_data_dir)"
        exit 1
    fi

    if [[ ! -f "$(pwd)/settings/dolphin_settings.ini" ]]; then
        echo -e "[${COLOR_RED}File Missing${COLOR_NONE}]: dolphin_settings.ini"
        exit 1
    fi

    if [[ ! -f "$(pwd)/settings/slippi_desktop_app_settings.json" ]]; then
        echo -e "[${COLOR_RED}File Missing${COLOR_NONE}]: slippi_desktop_app_settings.json"
        exit 1
    else
        dolphin_bin=$(jq -r .settings.playbackDolphinPath $(pwd)/settings/slippi_desktop_app_settings.json)
        if [[ $dolphin_bin = null ]]; then
            echo -e "[${COLOR_RED}Setting Missing${COLOR_NONE}] Setting not found (check slippi_desktop_app_settings.json - settings.playbackDolphinPath)"
            exit 1
        else
            if [[ ! -f ${dolphin_bin} ]]; then
                echo -e "[${COLOR_RED}File Missing${COLOR_NONE}]: Dolphin Binary not found (check your settings in: slippi_desktop_app_settings.json)"
                exit 1
            fi
        fi

        melee_iso=$(jq -r .settings.isoPath $(pwd)/settings/slippi_desktop_app_settings.json)
        if [[ $melee_iso = null ]]; then
            echo -e "[${COLOR_RED}Setting Missing${COLOR_NONE}] in: slippi_desktop_app_settings.json - settings.isoPath"
            exit 1
        else
            if [[ ! -f ${melee_iso} ]]; then
                echo -e "[${COLOR_RED}File Missing${COLOR_NONE}]: ${melee_iso}"
                exit 1
            fi
        fi
        
    fi

    echo -e "[${COLOR_GREEN}Settings Validated${COLOR_NONE}]: $(pwd)/settings/settings.json"
}

function init {
    #Kill running Slippi Desktop App and Dolphin instances
    ps axf | grep slippi-desktop-app | grep -v grep | awk '{print "kill -9 " $1}' | sh
    ps axf | grep dolphin-emu | grep -v grep | awk '{print "kill -9 " $1}' | sh

    #Validate settings and set variables
    validate_and_set_settings

    #Copy Slippi Desktop App settings from script to application
    cp "$(pwd)/settings/slippi_desktop_app_settings.json" "${path_to_slippi_desktop_app_data_dir}/Settings"

    #Copy Dolphin.ini settings from script to application
    cp "$(pwd)/settings/dolphin_settings.ini" "${path_to_dolphin_app_config_dir}/Dolphin.ini"

}

function record_file {
    local slp_file=$1

    #Get frames in Slippi file
    local offset=$(strings -d -t d -n 9 $file | grep -A1 'lastFramel' | grep -v "lastFramel"| cut -d: -f1 | cut -d ' ' -f1)
    offset="$(($offset - 4))"
    if [ "$offset" -eq -4 ]; then
        offset=$(strings -d -t d -n 9 $file | grep -A1 'lastFramel' | grep -v "lastFramel" | cut -d ' ' -f2 | cut -d: -f1 | cut -d ' ' -f1)
        offset="$(($offset - 4))"
    fi
    #echo "$offset"
    local a=$(xxd -p -l1 -s $offset $file)
	offset="$(($offset + 1))"
	local b=$(xxd -p -l1 -s $offset $file)
	#echo "$a"
	#echo "$b"
	local c="$((16#$a * 256 + 16#$b))"
	#echo "$c"
	local d="$((10 + $c / 60))"
	#echo "$d"

    local frames_file=$path_to_dolphin_app_user_dir/Logs/render_time.txt
    local dump_folder="${path_to_slp_files}/dump"
    local dump_file=$dump_folder/frames/frame*
    local audio_files=$dump_folder/audio/*
    local audio_file=$dump_folder/audio/dspdump.wav

    rm -f $frames_file
        rm -f $dump_file
        rm -f $audio_files
        rm -f $audio_file
	mkdir -p $dump_folder/Frames

    # Launch slippi desktop app so it will launch dolphin, then kill slippi desktop app
    echo $path_to_slippi_desktop_app
	# $($path_to_slippi_desktop_app) $file
    #& sleep 3s
	# job2kill=$(ps axf --sort time | grep slippi-desktop-app | grep -v grep | awk '{print $1}')
	# while [ -z $job2kill ]; do
	# 	sleep 1s
	# 	job2kill=$(ps axf --sort time | grep slippi-desktop-app | grep -v grep | grep r18_$5 | awk '{print $1}')
	# done
	# kill -9 $job2kill
}


function process_slp_files_in_folder {
    for file in ${path_to_slp_files}/*; do
        #$(basename $file) to get only filename, not full path
        echo -e $file

        record_file $file


    done

}


init
process_slp_files_in_folder



