const fs = require('fs');
const { fork } = require('child_process');

const _ = require('lodash');
const chokidar = require('chokidar');
const SlippiGame = require('slp-parser-js');

const script_settings = require('./settings.json');
const process = fork('./clip.js');

console.log(`Listening at: ${script_settings.SLIPPI_FILE_PATH}`);

let activePorts = [];

const watcher = chokidar.watch(script_settings.SLIPPI_FILE_PATH, {
  depth: 0,
  persistent: true,
  usePolling: true,
  ignoreInitial: true,
});
const gameByPath = {};
watcher.on('change', (path) => {
  let gameState, settings, stats, frames, latestFrame, gameEnd;
  let game;
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

    // const currFrame = latestFrame.players[0].post.frame - 1;
    // const frameOne = frames[currFrame - 2].players[0].post.stocksRemaining;
    // const frameTwo = frames[currFrame - 3].players[0].post.stocksRemaining;
    // console.log(frames[currFrame - 3].players[0].post)


    gameState = _.get(gameByPath, [path, 'state']);

    settings = game.getSettings();
    stats = game.getStats();
    // console.log(SlippiGame.common.didLoseStock(frameOne, frameTwo));

    // console.log(stats.stocks.filter(stock => stock.endPercent !== null).map(stock => { stock.endPercent, stock.playerIndex }));

    //  const stockEnds = [];
    //  stats.stocks.forEach(stock => {
    //    if (stock.endPercent !== null) {
    //      console.log('player' + stock.playerIndex + ' :' + stock.endPercent);
    //    }
    //  });


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
    process.send(["new_game", {"current_slippi_file": path}]);
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
    process.send(["check_for_clip"]);
  }

  update_stream_assets_icon(settings);

  // console.log(`Read took: ${Date.now() - start} ms`);
});



//TO DO: NEED TO MAKE THIS 4P COMPATIBLE
const update_stream_assets_icon = (game_settings) => {
  if(!game_settings) {
    return;
  }

  let player1 = game_settings.players[0];
  let player2 = game_settings.players[1];
  let { getCharacterName, getCharacterColorName } = SlippiGame.characters;

  let character_one_name = getCharacterName(player1.characterId);
  let character_one_color = getCharacterColorName(player1.characterId, player1.characterColor);
  let character_two_name = getCharacterName(player2.characterId);
  let character_two_color = getCharacterColorName(player2.characterId, player2.characterColor);


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

function update_stream_assets_scene(scene) {
    setTimeout(function() {
      console.log("Switching to scene: ", scene);
      fs.writeFileSync(script_settings.STREAM_OVERLAY_FILE_PATH + script_settings.SCENE_FILE_NAME, scene);
    }.bind(this), script_settings.TIME_TO_SWITCH_SCENES);
}

//TO DO: NEED TO MAKE THIS 4P COMPATIBLE
function update_stream_assets_stats(stats) {
  //keys: stocks combos actionCounts conversions lastFrame playableFrameCount overall gameComplete
  var port_to_folder_name = ["player_one", "player_two", "player_three", "player_four"];

  for(var player in stats.overall) {
    for(stat in stats.overall[player]) {
      var stat_value = (typeof stats.overall[player][stat] == 'object' ? stats.overall[player][stat].ratio : stats.overall[player][stat]);
      if(typeof stat_value == "number") {
        stat_value = Math.round(stat_value * 10) / 10;
      }
      if(stat_value) {
        fs.writeFileSync(script_settings.STREAM_OVERLAY_FILE_PATH
        + "stats\\"
          + port_to_folder_name[player]
          + "\\"
          + stat
          + ".txt",
          stat_value);
      }
    }
  }
}