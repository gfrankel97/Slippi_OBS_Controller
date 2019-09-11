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

    echo -e "[${COLOR_GREEN}Settings Validated${COLOR_NONE}]: $(pwd)/settings/settings.json"
}

function init {
    #Kill running Slippi Desktop App and Dolphin instances
    ps axf | grep slippi-desktop-app | grep -v grep | awk '{print "kill -9 " $1}' | sh | at now &> /dev/null
    ps axf | grep dolphin-emu | grep -v grep | awk '{print "kill -9 " $1}' | sh | at now &> /dev/null

    #Validate settings and set variables
    validate_and_set_settings

    #Copy Slippi Desktop App settings from script to application
    cp "$(pwd)/settings/slippi_desktop_app_settings.json" "${path_to_slippi_desktop_app_data_dir}/Settings"

    #Copy Dolphin.ini settings from script to application
    cp "$(pwd)/settings/dolphin_settings.ini" "${path_to_dolphin_app_config_dir}/Dolphin.ini"
    cp "$(pwd)/settings/dolphin_gfx_settings.ini" "${path_to_dolphin_app_config_dir}/GFX.ini"

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

    echo "TO RETURN: "${dump_folder}/Frames/$(ls -t ${dump_folder}/Frames/ | head -1)
    echo "TO RETURN: "${dump_folder}/Audio/dspdump.wav
    current_avi_file="${dump_folder}/Frames/$(ls -t ${dump_folder}/Frames/ | head -1)"
    current_audio_file_wav="${dump_folder}/Audio/dspdump.wav"
}

function convert_wav_and_avi_to_mp4 {
    local avi_file=$1
    local mp3_file=$2
    

    echo "Starting: ${output_dir}/${original_file_name}.mp4"

    ffmpeg -y -i ${avi_file} -i ${mp3_file} -filter_complex '[0:v]scale=1168:960'  "${output_dir}/${original_file_name}.mp4" > /dev/null
    # ffmpeg -y -i $mp3_file -itsoffset $input_offset -i $avi_file -map 1:v -map 0:a -c:a? copy -c:v copy "${output_dir}/${original_file_name}.mp4"
    # ffmpeg -y -i $mp3_file -itsoffset $input_offset -i $avi_file -map 1:v -map 0:a -c:a? copy -c:v copy "${output_dir}/${original_file_name}.mp4"
}

function convert_wav_to_mp3 {
    local audio_file=$1

    mkdir "${output_dir}/temp"

    ffmpeg -y -i ${audio_file} "${output_dir}/temp/temp.mp3" > /dev/null
    current_audio_file_mp3="${output_dir}/temp/temp.mp3"
}

function process_slp_files_in_folder {
    for file in ${path_to_slp_files}/*; do
        if test -f $file; then
            original_file_name=$(basename $file | cut -f1 -d '.')
            echo -e "[${COLOR_GREEN}Clean - File Recording${COLOR_NONE}]: Output and Temp directories cleaned successfully"
            clean_dump_dir

            echo -e "[${COLOR_GREEN}Start - File Recording${COLOR_NONE}]: ${original_file_name}"
            record_file $file

            if [ $? -ne 0 ];then
                echo -e "[${COLOR_RED}Failed - File Recording${COLOR_NONE}]: ${original_file_name}"
            fi
            echo -e "[${COLOR_GREEN}Finish - File Recording${COLOR_NONE}]: ${original_file_name}"
            echo -e "[${COLOR_GREEN}Start - Audio Conversion${COLOR_NONE}]: Convert audio format from WAV to MP3"
            convert_wav_to_mp3 $current_audio_file_wav
            echo -e "[${COLOR_GREEN}Finish - Audio Conversion${COLOR_NONE}]: Convert audio format from WAV to MP3"

            echo -e "[${COLOR_GREEN}Start - File Combine${COLOR_NONE}]: Combine AVI and MP3 to create output file: ${output_dir}/${original_file_name}.mp4"
            convert_wav_and_avi_to_mp4 $current_avi_file $current_audio_file_mp3
            echo -e "[${COLOR_GREEN}Finish - File Combine${COLOR_NONE}]: Combine AVI and MP3 to create output file: ${output_dir}/${original_file_name}.mp4"





        fi
    done


    echo -e "[${COLOR_GREEN}Script Complete${COLOR_NONE}]: Exiting Successfully"
}


init
process_slp_files_in_folder
exit 0



