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

    output_dir=$(jq -r .output_dir $(pwd)/settings/settings.json)
    if [[ $output_dir = null ]]; then
        echo -e "[${COLOR_RED}Setting Missing${COLOR_NONE}]: Setting not found (check settings.json - output_dir)"
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

    resolution_scale_factor=$(jq -r .resolution_scale_factor $(pwd)/settings/settings.json)
    if [[ $resolution_scale_factor = null ]]; then
        echo -e "[${COLOR_YELLOW}Setting Missing${COLOR_NONE}]: Setting not found (check settings.json - resolution_scale_factor), defaulting to '${COLOR_BLUE}2${COLOR_NONE}'"
        resolution_scale_factor="2"
    fi

    if [[ ! -f "$(pwd)/settings/dolphin_settings.ini" ]]; then
        echo -e "[${COLOR_RED}File Missing${COLOR_NONE}]: dolphin_settings.ini"
        exit 1
    fi

    if [[ ! -f "$(pwd)/settings/dolphin_gfx_settings.ini" ]]; then
        echo -e "[${COLOR_RED}File Missing${COLOR_NONE}]: dolphin_gfx_settings.ini"
        exit 1
    fi

    if [[ ! -f "$(pwd)/settings/slippi_desktop_app_settings.json" ]]; then
        echo -e "[${COLOR_RED}File Missing${COLOR_NONE}]: slippi_desktop_app_settings.json"
        exit 1
    else
        dolphin_bin=$(jq -r .settings.playbackDolphinPath $(pwd)/settings/slippi_desktop_app_settings.json)/dolphin-emu
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

    echo -e "\t[${COLOR_GREEN}Settings Validated${COLOR_NONE}]: $(pwd)/settings/settings.json"
}

function init {
    echo -e "[${COLOR_GREEN}Script Init - Start${COLOR_NONE}]"
    #Kill running Slippi Desktop App and Dolphin instances
    ps axf | grep slippi-desktop-app | grep -v grep | awk '{print "kill -9 " $1}' | sh | at now &> /dev/null
    ps axf | grep dolphin-emu | grep -v grep | awk '{print "kill -9 " $1}' | sh | at now &> /dev/null

    #Validate settings and set variables
    validate_and_set_settings

    cp "$(pwd)/settings/slippi_desktop_app_settings.json" "${path_to_slippi_desktop_app_data_dir}/Settings"
    echo -e "\t[${COLOR_GREEN}Settings Copied${COLOR_NONE}]: Copy settings/slippi_desktop_app_settings.json to Slippi Desktop App directory"

    cp "$(pwd)/settings/dolphin_settings.ini" "${path_to_dolphin_app_config_dir}/Dolphin.ini"
    echo -e "\t[${COLOR_GREEN}Settings Copied${COLOR_NONE}]: Copy settings/dolphin_settings.ini to Dolphin"
    cp "$(pwd)/settings/dolphin_gfx_settings.ini" "${path_to_dolphin_app_config_dir}/GFX.ini"
    echo -e "\t[${COLOR_GREEN}Settings Copied${COLOR_NONE}]: Copy GFX settings/dolphin_gfx_settings.ini to Dolphin"

    echo -e "[${COLOR_GREEN}Script Init - Complete${COLOR_NONE}]\n"
}

function clean_dump_dir {
    rm -f "${path_to_dolphin_app_user_dir}/Logs/render_time.txt"
    rm -f "${path_to_dolphin_app_user_dir}/Dump/Frames/*"
    rm -f "${path_to_dolphin_app_user_dir}/Dump/Audio/*"
    rm -f "${path_to_dolphin_app_user_dir}/Dump/Audio/dspdump.wav"
    rm -rf ${output_dir}/temp
	mkdir -p "${path_to_dolphin_app_user_dir}/Dump/Frames"
    mkdir ${output_dir}/temp
}


function record_file {
    # RETURNS OUTPUT FILE PATH
    local slp_file=$1
    local frames_file="${path_to_dolphin_app_user_dir}/Logs/render_time.txt"
    local dump_folder="${path_to_dolphin_app_user_dir}/Dump"

    #Get frames in Slippi file
    # TODO: Pull out this into its own function
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
	local frame_count="$((16#$a * 256 + 16#$b))"
	local d="$((10 + $frame_count / 60))"
	#echo "$d"

    # Launch slippi desktop app so it will launch dolphin, then kill slippi desktop app
    # TODO: Find better way to get PID to kill

	$path_to_slippi_desktop_app $file | at now &> /dev/null & sleep 3s
	local slippi_desktop_app_process=$(ps axf --sort time | grep slippi-desktop-app | grep -v grep | awk 'NR==1{print $1}')
	while [ -z $slippi_desktop_app_process ]; do
		sleep 1s
		slippi_desktop_app_process=$(ps axf --sort time | grep slippi-desktop-app | grep -v grep | grep $file | awk 'NR==1{print $1}')
	done
	kill -9 $slippi_desktop_app_process | at now &> /dev/null

    # Wait for the render_time.txt file to be created by dolphin
    while ! test -f $frames_file; do 
		sleep 1s
		echo "Waiting in job: ${file} for file ${frames_file}"
	done


	local current_frame=$(grep -vc '^$' $frames_file)
	local frame_count="$(($frame_count + 298))"


	# Run until the number of frames rendered is the length of the slippi file
	local timeout=$((SECONDS+490))
	while [ "$current_frame" -lt $frame_count ]
	do
		current_frame=$(grep -vc '^$' $frames_file)
    
		#Timeout loop after 8 minutes
		if [ $SECONDS -gt $timeout ]; then
			break
		fi
	done

    local dolphin_process=$(ps axf --sort time | grep dolphin-emu | grep -v grep  | awk '{print $1}')
	kill -9 $dolphin_process | at now &> /dev/null

    current_avi_file="${dump_folder}/Frames/$(ls -t ${dump_folder}/Frames/ | head -1)"
    current_audio_file_wav="${dump_folder}/Audio/dspdump.wav"
}

function set_video_filter {
    echo -e "\t[${COLOR_GREEN}Set FFmpeg Filter - Start${COLOR_NONE}]"
    local log_resolution=""
    case ${resolution_scale_factor} in 
        "1")
            video_filter="scale=584:480,pad=853:480:135"
            log_resolution="853x480 (SD)"
            ;;
        "2")
            video_filter="scale=876:720,pad=1280:720:202"
            log_resolution="1280x720 (HD 720p)"
            ;;
        "3")
            video_filter="scale=1314:1080,pad=1920:1080:303"
            log_resolution="1920x1080 (HD 1080p)"
            ;;
        *)
            echo -e "[${COLOR_GREEN}Error Scaling - File Recording${COLOR_NONE}]: Scale factor must be one of: '1', '2', '3'"
            exit 1
            ;;
    esac
    echo -e "\t[${COLOR_GREEN}Set FFmpeg Filter - Finish${COLOR_NONE}]: set to ${COLOR_BLUE}${log_resolution}${COLOR_NONE}"
}

function convert_wav_and_avi_to_mp4 {
    local avi_file=$1
    local wav_file=$2

    set_video_filter
    ffmpeg -loglevel panic -y -i ${avi_file} -i ${wav_file} -filter_complex "[0:v]${video_filter}" "${output_dir}/${original_file_name}.mp4"
}


function process_slp_files_in_folder {
    for file in ${path_to_slp_files}/*; do
        if test -f $file; then
            original_file_name=$(basename $file | cut -f1 -d '.')
            echo -e "[${COLOR_GREEN}File Recording - Init${COLOR_NONE}]: Output and Temp directories cleaned successfully"
            clean_dump_dir

            echo -e "[${COLOR_GREEN}File Recording - Start${COLOR_NONE}]: ${original_file_name}"
            record_file $file

            if [ $? -ne 0 ];then
                echo -e "\t[${COLOR_RED}Failed - File Recording${COLOR_NONE}]: ${original_file_name}"
            fi
            echo -e "[${COLOR_GREEN}File Recording - Finish${COLOR_NONE}]: ${original_file_name}\n"

            echo -e "[${COLOR_GREEN}Combine Audio and Video - Start${COLOR_NONE}]: Combine AVI and WAV from Dolphin dump to create output file: ${output_dir}/${original_file_name}.mp4"
            convert_wav_and_avi_to_mp4 $current_avi_file $current_audio_file_wav
            echo -e "[${COLOR_GREEN}Combine Audio and Video - Finish${COLOR_NONE}]: Combine AVI and WAV from Dolphin dump to create output file: ${output_dir}/${original_file_name}.mp4"
        fi
    done


    echo -e "[${COLOR_GREEN}Script Complete${COLOR_NONE}]: Exiting Successfully"
}


init
process_slp_files_in_folder
exit 0



