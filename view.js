// const mainProgram = require('./index.js');
const $ = require('jquery');
const { fork } = require('child_process');

const game_status = $('#game-status');
const player1 = $('#player1');
const player2 = $('#player2');
const clip_it = $('#clip-it');
const stage_text = $('#stage');
const clip_info = $('#clip-info');
const clip_character1 = $('#clip-character1');
const clip_character2 = $('#clip-character2');
const create_clip = $('#create-clip');
const timestamp = $('#time-stamp');

clip_it.hide();
clip_info.hide();
create_clip.attr('disabled', true);

// mainProgram.main();
const mainProgram = fork('./index.js');
mainProgram.send('start');

clip_it.on('click', () => {
    clip_info.show();
    clip_it.hide();
    mainProgram.send('clip')
});
clip_character1.on('click', () => {
    clip_character1.addClass('selected');
    clip_character2.removeClass('selected');
});
clip_character2.on('click', () => {
    clip_character2.addClass('selected');
    clip_character1.removeClass('selected');
});
timestamp.on('keyup', () => {
    create_clip.attr('disabled', !RegExp(`[0-8]:[0-6][0-9]`).test(timestamp.val()));
})

mainProgram.on('message', ({ message_type, payload }) => {
    switch (message_type) {
        case 'init': {
            game_status.text('Waiting for Game');
            break;
        }
        case 'new game': {
            const { game, p1, p2, stage } = payload
            game_status.text(game);
            player1.text(p1);
            player2.text(p2);
            clip_character1.text(p1);
            clip_character2.text(p2);
            stage_text.text(stage)
            clip_it.show();
            break;
        }
    }
});