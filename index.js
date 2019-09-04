const fs = require('fs');
const { fork } = require('child_process');

const _ = require('lodash');
const chokidar = require('chokidar');
const SlippiGame = require('slp-parser-js');
const characters = require('slp-parser-js/dist/melee/characters');
const stages = require('slp-parser-js/dist/melee/stages');

const script_settings = require('./settings.json');
const process = fork('./clip.js');

console.log(`Listening at: ${script_settings.SLIPPI_FILE_PATH}`);

const watcher = chokidar.watch(script_settings.SLIPPI_FILE_PATH, {
  depth: 0,
  persistent: true,
  usePolling: true,
  ignoreInitial: true,
});

const gameByPath = {};

watcher.on('change', (path) => {
  let gameState, settings, stats, frames, latestFrame, gameEnd, game;
  try {
    game = _.get(gameByPath, [path, 'game']);
    if (!game) {
      console.log(`New file at: ${path}`);
      
      game = new SlippiGame.default(path);
      const firstFrame = game.getLatestFrame();
      if(firstFrame.players) {
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

    // You can uncomment the stats calculation below to get complex stats in real-time. The problem
    // is that these calculations have not been made to operate only on new data yet so as
    // the game gets longer, the calculation will take longer and longer
    // stats = game.getStats();

    frames = game.getFrames();
    latestFrame = game.getLatestFrame();
    gameEnd = game.getGameEnd();
  } catch (err) {
    console.error(err);
    return;
  }

  if (!gameState.settings && settings) {
    console.log(`[Game Start] New game has started`);
    process.send({
      message_type: "new_game", 
      current_slippi_file: path,
      game_meta: {
        character1: characters.getCharacterName(settings.players[0].characterId),
        character2: characters.getCharacterName(settings.players[1].characterId),
        stage: stages.getStageName(settings.stageId)
      }
    });
    update_stream_assets_scene(script_settings.SCENES[script_settings.SCENES.indexOf("Slippi")]);
    gameState.settings = settings;
  }

  if (gameEnd) {
    // NOTE: These values and the quitter index will not work until 2.0.0 recording code is
    // NOTE: used. This code has not been publicly released yet as it still has issues
    const endTypes = {
      1: "TIME!",
      2: "GAME!",
      7: "No Contest",
    };

    const endMessage = _.get(endTypes, gameEnd.gameEndMethod) || "Unknown";

    const lrasText = gameEnd.gameEndMethod === 7 ? ` | Quitter Index: ${gameEnd.lrasInitiatorIndex}` : "";
    console.log(`[Game Complete] Type: ${endMessage}${lrasText}`);
    update_stream_assets_scene(script_settings.SCENES[script_settings.SCENES.indexOf("Slippi_Stats")]);
    update_stream_assets_stats(stats);
    process.send({ message_type: "check_for_clip" });
  }
});



//TO DO: NEED TO MAKE THIS 4P COMPATIBLE
update_stream_assets_icon = (game_settings) => {
  if(!game_settings) {
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
    script_settings.CHARACTER_ICON_SOURCE
      + character_one_name.toLowerCase()
      + "-"
      + character_one_color.toLowerCase()
      + ".png",
    script_settings.STREAM_OVERLAY_FILE_PATH + script_settings.PLAYER_ONE_ICON_FILE_NAME);

    fs.copyFileSync(
      script_settings.CHARACTER_ICON_SOURCE
        + character_two_name.toLowerCase()
        + "-"
        + character_two_color.toLowerCase()
        + ".png",
      script_settings.STREAM_OVERLAY_FILE_PATH + script_settings.PLAYER_TWO_ICON_FILE_NAME);
}

update_stream_assets_scene = scene => {
    setTimeout(() => {
      console.log("Switching to scene: ", scene);
      fs.writeFileSync(script_settings.STREAM_OVERLAY_FILE_PATH + script_settings.SCENE_FILE_NAME, scene);
    }, script_settings.TIME_TO_SWITCH_SCENES);
}

//TO DO: NEED TO MAKE THIS 4P COMPATIBLE
update_stream_assets_stats = stats => {
  //keys: stocks combos actionCounts conversions lastFrame playableFrameCount overall gameComplete
  const port_to_folder_name = ["player_one", "player_two", "player_three", "player_four"];

    stats.overall.forEach(player => {
      for (let stat in player) {
        stat_value = typeof player[stat] == 'object' ? player[stat].ratio : player[stat];

        if (typeof stat_value === 'number') stat_value = Math.round(stat_value * 10) / 10;

        if (stat_value) {
          fs.writeFileSync(script_settings.STREAM_OVERLAY_FILE_PATH
          + "stats\\"
            + port_to_folder_name[player.playerIndex]
            + "\\"
            + stat
            + ".txt",
            stat_value);
        }
      }
    });
}