I have included the dolphin and slippi configurations as well as the run script that I use. The other dependencies are:

Slippi-FM-r18
	https://github.com/project-slippi/Slippi-FM-installer
	Follow the instructions in that readme

Slippi desktop app
	https://www.slippi.gg/downloads

ffmpeg
	http://ffmpeg.org/download.html?aemtn=tg-on#build-linux

Configure slippi desktop app to point to your melee iso and the dolphin path

## TODO ^ Automate

Once Slippi-FM-r18 is built, copy it 5 times with '_1', '_2', etc. appended to the top-level 
folder. 

Any paths in these configurations may or may not work for you. You will need to change any paths. The provided Dolphin.ini will need to be reaccomodated to each new copy of Slippi-FM-r18.


To run the script:

./run.sh Name_of_Event


The folder structure is:

./Name_of_Event/Winners_Round_1_Player_X_v_Player_Y/Game_01234.slp


