#!/bin/bash

function recordsingle {
	local file=$1
	local username=$(whoami)

	# Get the number of frames in the slippi file
	local offset=$(strings -d -t d -n 9 $file | grep -A1 'lastFramel' | grep -v "lastFramel"| cut -d: -f1 | cut -d ' ' -f1)
	offset="$(($offset - 4))"
	if [ "$offset" -eq -4 ]; then
		offset=$(strings -d -t d -n 9 $file | grep -A1 'lastFramel' | grep -v "lastFramel" | cut -d ' ' -f2 | cut -d: -f1 | cut -d ' ' -f1)
		offset="$(($offset - 4))"
	fi
	echo "$offset"
	local a=$(xxd -p -l1 -s $offset $file)
	offset="$(($offset + 1))"
	local b=$(xxd -p -l1 -s $offset $file)
	echo "$a"
	echo "$b"
	local c="$((16#$a * 256 + 16#$b))"
	echo "$c"
	local d="$((10 + $c / 60))"
	echo "$d"
	cp $startfolder/Slippi-FM-r18_$5/playback/Dolphin.ini $startfolder/Slippi-FM-r18_$5/playback/User/Config/Dolphin.ini 
	local framesFile=$startfolder/Slippi-FM-r18_$5/playback/User/Logs/render_time.txt
        local dumpFolder=$startfolder/Slippi-FM-r18_$5/playback/User/Dump
        local dumpFile=$dumpFolder/Frames/frame*
        local audioFiles=$dumpFolder/Audio/*
        local audioFile=$dumpFolder/Audio/dspdump.wav
	rm -f $framesFile
        rm -f $dumpFile
        rm -f $audioFiles
        rm -f $audioFile
	mkdir -p $dumpFolder/Frames

	# Launch slippi desktop app so it will launch dolphin, then kill slippi desktop app
	slippi-desktop-app ./$file & sleep 3s
	job2kill=$(ps axf --sort time | grep slippi-desktop-app | grep -v grep | awk '{print $1}')
	while [ -z $job2kill ]; do
		sleep 1s
		job2kill=$(ps axf --sort time | grep slippi-desktop-app | grep -v grep | grep r18_$5 | awk '{print $1}')
	done
	kill -9 $job2kill

	# Wait for the render_time.txt file to be created by dolphin
        while ! test -f $framesFile; do 
		sleep 1s
		echo -n "Waiting in job "
        	echo "$5"
	done
	echo -n "Found render_time.txt in job "
	echo "$5"

	job2kill=$(ps axf --sort time | grep dolphin-emu | grep -v grep | grep r18_$5 | awk '{print $1}')
	local e=$(jobs -p)
	echo "job2kill value: "
	echo "$job2kill"
	echo "$framesFile"
	local f=$(grep -vc '^$' $framesFile)
	c="$(($c + 298))"
	
	# Run until the number of frames rendered is the length of the slippi file
	local end=$((SECONDS+490))
	while [ "$f" -lt $c ]
	do
		f=$(grep -vc '^$' $framesFile)

		#if something goes wrong, the loop will break after 8 minutes
		if [ $SECONDS -gt $end ]; then
			break
		fi
	done

	echo -n "killing pid : "
	echo "$job2kill"
	echo -n "in job "
	echo "$5"
	kill -9 $job2kill

	rm -f $framesFile

	# Copy and rename the dumped files
	local obsoutdir=$dumpFolder/Frames/
	local obsout=$(ls -t $obsoutdir | head -1)
	echo "Frames file:"
	echo "$obsout"
	pushd .
	cd ..
	local outfile="${PWD##*/}"
	popd
	outfile="$outfile_${PWD##*/}"
	outfile=$(echo $outfile | tr [:space:] _ | tr [ _ | tr ] _)
	outfile="$outfile$3"
	outfile="$outfile.avi"
	echo "$outfile"
	rm -f $4$outfile
	touch $4$outfile
	cp $dumpFolder/Frames/$obsout $4$outfile
        cp $audioFile $4$outfile-audio
	rm -rf $dumpFolder/Frames/
        rm -f $audioFiles
        rm -f $audioFile
	jobnum=$(cat $startfolder/jobs.txt)
	jobnum="$(($jobnum - 1))"
	rm -f $startfolder/jobs.txt
	echo "$jobnum" > $startfolder/jobs.txt
}

function checksingle {
	local file=$1
	local username=$(whoami)
	local offset=$(strings -d -t d -n 9 $file | grep -A1 'lastFramel' | grep -v "lastFramel"| cut -d: -f1 | cut -d ' ' -f1)
	local offset="$(($offset - 4))"
	if [ "$offset" -eq -4 ]; then
		offset=$(strings -d -t d -n 9 $file | grep -A1 'lastFramel' | grep -v "lastFramel" | cut -d ' ' -f2 | cut -d: -f1 | cut -d ' ' -f1)
		offset="$(($offset - 4))"
	fi
	if [ "$offset" -eq -4 ]; then
		echo -n "Removing "
		echo "$1"
		rm -f $1
	fi
	echo "$offset"
	local a=$(xxd -p -l1 -s $offset $file)
	offset="$(($offset + 1))"
	local b=$(xxd -p -l1 -s $offset $file)
	echo "$a"
	echo "$b"
	local c="$((16#$a * 256 + 16#$b))"
	echo "$c"
	if [ "$c" -lt 1600 ]; then
		echo -n "Removing "
		echo "$1"
		rm -f $1
	fi
}

function audioencodesingle {
	ifile=$1
	outfolder=$2
	encodefolder=$3
	local iname=$(echo "$ifile" | cut -d. -f1)
	ffmpeg -y -i $outfolder$iname.avi-audio -c:a mp3 $outfolder$iname.mp3
}

function videoencodesingle {
	ifile=$1
	outfolder=$2
	encodefolder=$3
	local iname=$(echo "$ifile" | cut -d. -f1)
	ffmpeg -y -i $outfolder$iname.mp3 -itsoffset 1.55 -i $outfolder$iname.avi -map 1:v -map 0:a -c:a? copy -c:v copy $encodefolder$iname.mp4
        rm -f $outfolder$iname.mp3
	rm -f $ifile
        rm -f $ifile-audio
}


startfolder=$PWD
stringsfile=$PWD/strings64.exe
outfolder=$PWD/$1out/
encodefolder=$PWD/$1encoded/
combinedfolder=$PWD/$1combined/

cp ./Settings ~/.config/Slippi\ Desktop\ App/Settings

rm -rf jobs.txt

rm -rf $outfolder
mkdir $outfolder

rm -rf $encodefolder
mkdir $encodefolder

rm -rf $combinedfolder
mkdir $combinedfolder


#Remove bad friendlies
for j in $startfolder/$1/*/ ; do
	if [ $(basename $j) == "unparsed" ] 
	then
		continue
	fi
	for k in $j/* ; do
		cd $j
		k=$(basename $k)
		echo "$k"
		checksingle $k $stringsfile $gamenum $outfolder $jobnum
		cd $startfolder
	done
done

cd $startfolder

ps axf | grep slippi-desktop-app | grep -v grep | awk '{print "kill -9 " $1}' | sh
ps axf | grep dolphin-emu | grep -v grep | awk '{print "kill -9 " $1}' | sh

# For each folder in the specified path
for h in $startfolder/$1/*/ ; do
	if [ $(basename $h) == "unparsed" ] 
	then
		continue
	fi 
	gamenum=1
	jobnum=1
	jobalive=1
	cp ./Settings ~/.config/Slippi\ Desktop\ App/Settings

        # For each slippi file in the folder
	for g in $h/* ; do
		cd $h

		# Set the dolphin path to run the slippi file
		rm -f $startfolder/testSettings3.txt
		if [ "$jobnum" -eq "1" ]; then
			echo "$(cat ~/.config/Slippi\ Desktop\ App/Settings | sed -E 's/r18_1\/|r18_2\/|r18_3\/|r18_4\/|r18_5\//r18_1\//g')" > $startfolder/testSettings3.txt
			cp $startfolder/testSettings3.txt ~/.config/Slippi\ Desktop\ App/Settings
		fi
		if [ "$jobnum" -eq "2" ]; then
			echo "$(cat ~/.config/Slippi\ Desktop\ App/Settings | sed -E 's/r18_1\/|r18_2\/|r18_3\/|r18_4\/|r18_5\//r18_2\//g')" > $startfolder/testSettings3.txt
			cp $startfolder/testSettings3.txt ~/.config/Slippi\ Desktop\ App/Settings
		fi
		if [ "$jobnum" -eq "3" ]; then
			echo "$(cat ~/.config/Slippi\ Desktop\ App/Settings | sed -E 's/r18_1\/|r18_2\/|r18_3\/|r18_4\/|r18_5\//r18_3\//g')" > $startfolder/testSettings3.txt
			cp $startfolder/testSettings3.txt ~/.config/Slippi\ Desktop\ App/Settings
		fi
		if [ "$jobnum" -eq "4" ]; then
			echo "$(cat ~/.config/Slippi\ Desktop\ App/Settings | sed -E 's/r18_1\/|r18_2\/|r18_3\/|r18_4\/|r18_5\//r18_4\//g')" > $startfolder/testSettings3.txt
			cp $startfolder/testSettings3.txt ~/.config/Slippi\ Desktop\ App/Settings
		fi
		if [ "$jobnum" -eq "5" ]; then
			echo "$(cat ~/.config/Slippi\ Desktop\ App/Settings | sed -E 's/r18_1\/|r18_2\/|r18_3\/|r18_4\/|r18_5\//r18_5\//g')" > $startfolder/testSettings3.txt
			cp $startfolder/testSettings3.txt ~/.config/Slippi\ Desktop\ App/Settings
		fi
		rm -f $startfolder/testSettings3.txt

		# Spawn a job to record the file
		g=$(basename $g)
		recordsingle $g $stringsfile $gamenum $outfolder $jobnum &
		gamenum="$(($gamenum + 1))"
                jobnum="$(($jobnum + 1))"
		jobalive="$(($jobalive + 1))"
		echo "$jobalive" > $startfolder/jobs.txt
		cd $startfolder

		# Track jobs
		totalInDir=$(ls 2>/dev/null -Ubad1 -- $h* | wc -l)
		totalInDir="$(($totalInDir + 1))"
		oldjobnum="$(($jobnum - 1))"
		jobnum=$oldjobnum
		while [ "$jobnum" -eq "$oldjobnum" ]; do
			for i in 1 2 3 4 5
			do
				isjobalive=$(ps axf | grep dolphin-emu | grep r18_$i | wc -l)
				if [ "$isjobalive" -eq "0" ] && [ "$i" -ne "$oldjobnum" ]; then
					jobnum=$i
					break
				fi
			done
			sleep 1s
			echo "Waiting for new job..."
		done
		isjobalive=$(ps axf | grep dolphin-emu | grep r18_$i | wc -l)
		if [ "$isjobalive" -gt "1" ]; then
			sleep 11s
		else
			sleep 6s
		fi
		
		isjobalive=$(ps axf | grep dolphin-emu | grep r18 | wc -l)
		jobsLeft="$(($totalInDir - $gamenum))"
   		while [ "$isjobalive" -gt "0" ] && [ "$gamenum" -eq "$totalInDir" ]; do
        		sleep 1s
			isjobalive=$(ps axf | grep dolphin-emu | grep r18 | wc -l)
		done
		if [ "$gamenum" -eq "$totalInDir" ]; then
			wait
		fi
	done


	ps axf | grep slippi-desktop-app | grep -v grep | awk '{print "kill -9 " $1}' | sh
	ps axf | grep dolphin-emu | grep -v grep | awk '{print "kill -9 " $1}' | sh
	
	sleep 5s

	# Use ffmpeg to encode the audio to mp3 and encode the video with the audio
	cd $startfolder
	for ifile in $(ls $outfolder *.avi) ; do
		audioencodesingle $ifile $outfolder $encodefolder &
	done
	wait
	for ifile in $(ls $outfolder *.avi) ; do
		videoencodesingle $ifile $outfolder $encodefolder &
	done
	wait

	rm -rf $outfolder
	mkdir $outfolder

	# Combine all the video files with the same parent folder in order
	for ifile in $(ls $encodefolder) ; do
		iname=$(echo "$ifile" | cut -d. -f1)
		setnamenumber=$(echo "$ifile")
		setname=$(echo "$setnamenumber" | cut -d_ -f-$(echo "$setnamenumber" | grep -o "_" | wc -l))
		filelist=$(find $encodefolder -name "$setname*.mp4" | sort -V)
		rm -f ./temp.txt
		for file in $filelist ; do 
			echo "file '$(echo "$file")" >> ./temp.txt
		done
		ffmpeg -y -safe 0 -f concat -i temp.txt -c copy $combinedfolder$setname.mp4
		for file in $filelist ; do 
			rm -f $file
		done
	done

	sleep 20s

done



