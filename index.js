const fs = require('fs');
const _ = require('lodash');
const chalk = require('chalk');
const chokidar = require('chokidar');
const { fork } = require('child_process');

const SlippiGame = require('slp-parser-js');
const stages = require('slp-parser-js/dist/melee/stages');
const characters = require('slp-parser-js/dist/melee/characters');
const script_settings = require('./settings.json');

var child_process, watcher;


const gameByPath = {};

script = script => {
    watcher.on('all', async(event, path) => {
        let gameState, settings, stats, frames, latestFrame, gameEnd, game;
        try {
            game = _.get(gameByPath, [path, 'game']);
            if (!game) {
                //hacky way to get clipping after games working. We need to set a flag in clip.js to whether or not we're in a game
                child_process.send({ message_type: "check_for_clip" });
                console.log(chalk.green(`[New File]`), `at: ${path}`);
                game = new SlippiGame.default(path);
                const firstFrame = game.getLatestFrame();
                if (firstFrame.players) {
                    // need to set flag and make sure this gets set properly
                    activePorts = firstFrame.players.filter(player => player !== undefined).map(player => player.pre.playerIndex);
                }

                settings = game.getSettings();
                update_stream_assets_icon(settings);

                gameByPath[path] = {
                    game: game,
                    state: {
                        settings: null,
                        detectedPunishes: {},
                    }
                };
            }

            frames = game.getFrames();
            latestFrame = game.getLatestFrame();
            gameState = _.get(gameByPath, [path, 'state']);

            stats = game.getStats();
            // console.log(SlippiGame.common.didLoseStock(frameOne, frameTwo));

            frames = game.getFrames();
            latestFrame = game.getLatestFrame();
            gameEnd = game.getGameEnd();
        } catch (err) {
            console.error(chalk.red(err));
            return;
        }

        if (!gameState.settings && settings) {

            console.log(chalk.green(`[Game Start]`), `New game has started`);
            const time = new Date().toLocaleTimeString([], {hour: 'numeric', minute:'2-digit'});
            const game_meta = {
                character1: characters.getCharacterName(settings.players[0].characterId),
                tag1: settings.players[0].nametag ? settings.players[0].nametag : "",
                color1: characters.getCharacterColorName(settings.players[0].characterId, settings.players[0].characterColor),
                character2: characters.getCharacterName(settings.players[1].characterId),
                tag2: settings.players[1].nametag ? settings.players[1].nametag : "",
                color2: characters.getCharacterColorName(settings.players[1].characterId, settings.players[1].characterColor),
                stage: stages.getStageName(settings.stageId)
            }

            process.send({
                message_type: 'new game',
                payload: {
                    game: `New game started at ${time}`,
                    p1: `${game_meta.color1} ${game_meta.character1}`,
                    p2: `${game_meta.color2} ${game_meta.character2}`,
                    stage: `${game_meta.stage}`
                }
            });

            await update_stream_assets_scene(script_settings.SCENES[script_settings.SCENES.indexOf("Slippi")]);
            child_process.send({
                message_type: "new_game",
                current_slippi_file: path,
                game_meta
            });
            console.log(settings);
            gameState.settings = settings;
        }

        if (gameEnd) {
            const endTypes = {
                1: "TIME!",
                2: "GAME!",
                7: "No Contest",
            };

            const endMessage = _.get(endTypes, gameEnd.gameEndMethod) || "Unknown";

            const lrasText = gameEnd.gameEndMethod === 7 ? ` | Quitter Index: ${gameEnd.lrasInitiatorIndex}` : "";
            console.log(chalk.green(`[Game Complete]`), `Type: ${endMessage}${lrasText}`);
            await update_stream_assets_stats(stats);
            await update_stream_assets_scene(script_settings.SCENES[script_settings.SCENES.indexOf("Slippi_Stats")]);
            child_process.send({ message_type: "check_for_clip" });
        }

        update_stream_assets_icon(settings);
    });
}



//TO DO: NEED TO MAKE THIS 4P COMPATIBLE
update_stream_assets_icon = (game_settings) => {
    if (!game_settings) {
        return;
    }

    const player1 = game_settings.players[0];
    const player2 = game_settings.players[1];
    const { getCharacterName, getCharacterColorName } = SlippiGame.characters;

    const character_one_name = getCharacterName(player1.characterId);
    const character_one_color = getCharacterColorName(player1.characterId, player1.characterColor);
    const character_two_name = getCharacterName(player2.characterId);
    const character_two_color = getCharacterColorName(player2.characterId, player2.characterColor);


    //TO DO: Check for file and make sure it exists, if color doesn't exist, default to default
    fs.copyFileSync(
        `${script_settings.CHARACTER_ICON_SOURCE}${character_one_name.toLowerCase()}-${character_one_color.toLowerCase()}.png`,
        `${script_settings.STREAM_OVERLAY_FILE_PATH} ${script_settings.PLAYER_ONE_ICON_FILE_NAME}`);

    fs.copyFileSync(
      `${script_settings.CHARACTER_ICON_SOURCE}${character_two_name.toLowerCase()}-${character_two_color.toLowerCase()}.png`,
      `${script_settings.STREAM_OVERLAY_FILE_PATH} ${script_settings.PLAYER_TWO_ICON_FILE_NAME}`);
}

update_stream_assets_scene = (scene) => {
    return new Promise((resolve, reject) => {
            console.log(chalk.green(`[Scene Switching]`), `Scene:`, scene);
            fs.writeFileSync(script_settings.STREAM_OVERLAY_FILE_PATH + script_settings.SCENE_FILE_NAME, scene);
            resolve();
        // maybe no longer needed w/ obs setting
        //setTimeout(() => {}, script_settings.TIME_TO_SWITCH_SCENES);
    })
}

//TO DO: NEED TO MAKE THIS 4P COMPATIBLE
update_stream_assets_stats = (stats) => {
    return new Promise((resolve, reject) => {
        //keys: stocks combos actionCounts conversions lastFrame playableFrameCount overall gameComplete
        const port_to_folder_name = ["player_one", "player_two", "player_three", "player_four"];

        stats.overall.forEach(player => {
            for (let stat in player) {
                stat_value = typeof player[stat] == 'object' ? player[stat].ratio : player[stat];

                if (typeof stat_value === 'number') stat_value = Math.round(stat_value * 10) / 10;

                if (stat_value) {
                    fs.writeFileSync(
                      `${script_settings.STREAM_OVERLAY_FILE_PATH}stats\\${port_to_folder_name[player.playerIndex]}\\${stat}.txt`,
                        stat_value);
                }
            }
        });
        resolve();
    });
}


init = () => {
    process.send({ message_type: 'init' });
    if (!fs.existsSync(script_settings.SLIPPI_FILE_PATH)) {
        console.error(chalk.red(`[Settings Error]`), `Path ${script_settings.SLIPPI_FILE_PATH} does not exist. Check your settings.`);
        process.exit();
    }


    console.log(chalk.green(`[Listening]`), `at: ${script_settings.SLIPPI_FILE_PATH}`);
    child_process = fork('./clip.js');
    watcher = chokidar.watch(script_settings.SLIPPI_FILE_PATH, {
        depth: 0,
        persistent: true,
        usePolling: true,
        ignoreInitial: true,
    });
}


const main = () => {
    console.log('hitting main');
    init();
    script();
}

process.on('message', message => {
    console.log(message);
    switch (message) {
        case 'start': {
            console.log('starting');
            main();
            break;
        }
        case 'clip': {
            child_process.send({ message_type: "prompt_for_clip" });
        }
    }
});

// module.exports = { main };

