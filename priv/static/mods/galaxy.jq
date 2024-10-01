.wall |= (to_entries | map(if (.key % 4 == 3) then .value = "1" + .value else . end) | map(.value))
|
.set_definitions += {dragons: ["5z", "6z", "7z"]}
|
.yaku += [{
  "display_name": "Dragon Sequence",
  "value": 1,
  "when": [{"name": "match", "opts": [["hand", "calls", "winning_tile"], [[[["dragons"], 1]]]]}]
}]
|
.extra_yaku += [
  {"display_name": "Dora", "value": 5, "when": [{"name": "tile_revealed", "opts": ["doraindicator_1"]}, {"name": "winning_dora_count", "opts": ["doraindicator_1", 5]}]},
  {"display_name": "Dora", "value": 6, "when": [{"name": "tile_revealed", "opts": ["doraindicator_1"]}, {"name": "winning_dora_count", "opts": ["doraindicator_1", 6]}]},
  {"display_name": "Dora", "value": 5, "when": [{"name": "tile_revealed", "opts": ["doraindicator_2"]}, {"name": "winning_dora_count", "opts": ["doraindicator_2", 5]}]},
  {"display_name": "Dora", "value": 6, "when": [{"name": "tile_revealed", "opts": ["doraindicator_2"]}, {"name": "winning_dora_count", "opts": ["doraindicator_2", 6]}]},
  {"display_name": "Dora", "value": 5, "when": [{"name": "tile_revealed", "opts": ["doraindicator_3"]}, {"name": "winning_dora_count", "opts": ["doraindicator_3", 5]}]},
  {"display_name": "Dora", "value": 6, "when": [{"name": "tile_revealed", "opts": ["doraindicator_3"]}, {"name": "winning_dora_count", "opts": ["doraindicator_3", 6]}]},
  {"display_name": "Dora", "value": 5, "when": [{"name": "tile_revealed", "opts": ["doraindicator_4"]}, {"name": "winning_dora_count", "opts": ["doraindicator_4", 5]}]},
  {"display_name": "Dora", "value": 6, "when": [{"name": "tile_revealed", "opts": ["doraindicator_4"]}, {"name": "winning_dora_count", "opts": ["doraindicator_4", 6]}]},
  {"display_name": "Dora", "value": 5, "when": [{"name": "tile_revealed", "opts": ["doraindicator_5"]}, {"name": "winning_dora_count", "opts": ["doraindicator_5", 5]}]},
  {"display_name": "Dora", "value": 6, "when": [{"name": "tile_revealed", "opts": ["doraindicator_5"]}, {"name": "winning_dora_count", "opts": ["doraindicator_5", 6]}]},
  {"display_name": "Ura", "value": 5, "when": [{"name": "status", "opts": ["riichi"]}, {"name": "tile_revealed", "opts": ["doraindicator_1"]}, {"name": "winning_dora_count", "opts": ["uraindicator_1", 5]}]},
  {"display_name": "Ura", "value": 4, "when": [{"name": "status", "opts": ["riichi"]}, {"name": "tile_revealed", "opts": ["doraindicator_1"]}, {"name": "winning_dora_count", "opts": ["uraindicator_1", 6]}]},
  {"display_name": "Ura", "value": 5, "when": [{"name": "status", "opts": ["riichi"]}, {"name": "tile_revealed", "opts": ["doraindicator_2"]}, {"name": "winning_dora_count", "opts": ["uraindicator_2", 5]}]},
  {"display_name": "Ura", "value": 4, "when": [{"name": "status", "opts": ["riichi"]}, {"name": "tile_revealed", "opts": ["doraindicator_2"]}, {"name": "winning_dora_count", "opts": ["uraindicator_2", 6]}]},
  {"display_name": "Ura", "value": 5, "when": [{"name": "status", "opts": ["riichi"]}, {"name": "tile_revealed", "opts": ["doraindicator_3"]}, {"name": "winning_dora_count", "opts": ["uraindicator_3", 5]}]},
  {"display_name": "Ura", "value": 4, "when": [{"name": "status", "opts": ["riichi"]}, {"name": "tile_revealed", "opts": ["doraindicator_3"]}, {"name": "winning_dora_count", "opts": ["uraindicator_3", 6]}]},
  {"display_name": "Ura", "value": 5, "when": [{"name": "status", "opts": ["riichi"]}, {"name": "tile_revealed", "opts": ["doraindicator_4"]}, {"name": "winning_dora_count", "opts": ["uraindicator_4", 5]}]},
  {"display_name": "Ura", "value": 4, "when": [{"name": "status", "opts": ["riichi"]}, {"name": "tile_revealed", "opts": ["doraindicator_4"]}, {"name": "winning_dora_count", "opts": ["uraindicator_4", 6]}]},
  {"display_name": "Ura", "value": 5, "when": [{"name": "status", "opts": ["riichi"]}, {"name": "tile_revealed", "opts": ["doraindicator_5"]}, {"name": "winning_dora_count", "opts": ["uraindicator_5", 5]}]},
  {"display_name": "Ura", "value": 4, "when": [{"name": "status", "opts": ["riichi"]}, {"name": "tile_revealed", "opts": ["doraindicator_5"]}, {"name": "winning_dora_count", "opts": ["uraindicator_5", 6]}]}
]
|
.after_start.actions += [
  ["set_tile_alias_all", ["11m"], ["1m","1s","1p"]],
  ["set_tile_alias_all", ["12m"], ["2m","2s","2p"]],
  ["set_tile_alias_all", ["13m"], ["3m","3s","3p"]],
  ["set_tile_alias_all", ["14m"], ["4m","4s","4p"]],
  ["set_tile_alias_all", ["15m"], ["5m","5s","5p"]],
  ["set_tile_alias_all", ["16m"], ["6m","6s","6p"]],
  ["set_tile_alias_all", ["17m"], ["7m","7s","7p"]],
  ["set_tile_alias_all", ["18m"], ["8m","8s","8p"]],
  ["set_tile_alias_all", ["19m"], ["9m","9s","9p"]],
  ["set_tile_alias_all", ["11p"], ["1m","1s","1p"]],
  ["set_tile_alias_all", ["12p"], ["2m","2s","2p"]],
  ["set_tile_alias_all", ["13p"], ["3m","3s","3p"]],
  ["set_tile_alias_all", ["14p"], ["4m","4s","4p"]],
  ["set_tile_alias_all", ["15p"], ["5m","5s","5p"]],
  ["set_tile_alias_all", ["16p"], ["6m","6s","6p"]],
  ["set_tile_alias_all", ["17p"], ["7m","7s","7p"]],
  ["set_tile_alias_all", ["18p"], ["8m","8s","8p"]],
  ["set_tile_alias_all", ["19p"], ["9m","9s","9p"]],
  ["set_tile_alias_all", ["11s"], ["1m","1s","1p"]],
  ["set_tile_alias_all", ["12s"], ["2m","2s","2p"]],
  ["set_tile_alias_all", ["13s"], ["3m","3s","3p"]],
  ["set_tile_alias_all", ["14s"], ["4m","4s","4p"]],
  ["set_tile_alias_all", ["15s"], ["5m","5s","5p"]],
  ["set_tile_alias_all", ["16s"], ["6m","6s","6p"]],
  ["set_tile_alias_all", ["17s"], ["7m","7s","7p"]],
  ["set_tile_alias_all", ["18s"], ["8m","8s","8p"]],
  ["set_tile_alias_all", ["19s"], ["9m","9s","9p"]],
  ["set_tile_alias_all", ["11z"], ["1z","2z","3z","4z"]],
  ["set_tile_alias_all", ["12z"], ["1z","2z","3z","4z"]],
  ["set_tile_alias_all", ["13z"], ["1z","2z","3z","4z"]],
  ["set_tile_alias_all", ["14z"], ["1z","2z","3z","4z"]],
  ["set_tile_alias_all", ["15z"], ["5z","6z","7z"]],
  ["set_tile_alias_all", ["16z"], ["5z","6z","7z"]],
  ["set_tile_alias_all", ["17z"], ["5z","6z","7z"]]
]