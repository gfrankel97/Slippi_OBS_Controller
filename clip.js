const readline = require('readline');
const fs = require('fs');
const { askQuestions } = require('./ask.js');
const script_settings = require('./settings.json');

var current_slippi_file;
var clip_queued = false;
var clip_data = null;
var process_reader = create_reader_interface();

function create_reader_interface() {
    return readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });
}

function validate_answers(answers) {
    let stage = answers[0];
    let character = answers[1];
    let time = answers[2];
    if(script_settings.STAGES.indexOf(stage) === -1) {
        console.error("    Stage must be one of: ", script_settings.STAGES);
        return false;
    }

    if(script_settings.CHARACTERS.indexOf(character) === -1) {
        console.error("    Character not one of: ", script_settings.CHARACTERS);
        return false;
    }

    if(!RegExp(`[0-7]:[0-6][0-9]`).test(time)) {
        console.error("    \[\e[1;35m\]Time must be in format: m:ss\[\e[0m\]");
        return false;
    }

    return true;
}

function get_clip_information() {
    return new Promise((resolve, reject) => {
        let stage, character, time;
        askQuestions(process_reader, [
            `    Stage: `,
            `    Character: `,
            `    In-Game Time: `
        ]).then(answers => {
            if(!validate_answers(answers)) {
                console.error("    Could not validate clip.");
                reject("Could not validate clip.");
            }
            else {
                resolve({
                    stage: answers[0],
                    character: answers[1],
                    time: answers[2].replace(":", ".")
                });
            }
        });
    });
}

function prompt_for_clip() {
    process_reader.question(`Hit Enter to clip it.\n`, () => {
        get_clip_information().then((clip_information) => {
            clip_queued = true;
            console.log("Clip successfully queued. It will be created at the end of the game.");
            clip_data = clip_information;
        });
    })
}

function create_clip(clip_information) {
    let clip_file_path = script_settings.SLIPPI_CLIPS_FILE_PATH + "\\" + clip_information.character + "_" + clip_information.stage + "_" + clip_information.time;
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
    let data = message[1];
    switch(message[0]) {
        case "new_game":
            current_slippi_file = data.current_slippi_file;
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

