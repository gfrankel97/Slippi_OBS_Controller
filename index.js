const fs = require('fs');
const _ = require('lodash');
const fs_path = require('path');
const chalk = require('chalk');
const chokidar = require('chokidar');
const { fork } = require('child_process');

const SlippiGame = require('slp-parser-js');
const stages = require('slp-parser-js/dist/melee/stages');
const Characters = require('slp-parser-js/dist/melee/characters');

const script_settings = require('./settings.json');


let child_process,
    current_mode;


const gameByPath = {};

script = script => {
  let watcher = chokidar.watch(script_settings.INPUT_SLIPPI_FILE_PATH, {
    depth: 0,
    persistent: true,
    usePolling: true,
    ignoreInitial: true,
  }).on('all', async(ev, path) => {
      let gameState, settings, stats, frames, latestFrame, gameEnd, game;
      try {
          game = _.get(gameByPath, [path, 'game']);
          if (!game) {
              //hacky way to get clipping after games working. We need to set a flag in clip.js to whether or not we're in a game
              // BROKENN IN RECENT CODE - NEEDS ^
              // child_process.send({ message_type: "check_for_clip" });
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
          console.log(chalk.green(`[Game Start]`) + ` New game has started in ` + chalk.blue(current_mode) + ' mode.');
          await update_stream_assets_scene(script_settings.SCENES[script_settings.SCENES.indexOf("Slippi")]);
          child_process.send({
              message_type: "new_game",
              current_slippi_file: path,
              game_meta: {
                  character1: Characters.getCharacterName(settings.players[0].characterId),
                  tag1: settings.players[0].nametag ? settings.players[0].nametag : "",
                  color1: Characters.getCharacterColorName(settings.players[0].characterId, settings.players[0].characterColor),
                  character2: Characters.getCharacterName(settings.players[1].characterId),
                  tag2: settings.players[1].nametag ? settings.players[1].nametag : "",
                  color2: Characters.getCharacterColorName(settings.players[1].characterId, settings.players[1].characterColor),
                  stage: stages.getStageName(settings.stageId),
                  mode: current_mode
              },
          });
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
          child_process.send({ message_type: "game_end" });

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

    const character_one_name = Characters.getCharacterName(player1.characterId);
    const character_one_color = Characters.getCharacterColorName(player1.characterId, player1.characterColor);
    const character_two_name = Characters.getCharacterName(player2.characterId);
    const character_two_color = Characters.getCharacterColorName(player2.characterId, player2.characterColor);


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

validate_settings = () => {
  if (!fs.existsSync(script_settings.INPUT_SLIPPI_FILE_PATH)) {
    console.error(chalk.red(`[Settings Error]`), `Input Slippi file path ${script_settings.INPUT_SLIPPI_FILE_PATH} does not exist. Check your settings.`);
    process.exit();
  }
  console.log(chalk.green(`[Input Files Directory] `), `at: ${script_settings.INPUT_SLIPPI_FILE_PATH}`);

  if (!fs.existsSync(script_settings.OUTPUT_SLIPPI_FILE_PATH)) {
    console.error(chalk.red(`[Settings Error]`), `Output Slippi file path ${script_settings.OUTPUT_SLIPPI_FILE_PATH} does not exist. Check your settings. Exiting.`);
    process.exit();
  }

  if (!fs.existsSync(fs_path.join(`${script_settings.OUTPUT_SLIPPI_FILE_PATH}`, `/friendlies`))) {
    console.error(chalk.yellow(`[Settings Warning]`), `Output Slippi file path ${script_settings.OUTPUT_SLIPPI_FILE_PATH}/friendlies does not exist. Creating it for you.`);
    fs.mkdirSync(fs_path.join(`${script_settings.OUTPUT_SLIPPI_FILE_PATH}`, `/friendlies`));
  }
  console.log(chalk.green(`[Output Files Directory]`), `at: ${script_settings.OUTPUT_SLIPPI_FILE_PATH}`);


  if (!fs.existsSync(fs_path.join(`${script_settings.OUTPUT_SLIPPI_FILE_PATH}`, `/tournament`))) {
    console.warn(chalk.yellow(`[Settings Warning]`), `Output Slippi file path ${script_settings.OUTPUT_SLIPPI_FILE_PATH}/tournament does not exist. Creating it for you.`);
    fs.mkdirSync(fs_path.join(`${script_settings.OUTPUT_SLIPPI_FILE_PATH}`, `/tournament`));
  }

  if (!fs.existsSync(fs_path.join(`${script_settings.OUTPUT_SLIPPI_FILE_PATH}`, `/clips`))) {
    console.warn(chalk.yellow(`[Settings Warning]`), `Output Slippi file path ${script_settings.OUTPUT_SLIPPI_FILE_PATH}/clips does not exist. Creating it for you.`);
    fs.mkdirSync(fs_path.join(`${script_settings.OUTPUT_SLIPPI_FILE_PATH}`, `/clips`));
  }
}


init = () => {
    validate_settings();
    current_mode = script_settings.MODES[script_settings.MODES.indexOf("Friendlies")];
    console.log(chalk.green(`[Script Mode]`) + ` is in: ` + chalk.blue(current_mode) + ' mode.');
    child_process = fork('./clip.js');

    child_process.on('message', message => {
      switch(message.message_type) {
        case "change_script_mode":
          current_mode = script_settings.MODES[script_settings.MODES.indexOf(message.game_mode)];
          console.log(chalk.green(`[Script Mode Changed]`) + ` to: ` + chalk.blue(current_mode) + ' mode.');
          break;
      }
    })
    script();
}


init();
