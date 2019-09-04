const readline = require('readline');
const fs = require('fs');
const { askQuestion } = require('./ask.js');
const script_settings = require('./settings.json');

const process_reader = create_reader_interface();
let current_slippi_file;
let clip_queued = false;
let clip_data = null;
let game_meta = null;

function create_reader_interface() {
    return readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });
}

validate_time = time => RegExp(`[0-8]:[0-6][0-9]`).test(time);

validate_character = character => character === '1' || character === '2';

get_character_info = async() => {
    const characterInput = await askQuestion(process_reader,  `    Press 1 for ${game_meta.character1} or 2 for ${game_meta.character2}: \n`);

    if (!validate_character(characterInput)) return get_character_info();
    return characterInput === '1' ? game_meta.character1 : game_meta.character2;
}


get_time_info = async() => {
    const timeInput = await askQuestion(process_reader, `In-Game Time (format: m:ss): \n`)

    if (!validate_time(timeInput)) return get_time_info();
    return timeInput.replace(':', '.');
}

get_clip_information = () => {
    return new Promise(async (resolve) => {
        const character = await get_character_info();
        const time = await get_time_info();
        resolve({ character, time });
    });
}

prompt_for_clip = () => {
    process_reader.question(`Hit Enter to clip it.\n`, async() => {
        clip_data = await get_clip_information();
        clip_queued = true;
        console.log("Clip successfully queued. It will be created at the end of the game.");
    })
}

create_clip = (clip_information) => {
    let clip_file_path = `${script_settings.SLIPPI_CLIPS_FILE_PATH}\\${clip_information.character}_${game_meta.stage}_${clip_information.time}`;
    let counter = 1;
    while(fs.existsSync(clip_file_path)) {
        console.log(clip_file_path, "already exists, renaming to: ", clip_file_path + "_" + counter + ".slp")
        clip_file_path = clip_file_path + "_" + counter;
        counter++;
    }
    //check if file exists, if so, append something
    //wait til game has finished to copy file
    fs.copyFileSync(current_slippi_file, clip_file_path + ".slp");
    clip_queued = false;
}

process.on('message', message => {
    switch(message.message_type) {
        case "new_game":
            current_slippi_file = message.current_slippi_file;
            game_meta = message.game_meta;
            prompt_for_clip();
            break;
        case "check_for_clip":
            if(clip_queued) {
                create_clip(clip_data);
            }
            break;
        case "prompt_for_clip":
            prompt_for_clip();
            break;
        default:
            break;
    }
});

