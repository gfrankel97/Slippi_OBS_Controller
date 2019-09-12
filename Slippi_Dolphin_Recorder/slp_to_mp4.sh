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

    path_to_dolphin_base=$(jq -r .path_to_dolphin_base $(pwd)/settings/settings.json)
    if [[ $path_to_dolphin_base = null ]]; then
        echo -e "[${COLOR_RED}Setting Missing${COLOR_NONE}]: Setting not found (check settings.json - path_to_dolphin_base)"
        exit 1
    fi

    path_to_dolphin_temp=$(jq -r .path_to_dolphin_temp $(pwd)/settings/settings.json)
    if [[ $path_to_dolphin_temp = null ]]; then
        echo -e "[${COLOR_RED}Setting Missing${COLOR_NONE}]: Setting not found (check settings.json - path_to_dolphin_temp)"
        exit
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

    parallelism=$(jq -r .parallelism $(pwd)/settings/settings.json)
    if [[ $parallelism = null ]]; then
        echo -e "[${COLOR_RED}Setting Missing${COLOR_NONE}]: Setting not found (check settings.json - parallelism)"
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

    cp "$(pwd)/settings/dolphin_settings.ini" "${path_to_dolphin_base}/User/Config/Dolphin.ini"
    echo -e "\t[${COLOR_GREEN}Settings Copied${COLOR_NONE}]: Copy settings/dolphin_settings.ini to Dolphin"
    cp "$(pwd)/settings/dolphin_gfx_settings.ini" "${path_to_dolphin_base}/User/Config/GFX.ini"
    echo -e "\t[${COLOR_GREEN}Settings Copied${COLOR_NONE}]: Copy GFX settings/dolphin_gfx_settings.ini to Dolphin"


    ls ${path_to_slp_files} | grep slp > dolphin_jobs.txt
    echo -e "\t[${COLOR_GREEN}Job List Created${COLOR_NONE}]: Created dolphin_jobs.txt (a list of slp files to record)"
 
    set_video_filter
 
    echo -e "[${COLOR_GREEN}Script Init - Complete${COLOR_NONE}]\n"
    
}

function clean_dump_dir {
    local dolphin_path=$1
    rm -f "${dolphin_path}/User/Logs/render_time.txt"
    rm -f "${dolphin_path}/User/Dump/Frames/*"
    rm -f "${dolphin_path}/User/Dump/Audio/*"
    rm -f "${dolphin_path}/User/Dump/Audio/dspdump.wav"
    rm -rf ${output_dir}/temp
	mkdir -p "${dolphin_path}/User/Dump/Frames"
    mkdir ${output_dir}/temp
}

function set_slippi_desktop_app_parallel_dolphin_bin {
    local dolphin_path=$1
    cat $(pwd)/settings/slippi_desktop_app_settings.json | jq -r --arg current_parallel_dolphin_path "$dolphin_path" '.settings.playbackDolphinPath = $current_parallel_dolphin_path' > "${path_to_slippi_desktop_app_data_dir}/Settings"
}

function record_file {
    local slp_file=$1
    local dolphin_path=$2
    local frames_file="${dolphin_path}/User/Logs/render_time.txt"
    local dump_folder="${dolphin_path}/User/Dump"

    #Get frames in Slippi file
    # TODO: Pull out this into its own function
    local offset=$(strings -d -t d -n 9 $slp_file | grep -A1 'lastFramel' | grep -v "lastFramel"| cut -d: -f1 | cut -d ' ' -f1)
    offset="$(($offset - 4))"
    if [ "$offset" -eq -4 ]; then
        offset=$(strings -d -t d -n 9 $slp_file | grep -A1 'lastFramel' | grep -v "lastFramel" | cut -d ' ' -f2 | cut -d: -f1 | cut -d ' ' -f1)
        offset="$(($offset - 4))"
    fi
    #echo "$offset"
    local a=$(xxd -p -l1 -s $offset $slp_file)
	offset="$(($offset + 1))"
	local b=$(xxd -p -l1 -s $offset $slp_file)
	#echo "$a"
	#echo "$b"
	local frame_count="$((16#$a * 256 + 16#$b))"
	local d="$((10 + $frame_count / 60))"
	#echo "$d"

    # Launch slippi desktop app so it will launch dolphin, then kill slippi desktop app
    # TODO: Find better way to get PID to kill
    clean_dump_dir $dolphin_path
    echo -e "\t[${COLOR_GREEN}File Recording - Init${COLOR_NONE}]: Output and Temp directories cleaned successfully"
    echo -e "\t[${COLOR_GREEN}File Recording - Init${COLOR_NONE}]: Parallel Dolphin Playback path set to ${current_parallel_dolphin_path}"
    set_slippi_desktop_app_parallel_dolphin_bin $dolphin_path
    echo -e "\t[${COLOR_GREEN}File Recording - Init${COLOR_NONE}]: Slippi Desktop App set to use: ${current_parallel_dolphin_path}"
    echo -e "[${COLOR_GREEN}File Recording - Init Finish${COLOR_NONE}]\n"
    echo -e "[${COLOR_GREEN}File Recording - Start${COLOR_NONE}]: ${COLOR_BLUE}${file}${COLOR_NONE}"
	$path_to_slippi_desktop_app $slp_file | at now &> /dev/null & sleep 3s
    
	local slippi_desktop_app_process=$(ps axf --sort time | grep slippi-desktop-app | grep -v grep | awk 'NR==1{print $1}')
	while [ -z $slippi_desktop_app_process ]; do
		sleep 1s
		slippi_desktop_app_process=$(ps axf --sort time | grep slippi-desktop-app | grep -v grep | grep $slp_file | awk 'NR==1{print $1}')
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

    echo -e "\n[${COLOR_GREEN}File Recording - Finish${COLOR_NONE}]: ${file}\n"

    local dolphin_process=$(ps axf --sort time | grep dolphin-emu | grep -v grep | grep $dolphin_path | awk '{print $1}')
	kill -9 $dolphin_process | at now &> /dev/null

    local current_avi_file="${dump_folder}/Frames/$(ls -t ${dump_folder}/Frames/ | head -1)"
    local current_audio_file_wav="${dump_folder}/Audio/dspdump.wav"
    local base_file_name=$(basename $slp_file)

    sed -i "\:$base_file_name:d" dolphin_jobs.txt

    base_file_name=$(echo $base_file_name | cut -d'.' -f1)
    convert_wav_and_avi_to_mp4 $current_avi_file $current_audio_file_wav $base_file_name

}

function set_video_filter {
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
    echo -e "\t[${COLOR_GREEN}FFmpeg Filter Set ${COLOR_NONE}]: to ${COLOR_BLUE}${log_resolution}${COLOR_NONE}"
}

function ini_replace {
    local path_to_instance=$1
    local path_to_instance_dolphin_dump="${path_to_instance}/User/Dump"
    echo -e "\t[${COLOR_GREEN}Settings Replace - Start${COLOR_NONE}]:  ${path_to_instance}/User/Config/Dolphin.ini"
    sed -i.bak "s@DumpPath = .*@DumpPath = $path_to_instance_dolphin_dump@" "${path_to_instance}/User/Config/Dolphin.ini"
    echo -e "\t[${COLOR_GREEN}Settings Replace - Finish${COLOR_NONE}]: ${path_to_instance}/User/Config/Dolphin.ini"
}

function init_parallelism {
    echo -e "[${COLOR_GREEN}Init Parallelism - Start${COLOR_NONE}]"
    for ((index=1;index<=$parallelism;index++)); do
        rm -rf "${path_to_dolphin_temp}/playback_${index}"
        cp -rf "${path_to_dolphin_base}" "${path_to_dolphin_temp}/playback_${index}"
        ini_replace "${path_to_dolphin_temp}/playback_${index}"
    done

    set_path_to_parallel_dolphin
    echo -e "\t[${COLOR_GREEN}Init Parallelism${COLOR_NONE}]: Parallel Dolphin Playback path set to ${current_parallel_dolphin_path}"
    echo -e "[${COLOR_GREEN}Init Parallelism - Finish${COLOR_NONE}]\n"
}

function set_path_to_parallel_dolphin {
    for ((index=1;index<=$parallelism;index++)); do
        echo -e "\t[${COLOR_YELLOW}Init Parallelism${COLOR_NONE}]: Looking for running dolphin-emu: "$(ps axf | grep playback_${index}/dolphin-emu | grep -v grep | awk '{print $6}')
        if [ -z $(ps axf | grep playback_${index}/dolphin-emu | grep -v grep | awk '{print $6}') ] && [ -z $(ps axf | grep ffmpeg | grep playback_${index} | grep -v grep | awk '{print $6}')]; then
            current_parallel_dolphin_path="${path_to_dolphin_temp}/playback_${index}"
            break
        fi
        current_parallel_dolphin_path=""
    done
    
}

function can_exit {
    echo -e "\t[${COLOR_YELLOW}DEBUG${COLOR_NONE}]:  Can Exit (dolphin): $(ps axf | grep -v grep | grep dolphin-emu)"
    echo -e "\t[${COLOR_YELLOW}DEBUG${COLOR_NONE}]:  Can Exit (ffmpeg): $(ps axf | grep -v grep | grep ffmpeg)"
    echo -e "\t[${COLOR_YELLOW}DEBUG${COLOR_NONE}]:  Can Exit (dolphin_jobs) $(head -n 1 dolphin_jobs.txt)"
    
    if [ -z "$(ps axf | grep -v grep | grep dolphin-emu)" ] && [ -z "$(ps axf | grep -v grep | grep ffmpeg)" ] && [ -z "$(head -n 1 dolphin_jobs.txt)" ]; then
        echo -e "\tCAN EXIT"
        return 0
    else
        echo -e "\tCANT EXIT"
        return 1
    fi
}

function convert_wav_and_avi_to_mp4 {
    local avi_file=$1
    local wav_file=$2
    local output_file_name=$3

    echo -e "[${COLOR_GREEN}Combine Audio and Video - Start${COLOR_NONE}]: Combine AVI and WAV from Dolphin dump to create output file: ${COLOR_BLUE}${output_dir}/${output_file_name}.mp4${COLOR_NONE}"
    ffmpeg -loglevel panic -y -i ${avi_file} -i ${wav_file} -filter_complex "[0:v]${video_filter}" "${output_dir}/${output_file_name}.mp4"
    echo -e "[${COLOR_GREEN}Combine Audio and Video - Finish${COLOR_NONE}]: Combine AVI and WAV from Dolphin dump to create output file: ${COLOR_BLUE}${output_dir}/${output_file_name}.mp4${COLOR_NONE}"
}

function process_slp_files_in_folder {
    local file=$(head -n 1 dolphin_jobs.txt)
    while [ can_exit ]; do
        echo -e "\t[${COLOR_YELLOW}OUTER LOOP${COLOR_NONE}]: ${file}"

        # echo "FILE: ${file}"
        set_path_to_parallel_dolphin
        # OR CAN_EXIT
        while [ ! -z $current_parallel_dolphin_path ]; do
            echo -e "\t[${COLOR_YELLOW}INNER LOOP${COLOR_NONE}]: ${current_parallel_dolphin_path}"
            if [ ! -z $file ]; then
                echo -e "[${COLOR_GREEN}File Recording - Init Start${COLOR_NONE}]"
                record_file "${path_to_slp_files}/${file}" $current_parallel_dolphin_path &
                echo -e "\t[${COLOR_YELLOW}File Recording - Init Start${COLOR_NONE}]: ${current_parallel_dolphin_path}"
            fi


            sleep 5s
            local counter=0
            while [ $(ps axf | grep -v grep | grep -c 'dolphin-emu\|ffmpeg') -eq $parallelism ]; do
                if [ ! -z "$(ps axf |  grep -v grep | grep dolphin-emu)" ]; then
                    echo -ne "\t[${COLOR_GREEN}File Recording - Dump Dolphin Frames${COLOR_NONE}]: ${COLOR_BLUE}$(ps axf |  grep -v grep | grep -c dolphin-emu)${COLOR_NONE} Dolphin Instances running for ${COLOR_BLUE}${counter}s${COLOR_NONE}\r"
                fi
                if [ ! -z "$(ps axf |  grep -v grep | grep ffmpeg)" ]; then
                    echo -ne "\t[${COLOR_GREEN}File Recording - Video Encoding${COLOR_NONE}]: ${COLOR_BLUE}$(ps axf |  grep -v grep | grep -c ffmpeg)${COLOR_NONE} FFmpeg Instances running for ${COLOR_BLUE}${counter}s${COLOR_NONE}\r"
                fi
                counter=$((counter + 1))
                sleep 1s
            done
            echo -e "\n"


            # ## Wait for dolphin to be up
            # sleep 5s
            # local dolphin_counter=0
            # # Wait for dolphin to be killed
            # while [ ! -z "$(ps axf | grep -v grep | grep dolphin-emu)" ]; do
            #     echo -ne "\t[${COLOR_GREEN}File Recording - Dump Dolphin Frames${COLOR_NONE}]: running for ${COLOR_BLUE}${dolphin_counter}s${COLOR_NONE}\r"
            #     sleep 5s
            #     dolphin_counter=$((dolphin_counter + 5))
            # done
            # echo -e "\n"

            # sleep 5s
            # local ffmpeg_counter=0
            # # Wait for FFmpeg to be complete
            # while [ ! -z "$(ps axf | grep -v grep | grep ffmpeg)" ]; do
            #     echo -ne "\t[${COLOR_GREEN}File Recording - Video Encoding${COLOR_NONE}]: running for ${COLOR_BLUE}${ffmpeg_counter}s${COLOR_NONE}\r"
            #     sleep 5s
            #     ffmpeg_counter=$((ffmpeg_counter + 5))
            # done
            # echo -e "\n"

            local file=$(head -n 1 dolphin_jobs.txt)
        done

        local file=$(head -n 1 dolphin_jobs.txt)
    done


    echo -e "[${COLOR_GREEN}Script Complete${COLOR_NONE}]: Exiting Successfully"
}


init
init_parallelism
process_slp_files_in_folder
exit 0



