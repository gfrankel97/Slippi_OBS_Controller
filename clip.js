const readline = require('readline');
const fs = require('fs');
const { askQuestions } = require('./ask.js');
const script_settings = require('./settings.json');

var current_slippi_file;
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
    let stage, character, time;
    askQuestions(process_reader, [
        `    Stage: `,
        `    Character: `,
        `    In-Game Time: `
    ]).then(answers => {
        if(!validate_answers(answers)) {
            console.error("    Could not validate clip.");
        }
        else {
            stage = answers[0];
            character = answers[1];
            time = answers[2];
            fs.copyFileSync(current_slippi_file, script_settings.SLIPPI_CLIPS_FILE_PATH + current_slippi_file.split('\\').pop());
        }
        create_clip();
    });
}

function create_clip() {
    process_reader.question(`Hit Enter to clip it. `, () => {
        get_clip_information();
    })
}

process.on('message', message => {
    let data = message[1];
    switch(message[0]) {
        case "update_current_slippi_file":
            current_slippi_file = data.current_slippi_file;
            break;

    }
});

create_clip();

