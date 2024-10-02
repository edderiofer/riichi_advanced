.tenpai_definition |= map(if .[0] == "exhaustive" then (["exhaustive", "wraps", "honorseq"] + .[1:]) else . end)
|
.tenpai_14_definition |= map(if .[0] == "exhaustive" then (["exhaustive", "wraps", "honorseq"] + .[1:]) else . end)
|
.win_definition |= map(if .[0] == "exhaustive" then (["exhaustive", "wraps", "honorseq"] + .[1:]) else . end)
|
.kokushi_tenpai_definition += [
  [ "unique",
    [["1m","9m","1p","9p","1s","9s","4z","5z","6z","7z"], 9],
    [[["1z","2z","3z"]], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ],
  [ "unique",
    [["1m","9m","1p","9p","1s","9s","3z","5z","6z","7z"], 9],
    [[["1z","2z","4z"]], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ],
  [ "unique",
    [["1m","9m","1p","9p","1s","9s","2z","5z","6z","7z"], 9],
    [[["1z","3z","4z"]], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ],
  [ "unique",
    [["1m","9m","1p","9p","1s","9s","1z","5z","6z","7z"], 9],
    [[["2z","3z","4z"]], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ],
  [ "unique",
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z"], 9],
    [[["5z","6z","7z"]], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ],
  [ "unique",
    [["1m","9m","1p","9p","1s","9s","4z"], 6],
    [[["1z","2z","3z"]], 1],
    [[["5z","6z","7z"]], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ],
  [ "unique",
    [["1m","9m","1p","9p","1s","9s","3z"], 6],
    [[["1z","2z","4z"]], 1],
    [[["5z","6z","7z"]], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ],
  [ "unique",
    [["1m","9m","1p","9p","1s","9s","2z"], 6],
    [[["1z","3z","4z"]], 1],
    [[["5z","6z","7z"]], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ],
  [ "unique",
    [["1m","9m","1p","9p","1s","9s","1z"], 6],
    [[["2z","3z","4z"]], 1],
    [[["5z","6z","7z"]], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ]
]
|
.win_definition += [
  [
    [[["1m","9m","1p","9p","1s","9s"]], 1],
    [[["5z","6z","7z"]], 1],
    [[["1z","2z","3z"]], 1],
    [["4z"], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ],
  [
    [[["1m","9m","1p","9p","1s","9s"]], 1],
    [[["5z","6z","7z"]], 1],
    [[["1z","2z","4z"]], 1],
    [["3z"], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ],
  [
    [[["1m","9m","1p","9p","1s","9s"]], 1],
    [[["5z","6z","7z"]], 1],
    [[["1z","3z","4z"]], 1],
    [["2z"], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ],
  [
    [[["1m","9m","1p","9p","1s","9s"]], 1],
    [[["5z","6z","7z"]], 1],
    [[["2z","3z","4z"]], 1],
    [["1z"], 1],
    [["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"], 1]
  ]
]
|
.yaku += [
  {
    "display_name": "Open Kokushi Musou",
    "value": 3,
    "when": [
      {"name": "winning_hand_consists_of", "opts": ["1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z"]},
      {"name": "not_match", "opts": [["hand", "calls", "winning_tile"], [[[["ton_pair", "nan_pair", "shaa_pair", "pei_pair", "haku_pair", "hatsu_pair", "chun_pair"], 2]]]]},
      {"name": "not_match", "opts": [["hand", "calls", "winning_tile"], [[[["ton", "nan", "shaa", "pei", "haku", "hatsu", "chun"], 1]]]]}
    ]
  }
]
|
.yaku |= map(select(.display_name != "Chiitoitsu"))
|
.after_start.actions |= map(if .[0] == "set_status_all" then (. + ["wrapping_score_calculation"]) else . end)
|
.buttons.chii += {"honor_seqs": true, "call_wraps": true}
|
.buttons.chii.show_when |= map(if . == "kamicha_discarded" then "someone_else_just_discarded" else . end)