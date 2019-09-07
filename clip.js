const readline = require('readline');
const fs = require('fs');
const chalk = require('chalk');
const fs_path = require('path');
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

get_character_info = async(is_clip) => {
    let character1_string = game_meta.tag1 ? game_meta.tag1 : game_meta.character1;
    let character2_string = game_meta.tag2 ? game_meta.tag2 : game_meta.character2;
    if(!is_clip) {
        return `${character1_string}_vs_${character2_string}`
    }
    if(character1_string === character2_string) {
        character1_string = `${game_meta.color1}-${game_meta.character1}`;
        character2_string = `${game_meta.color2}-${game_meta.character2}`

    }
    let question_string = `    Press 1 for ${character1_string} or 2 for ${character2_string}: `;
    characterInput = await askQuestion(process_reader,  question_string);

    if (!validate_character(characterInput)) {
        return get_character_info();
    }

    return characterInput === '1' ? game_meta.character1 : game_meta.character2;
}


get_time_info = async() => {
    const timeInput = await askQuestion(process_reader, `    In-Game Time (format: m:ss): `)

    if (!validate_time(timeInput)) {
        return get_time_info();
    }

    return timeInput.replace(':', '.');
}

get_tag_info = () => {
    return characterInput === '1' ? game_meta.tag1 : game_meta.tag2;
}

get_readable_file_name = (clip_information, is_clip) => {
    console.log('READABLE')
    let file_path = clip_information.tag ? `${script_settings.SLIPPI_CLIPS_FILE_PATH}\\${clip_information.tag}_${clip_information.character}_${game_meta.stage}_${clip_information.time}` : `${script_settings.SLIPPI_CLIPS_FILE_PATH}\\${clip_information.character}_${game_meta.stage}_${clip_information.time}`;
    if(is_clip) {
        let counter = 1;
        while(fs.existsSync(file_path)) {
            console.log(chalk.yellow(`[Clip Name Already Exists]`), `${file_path} already exists, renaming to: ${file_path}_${counter}.slp`)
            file_path = `${file_path}_${counter}`;
            counter++;
        }
    }
    else {
        file_path = `${file_path}`
    }
    console.log(file_path)
    return file_path;
}

get_file_information = (is_clip) => {
    console.log("GET FILE INFO 1")
    return new Promise(async(resolve) => {
        const character = await get_character_info(is_clip);
        const time = await get_time_info();
        const tag = get_tag_info();
        console.log("GET FILE INFO 2")
        const file_name = get_readable_file_name({ character, time, tag }, is_clip);
        resolve({ character, time, tag, file_name });
    });
}

prompt_for_clip = () => {
    console.log('PROMPT FOR CLIP')
    // 'f' to enter friendlies mode
    // 't' to enter tournament mode
    process_reader.question(`Hit 'c' to clip it.\n`, async(key) => {
        console.log(key)
        if(key === 'c') {
            clip_data = await get_file_information(true);
            clip_queued = true;
            console.log(chalk.green(`[Clip Queued]`), `Clip successfully queued.`);
        }

        if(key === 't') {
            process.send({'message_type': 'change_script_mode',
                        'game_mode': 'Tournament'})
        }

        if(key === 'f') {
            process.send({'message_type': 'change_script_mode',
                        'game_mode': 'Friendlies'})
        }
    })
}

create_clip = (clip_information) => {
    fs.copyFileSync(current_slippi_file, `${clip_information.file_path}.slp`);
    console.log(chalk.green(`[Clip Created]`), `at location: ${clip_information.file_path}.slp`)
    clip_queued = false;
}

copy_slippi_file_to_output_dir = async() => {
    console.log('HERE 1')
    let output_file_name;
    get_file_information(false).then(info => {
        console.log('HERE 2')
        console.log(info)
        output_file_name = info.file_name;
    });

    // let destination_file = fs_path.join(output_file_name, game_meta.mode.toLowerCase());
    // console.log(destination_file)
    // fs.renameSync(current_slippi_file, destination_file);
}

correct_stage_names = (stage_name) => {
    switch(stage_name) {
        case "Pokémon Stadium":
            return "Pokemon Stadium"
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
        case "game_end":
            if(clip_queued) {
                create_clip(clip_data);
            }
            copy_slippi_file_to_output_dir();
            break;
        default:
            break;
    }
});



