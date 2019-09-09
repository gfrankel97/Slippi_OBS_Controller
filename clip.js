const readline = require('readline');
const fs = require('fs');
const chalk = require('chalk');
const { askQuestion } = require('./ask.js');
const script_settings = require('./settings.json');

const process_reader = create_reader_interface();
let current_slippi_file;
let clip_queued = false;
let clip_data = null;
let game_meta = null;
let characterInput = null;


function create_reader_interface() {
    return readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });
}

validate_time = time => RegExp(`[0-8]:[0-6][0-9]`).test(time);

validate_character = character => character === '1' || character === '2';

get_character_info = async() => {
    characterInput = await askQuestion(process_reader,  `    Press 1 for ${game_meta.character1} or 2 for ${game_meta.character2}: `);

    if (!validate_character(characterInput)) return get_character_info();
    return characterInput === '1' ? game_meta.character1 : game_meta.character2;
}


get_time_info = async() => {
    const timeInput = await askQuestion(process_reader, `    In-Game Time (format: m:ss): `)

    if (!validate_time(timeInput)) return get_time_info();
    return timeInput.replace(':', '.');
}

get_tag_info = () => {
    return characterInput === '1' ? game_meta.tag1 : game_meta.tag2;
}

get_clip_information = () => {
    return new Promise(async(resolve) => {
        const character = await get_character_info();
        const time = await get_time_info();
        const tag = get_tag_info();
        resolve({ character, time, tag });
    });
}

queue_clip_info = async() => {
    clip_data = await get_clip_information();
    clip_queued = true;
    console.log(chalk.green(`[Clip Queued]`), `Clip successfully queued.`);
}

prompt_for_clip = () => process_reader.question(`Hit Enter to clip it.\n`, queue_clip_info);

create_clip = (clip_information) => {
    let clip_file_path = `${script_settings.SLIPPI_CLIPS_FILE_PATH}${clip_information.tag ? `${clip_information.tag}_` : ''}${clip_information.character}_${game_meta.stage}_${clip_information.time}`
    let counter = 1;
    while(fs.existsSync(clip_file_path)) {
        console.log(chalk.yellow(`[Clip Name Already Exists]`), `${clip_file_path} already exists, renaming to: ${clip_file_path}_${counter}.slp`)
        clip_file_path = `${clip_file_path}_${counter}`;
        counter++;
    }
    fs.copyFileSync(current_slippi_file, `${clip_file_path}.slp`);
    console.log(chalk.green(`[Clip Created]`), `at location: ${clip_file_path}.slp`)
    clip_queued = false;
}


correct_stage_names = (stage_name) => {
    switch(stage_name) {
        case "Pokémon Stadium":
            return "Pokemon Stadium"
            break;
        default: return stage_name;
    }
}

process.on('message', message => {
    switch(message.message_type) {
        case "new_game":
            current_slippi_file = message.current_slippi_file;
            game_meta = message.game_meta;
            game_meta.stage = correct_stage_names(game_meta.stage);
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

        case "get_clip_ui":
            const { player, time } = message.payload;
            const tag = player === 1 ? game_meta.tag1 : game_meta.tag2;
            const character = player === 1 ? game_meta.character1 : game_meta.character2;
            const clip_information = { tag, character, stage: game_meta.stage, time: time.replace(':', '.') };
            create_clip(clip_information);
            break;
        default:
            break;
    }
});


