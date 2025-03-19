.set_definitions.am_pung = [0, 0, 0]
|
.set_definitions.am_kong = [0, 0, 0, 0]
|
.set_definitions.am_quint = [0, 0, 0, 0, 0]
|
.set_definitions.am_news_kong = ["1z", "2z", "3z", "4z"]
|
.set_definitions.am_dragon_pung = ["0z", "6z", "7z"]
|
.set_definitions.am_dragons_love = ["DDDDa DDDDb FFF FFF"]
|
.set_definitions.am_dragons_wings = ["1s", "1s", "0z", "0z", "0z", "0z", "6z", "6z", "6z", "6z", "7z", "7z", "7z", "7z"]
|
.set_definitions.am_dragons_breath = ["NN EE WW SS RR GG 00"]
|
.win_definition = [
  [
    # should be an AND of the following two things
      # CATEGORY
    [
      # should be an OR of the following:
      [
        # Any Like Numbers
        [["X0a X0b X0c"], 1], "restart",
        [["NN|EE|WW|SS", "X0a X1a|X2a|X3a|X4a|X5a|X6a|X7a|X8a"], -1]
      ],
      [
        # Winds NEWS
        [["NN EE WW SS"], 1], "restart",
        [["X0a"], -1]
      ],
      [
        # Winds NS
        [["NN SS"], 1], "restart",
        [["X0a", "EE|WW"], -1]
      ],
      [
        # Winds EW
        [["EE WW"], 1], "restart",
        [["X0a", "NN|SS"], -1]
      ],
      [
        # 369
        [["3a"], 1], [["6a"], 1], [["9a"], 1], "restart",
        [["X0a X0b", "1a|2a|4a|5a|7a|8a|NN|EE|WW|SS"], -1]
      ],
      [
        # 2468
        [["4a"], 1], [["6a"], 1], [["2a|8a"], 1], "restart",
        [["X0a X0b", "1a|3a|5a|7a|9a|NN|EE|WW|SS"], -1]
      ],
      [
        # 13579
        [
            # either you have 135 without 9, or you have 579 without 1, or you have 357
          [
            [["1a"], 1], [["3a"], 1], [["5a"], 1], "restart",
            [["X0a X0b", "2a|4a|6a|8a|9a|NN|EE|WW|SS"], -1]
          ],
          [
            [["5a"], 1], [["7a"], 1], [["9a"], 1], "restart",
            [["X0a X0b", "2a|4a|6a|8a|1a|NN|EE|WW|SS"], -1]
          ],
          [
            [["3a"], 1], [["5a"], 1], [["7a"], 1], "restart",
            [["X0a X0b", "2a|4a|6a|8a|NN|EE|WW|SS"], -1]
          ]
        ]
      ],
      [
        # Consecutive Run
        # time to add 22 cases! what fun! 😭
          # actually i got it down to only 11 cases! yippee!
            # haha past Sophie, future you has gotten it down to 2 cases
        [
            # you have one of the following cases:
            # consecutive run of length 3 or 4:
          [
            [["X0a X1a X2a"], 1], "restart",
            [["X0a X0b", "X0a X4a|X5a|X6a|X7a|X8a", "NN|EE|WW|SS"], -1]
          ],
            # consecutive run of length 5 or 6:
          [
            [["X0a X1a X2a X3a X4a"], 1], "restart",
            [["X0a X0b", "X0a X6a|X7a|X8a", "NN|EE|WW|SS"], -1]
          ]
        ]
      ]
    ],
      # PATTERN OF BLOCKS
    [
        # 2KKK
      [
        [["pair"], 1], [["am_kong"], 3], "restart",
        ["unique", [["any"], 4]], "restart",
        ["unique", [["any"], -5]]
      ],
      [
        [["pair"], 1], [["am_kong"], 2], [["am_news_kong"], 1], "restart",
        [["am_news_kong"], 1], ["unique", [["any"], 3]], "restart",
        [["am_news_kong"], 1], ["unique", [["any"], -4]]
      ],
        # 222KK
      [
        [["pair"], 3], [["am_kong"], 2], "restart",
        ["unique", [["any"], 5]], "restart",
        ["unique", [["any"], -6]]
      ],
      [
        [["pair"], 3], [["am_kong"], 1], [["am_news_kong"], 1], "restart",
        [["am_news_kong"], 1], ["unique", [["any"], 4]], "restart",
        [["am_news_kong"], 1], ["unique", [["any"], -5]]
      ],
        # 22222K
      [
        [["pair"], 5], [["am_kong"], 1], "restart",
        ["unique", [["any"], 6]], "restart",
        ["unique", [["any"], -7]]
      ],
      [
        [["pair"], 5], [["am_news_kong"], 1], "restart",
        [["am_news_kong"], 1], ["unique", [["any"], 5]], "restart",
        [["am_news_kong"], 1], ["unique", [["any"], -6]]
      ],
        # 2PPPP
      [
        [["pair"], 1], [["am_pung"], 4], "restart",
        ["unique", [["any"], 5]], "restart",
        ["unique", [["any"], -6]]
      ],
      [
        [["pair"], 1], [["am_pung"], 3], [["am_dragon_pung"], 1], "restart",
        [["am_dragon_pung"], 1], ["unique", [["any"], 4]], "restart",
        [["am_dragon_pung"], 1], ["unique", [["any"], -5]]
      ],
        # 2222PP
      [
        [["pair"], 4], [["am_pung"], 2], "restart",
        ["unique", [["any"], 6]], "restart",
        ["unique", [["any"], -7]]
      ],
      [
        [["pair"], 4], [["am_pung"], 1], [["am_dragon_pung"], 1], "restart",
        [["am_dragon_pung"], 1], ["unique", [["any"], 5]], "restart",
        [["am_dragon_pung"], 1], ["unique", [["any"], -6]]
      ],
        # 22QQ
      [
        [["pair"], 2], [["am_quint"], 2], "restart",
        ["unique", [["any"], 4]], "restart",
        ["unique", [["any"], -5]]
      ],
        # PPPQ
      [
        [["am_pung"], 3], [["am_quint"], 1], "restart",
        ["unique", [["any"], 4]], "restart",
        ["unique", [["any"], -5]]
      ],
      [
        [["am_pung"], 2], [["am_dragon_pung"], 1], [["am_quint"], 1], "restart",
        [["am_dragon_pung"], 1], ["unique", [["any"], 3]], "restart",
        [["am_dragon_pung"], 1], ["unique", [["any"], -4]]
      ],
        # KQQ
      [
        [["am_kong"], 1], [["am_quint"], 2], "restart",
        ["unique", [["any"], 4]], "restart",
        ["unique", [["any"], -5]]
      ],
      [
        [["am_news_kong"], 1], [["am_quint"], 2], "restart",
        [["am_news_kong"], 1], ["unique", [["any"], 3]], "restart",
        [["am_news_kong"], 1], ["unique", [["any"], -4]]
      ],
        # PPKK
      [
        [["am_pung"], 2], [["am_kong"], 2], "restart",
        ["unique", [["any"], 4]], "restart",
        ["unique", [["any"], -5]]
      ],
      [
        [["am_pung"], 1], [["am_dragon_pung"], 1], [["am_kong"], 2], "restart",
        [["am_dragon_pung"], 1], ["unique", [["any"], 3]], "restart",
        [["am_dragon_pung"], 1], ["unique", [["any"], -4]]
      ],
      [
        [["am_pung"], 2], [["am_kong"], 1], [["am_news_kong"], 1], "restart",
        [["am_news_kong"], 1], ["unique", [["any"], 3]], "restart",
        [["am_news_kong"], 1], ["unique", [["any"], -4]]
      ],
      [
        [["am_pung"], 1], [["am_dragon_pung"], 1], [["am_kong"], 1], [["am_news_kong"], 1], "restart",
        [["am_dragon_pung"], 1], [["am_news_kong"], 1], ["unique", [["any"], 2]], "restart",
        [["am_dragon_pung"], 1], [["am_news_kong"], 1], ["unique", [["any"], -3]]
      ]
    ]
  ],
  [["am_dragons_love", "am_dragons_wings", "am_dragons_breath"], 1]
]
|
.open_win_definition = [
  ]
|
.dragon_hand_win_definition = [
    [["am_dragons_love", "am_dragons_wings", "am_dragons_breath"], 1]
  ]
|
.singles_win_definition = [
  ]
|
.yaku = [
    { "display_name": "Base Value", "value": 25, "when": [{"name": "not_match", "opts": [["hand", "call_tiles", "winning_tile"], [["dragon_hand_win"], 1]]}] },
    { "display_name": "Quints", "value": 5, "when": [{"name": "match", "opts": [["hand", "call_tiles", "winning_tile"], [["am_quint"], 1]]}] },
    { "display_name": "Quints", "value": 5, "when": [{"name": "match", "opts": [["hand", "call_tiles", "winning_tile"], [["am_quint"], 2]]}] },
    { "display_name": "Pure", "value": 5, "when": [{"name": "not_match", "opts": [["hand", "call_tiles", "winning_tile"], [["jihai", "flower"], 1]]}] },
    { "display_name": "Suit", "value": 5, "when": [[
      {"name": "winning_hand_consists_of", "opts": ["1m","2m","3m","4m","5m","6m","7m","8m","9m","1z","2z","3z","4z","7z"]},
      {"name": "winning_hand_consists_of", "opts": ["1p","2p","3p","4p","5p","6p","7p","8p","9p","1z","2z","3z","4z","0z"]},
      {"name": "winning_hand_consists_of", "opts": ["1s","2s","3s","4s","5s","6s","7s","8s","9s","1z","2z","3z","4z","6z"]}
    ]] },
    { "display_name": "Concealed", "value": 10, "when": [{"name": "has_no_call_named", "opts": ["am_pung", "am_kong", "am_quint"]}] }
  ]
