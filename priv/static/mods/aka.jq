def replace_n_tiles($tile; $aka; $num):
  if $num > 0 then
    (map(if type == "object" then .tile elif type == "array" then .[0] else . end) | index($tile)) as $ix
    |
    if $ix then
      if .[$ix] | type == "object" then
        .[$ix].tile = $aka
      elif .[$ix] | type == "array" then
        .[$ix][0] = $aka
      else
        .[$ix] = $aka
      end
      |
      replace_n_tiles($tile; $aka; $num - 1)
    else . end
  else . end;

.after_initialization.actions += [
  ["add_rule", "Rules", "Wall", "(Aka) \($man)x 5m, \($pin)x 5p, and \($sou)x 5s are replaced with red \"aka dora\" fives that are worth one extra han each.", -99],
  ["update_rule", "Rules", "Shuugi", "(Aka) If your hand is closed, each aka dora is worth 1 shuugi."]
]
|
# replace 5m,5p,5s in wall with 0m,0p,0s
.wall |= replace_n_tiles("5m"; "0m"; $man)
|
.wall |= replace_n_tiles("5p"; "0p"; $pin)
|
.wall |= replace_n_tiles("5s"; "0s"; $sou)
|
.wall |= replace_n_tiles("5t"; "0t"; $man) # just reuse $man, keep it simple
|
# set each aka dora as 5m/p/s-valued jokers
.after_start.actions += [
  ["set_tile_alias_all", ["0m"], ["5m"]],
  ["set_tile_alias_all", ["0p"], ["5p"]],
  ["set_tile_alias_all", ["0s"], ["5s"]],
  ["tag_tiles", "dora", ["0m", "0p", "0s"]]
]
|
# star suit mod
if any(.wall[]; . == "1t") then
  (.wall | index("5s")) as $idx | if $idx then .wall[$idx] = "0s" else . end
  |
  .after_start.actions += [
    ["set_tile_alias_all", ["0t"], ["5t"]],
    ["tag_tiles", "dora", ["0t"]]
  ]
  |
  .before_win.actions += [
    ["add_counter", "aka", "count_matches", ["hand", "calls", "winning_tile"], [[ "nojoker", [["0t"], 1] ]]]
  ]
  |
  .dora_indicators += {
    "0t": ["6t"]
  }
else . end
|
# count aka
.before_win.actions += [
  ["add_counter", "aka", "count_matches", ["hand", "calls", "winning_tile"], [[ "nojoker", [["0m","0p","0s"], 1] ]]]
]
|
# add aka yaku
.extra_yaku += [
  {"display_name": "Aka", "value": "aka", "when": [{"name": "counter_at_least", "opts": ["aka", 1]}]}
]
|
# add dora indicators
.dora_indicators += {
  "0m": ["6m"],
  "0p": ["6p"],
  "0s": ["6s"]
}
