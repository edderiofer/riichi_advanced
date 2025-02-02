def make_galaxy:
  if type == "array" then
    .[0] |= make_galaxy
  elif . == "0z" then
    "15z"
  else "1" + . end;

.wall |= (to_entries | map(if (.key % 4 == 3) then .value |= make_galaxy else . end) | map(.value))
|
# add tenpai defs + win def + yakuman def for Milky Way yakuman
.tenpai_definition += [
  [ [[
    "11m", "12m", "13m", "14m", "15m", "16m", "17m", "18m", "19m", "110m",
    "11p", "12p", "13p", "14p", "15p", "16p", "17p", "18p", "19p", "110p",
    "11s", "12s", "13s", "14s", "15s", "16s", "17s", "18s", "19s", "110s",
    "11t", "12t", "13t", "14t", "15t", "16t", "17t", "18t", "19t", "110t",
    "11z", "12z", "13z", "14z", "15z", "16z", "17z"
  ], 13] ]
]
|
.tenpai_14_definition += [
  [ [[
    "11m", "12m", "13m", "14m", "15m", "16m", "17m", "18m", "19m", "110m",
    "11p", "12p", "13p", "14p", "15p", "16p", "17p", "18p", "19p", "110p",
    "11s", "12s", "13s", "14s", "15s", "16s", "17s", "18s", "19s", "110s",
    "11t", "12t", "13t", "14t", "15t", "16t", "17t", "18t", "19t", "110t",
    "11z", "12z", "13z", "14z", "15z", "16z", "17z"
  ], 13] ]
]
|
.win_definition += [
  [ [[
    "11m", "12m", "13m", "14m", "15m", "16m", "17m", "18m", "19m", "110m",
    "11p", "12p", "13p", "14p", "15p", "16p", "17p", "18p", "19p", "110p",
    "11s", "12s", "13s", "14s", "15s", "16s", "17s", "18s", "19s", "110s",
    "11t", "12t", "13t", "14t", "15t", "16t", "17t", "18t", "19t", "110t",
    "11z", "12z", "13z", "14z", "15z", "16z", "17z"
  ], 14] ]
]
|
.yakuman += [{
  "display_name": "Milky Way",
  "value": 1,
  "when": [{"name": "winning_hand_consists_of", "opts": [
    "11m", "12m", "13m", "14m", "15m", "16m", "17m", "18m", "19m", "110m",
    "11p", "12p", "13p", "14p", "15p", "16p", "17p", "18p", "19p", "110p",
    "11s", "12s", "13s", "14s", "15s", "16s", "17s", "18s", "19s", "110s",
    "11t", "12t", "13t", "14t", "15t", "16t", "17t", "18t", "19t", "110t",
    "11z", "12z", "13z", "14z", "15z", "16z", "17z"
  ]}]
}]
|
# add joker rules
.after_start.actions += [
  ["set_tile_alias_all", ["11m"], ["1m","1s","1p","1t"]],
  ["set_tile_alias_all", ["12m"], ["2m","2s","2p","2t"]],
  ["set_tile_alias_all", ["13m"], ["3m","3s","3p","3t"]],
  ["set_tile_alias_all", ["14m"], ["4m","4s","4p","4t"]],
  ["set_tile_alias_all", ["15m"], ["5m","5s","5p","5t"]],
  ["set_tile_alias_all", ["16m"], ["6m","6s","6p","6t"]],
  ["set_tile_alias_all", ["17m"], ["7m","7s","7p","7t"]],
  ["set_tile_alias_all", ["18m"], ["8m","8s","8p","8t"]],
  ["set_tile_alias_all", ["19m"], ["9m","9s","9p","9t"]],
  ["set_tile_alias_all", ["11p"], ["1m","1s","1p","1t"]],
  ["set_tile_alias_all", ["12p"], ["2m","2s","2p","2t"]],
  ["set_tile_alias_all", ["13p"], ["3m","3s","3p","3t"]],
  ["set_tile_alias_all", ["14p"], ["4m","4s","4p","4t"]],
  ["set_tile_alias_all", ["15p"], ["5m","5s","5p","5t"]],
  ["set_tile_alias_all", ["16p"], ["6m","6s","6p","6t"]],
  ["set_tile_alias_all", ["17p"], ["7m","7s","7p","7t"]],
  ["set_tile_alias_all", ["18p"], ["8m","8s","8p","8t"]],
  ["set_tile_alias_all", ["19p"], ["9m","9s","9p","9t"]],
  ["set_tile_alias_all", ["11s"], ["1m","1s","1p","1t"]],
  ["set_tile_alias_all", ["12s"], ["2m","2s","2p","2t"]],
  ["set_tile_alias_all", ["13s"], ["3m","3s","3p","3t"]],
  ["set_tile_alias_all", ["14s"], ["4m","4s","4p","4t"]],
  ["set_tile_alias_all", ["15s"], ["5m","5s","5p","5t"]],
  ["set_tile_alias_all", ["16s"], ["6m","6s","6p","6t"]],
  ["set_tile_alias_all", ["17s"], ["7m","7s","7p","7t"]],
  ["set_tile_alias_all", ["18s"], ["8m","8s","8p","8t"]],
  ["set_tile_alias_all", ["19s"], ["9m","9s","9p","9t"]],
  ["set_tile_alias_all", ["11t"], ["1m","1s","1p","1t"]],
  ["set_tile_alias_all", ["12t"], ["2m","2s","2p","2t"]],
  ["set_tile_alias_all", ["13t"], ["3m","3s","3p","3t"]],
  ["set_tile_alias_all", ["14t"], ["4m","4s","4p","4t"]],
  ["set_tile_alias_all", ["15t"], ["5m","5s","5p","5t"]],
  ["set_tile_alias_all", ["16t"], ["6m","6s","6p","6t"]],
  ["set_tile_alias_all", ["17t"], ["7m","7s","7p","7t"]],
  ["set_tile_alias_all", ["18t"], ["8m","8s","8p","8t"]],
  ["set_tile_alias_all", ["19t"], ["9m","9s","9p","9t"]],
  ["set_tile_alias_all", ["11z"], ["1z","2z","3z","4z"]],
  ["set_tile_alias_all", ["12z"], ["1z","2z","3z","4z"]],
  ["set_tile_alias_all", ["13z"], ["1z","2z","3z","4z"]],
  ["set_tile_alias_all", ["14z"], ["1z","2z","3z","4z"]],
  ["set_tile_alias_all", ["15z"], ["5z","6z","7z","0z"]],
  ["set_tile_alias_all", ["16z"], ["5z","6z","7z","0z"]],
  ["set_tile_alias_all", ["17z"], ["5z","6z","7z","0z"]]
]
|
# expand dora indicator map, if it exists
if .dora_indicators then
  .dora_indicators += {
    "11t": ["2m", "2p", "2s", "2t"],
    "12t": ["3m", "3p", "3s", "3t"],
    "13t": ["4m", "4p", "4s", "4t"],
    "14t": ["5m", "5p", "5s", "5t"],
    "15t": ["6m", "6p", "6s", "6t"],
    "16t": ["7m", "7p", "7s", "7t"],
    "17t": ["8m", "8p", "8s", "8t"],
    "18t": ["9m", "9p", "9s", "9t"],
    "19t": ["1m", "1p", "1s", "1t"],
    "11p": ["2m", "2p", "2s", "2t"],
    "12p": ["3m", "3p", "3s", "3t"],
    "13p": ["4m", "4p", "4s", "4t"],
    "14p": ["5m", "5p", "5s", "5t"],
    "15p": ["6m", "6p", "6s", "6t"],
    "16p": ["7m", "7p", "7s", "7t"],
    "17p": ["8m", "8p", "8s", "8t"],
    "18p": ["9m", "9p", "9s", "9t"],
    "19p": ["1m", "1p", "1s", "1t"],
    "11s": ["2m", "2p", "2s", "2t"],
    "12s": ["3m", "3p", "3s", "3t"],
    "13s": ["4m", "4p", "4s", "4t"],
    "14s": ["5m", "5p", "5s", "5t"],
    "15s": ["6m", "6p", "6s", "6t"],
    "16s": ["7m", "7p", "7s", "7t"],
    "17s": ["8m", "8p", "8s", "8t"],
    "18s": ["9m", "9p", "9s", "9t"],
    "19s": ["1m", "1p", "1s", "1t"],
    "11t": ["2m", "2p", "2s", "2t"],
    "12t": ["3m", "3p", "3s", "3t"],
    "13t": ["4m", "4p", "4s", "4t"],
    "14t": ["5m", "5p", "5s", "5t"],
    "15t": ["6m", "6p", "6s", "6t"],
    "16t": ["7m", "7p", "7s", "7t"],
    "17t": ["8m", "8p", "8s", "8t"],
    "18t": ["9m", "9p", "9s", "9t"],
    "19t": ["1m", "1p", "1s", "1t"],
    "11z": ["1z", "2z", "3z", "4z"],
    "12z": ["1z", "2z", "3z", "4z"],
    "13z": ["1z", "2z", "3z", "4z"],
    "14z": ["1z", "2z", "3z", "4z"],
    "15z": ["5z", "6z", "7z", "0z"],
    "16z": ["5z", "6z", "7z", "0z"],
    "17z": ["5z", "6z", "7z", "0z"]
  }
else . end
|
# support for ten mod
if any(.wall[]; . == "10m") then
  .after_start.actions += [
    ["set_tile_alias_all", ["110m"], ["10m","10s","10p","10t"]],
    ["set_tile_alias_all", ["110p"], ["10m","10s","10p","10t"]],
    ["set_tile_alias_all", ["110s"], ["10m","10s","10p","10t"]],
    ["set_tile_alias_all", ["110t"], ["10m","10s","10p","10t"]]
  ]
  |
  if .dora_indicators then
    .dora_indicators += {
      "19m": ["10m", "10p", "10s", "10t"],
      "19p": ["10m", "10p", "10s", "10t"],
      "19s": ["10m", "10p", "10s", "10t"],
      "19t": ["10m", "10p", "10s", "10t"],
      "110m": ["1m", "1p", "1s", "1t"],
      "110p": ["1m", "1p", "1s", "1t"],
      "110s": ["1m", "1p", "1s", "1t"],
      "110t": ["1m", "1p", "1s", "1t"]
    }
  else . end
else . end
|
# ankans are displayed all-face-up
.buttons.ankan.call_style = {"self": [0, 1, 2, 3]}
|
.win_timer = 20
