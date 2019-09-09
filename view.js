const $ = require('jquery');
const { fork } = require('child_process');

const game_status = $('#game-status');
const clip_it = $('#clip-it');
const stage_text = $('#stage');
const clip_info = $('#clip-info');
const clip_character1_text = $('#clip-character1_text');
const clip_character1 = $('#clip-character1');
const clip_character2_text = $('#clip-character2_text');
const clip_character2 = $('#clip-character2');
const create_clip = $('#create-clip');
const timestamp = $('#time-stamp');
const game_info_section = $('#game-info-section');

let selected_clip_character;

clip_it.hide();
clip_info.hide();
game_info_section.hide();
create_clip.attr('disabled', true);

const mainProgram = fork('./index.js');
mainProgram.send({ message_type: 'start' });

clip_it.on('click', () => {
    clip_info.show();
    game_info_section.hide();
    clip_it.hide();
});
create_clip.on('click', () => {
    mainProgram.send({ message_type: 'clip', player: selected_clip_character, time: timestamp.val() });
})
clip_character1.on('click', () => {
    selected_clip_character = 1;
    clip_character1.addClass('selected');
    clip_character2.removeClass('selected');
    check_is_clip_disabled();
});
clip_character2.on('click', () => {
    selected_clip_character = 2;
    clip_character2.addClass('selected');
    clip_character1.removeClass('selected');
    check_is_clip_disabled();
});
timestamp.on('keyup', () => check_is_clip_disabled());

check_is_clip_disabled = () => {
    create_clip.attr('disabled', (!RegExp(`[0-8]:[0-6][0-9]`).test(timestamp.val()) || !selected_clip_character));
}

mainProgram.on('message', ({ message_type, payload }) => {
    switch (message_type) {
        case 'init': {
            game_status.text('Waiting for Game');
            break;
        }
        case 'new game': {
            game_info_section.show();
            const { game, p1, p2, stage } = payload;
            game_status.text(game);
            clip_character1_text.text(p1);
            clip_character2_text.text(p2);
            stage_text.text(stage)
            clip_it.show();
            break;
        }
    }
});