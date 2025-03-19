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
        ["XX0a|XXX0a|XXXX0a|XXXXX0a XX0b|XXX0b|XXXX0b|XXXXX0b XX0c|XXX0c|XXXX0c|XXXXX0c"],
        [
          #TODO: add some kind of constraint that bans unlike number tiles and winds
          # NOT "XX0a|XXX0a|XXXX0a|XXXXX0a XX1a|XXX1a|XXXX1a|XXXXX1a|XX2a|XXX2a|XXXX2a|XXXXX2a|XX3a|XXX3a|XXXX3a|XXXXX3a|etc."
          # NOT "NN|NNN|NNNN|NNNNN|EE|EEE|EEEE|EEEEE|WW|WWW|WWWW|WWWWW|SS|SSS|SSSS|SSSSS"
        ]
      ],
      [
        # Winds NEWS
        ["NN|NNN|NNNN|NNNNN EE|EEE|EEEE|EEEEE WW|WWW|WWWW|WWWWW SS|SSS|SSSS|SSSSS"],
        [
          #TODO: add some kind of constraint that bans extra winds and numbers
          # NOT ????
          # NOT "XX0a|XXX0a|XXXX0a|XXXXX0a"
        ]
      ],
      [
        # Winds NS
        ["NN|NNN|NNNN|NNNNN SS|SSS|SSSS|SSSSS"],
        [
          #TODO: add some kind of constraint that bans extra Es and Ws and numbers
          # NOT "EE|EEE|EEEE|EEEEE|WW|WWW|WWWW|WWWWW"
          # NOT "XX0a|XXX0a|XXXX0a|XXXXX0a"
        ]
      ],
      [
        # Winds EW
        ["EE|EEE|EEEE|EEEEE WW|WWW|WWWW|WWWWW"],
        [
          #TODO: add some kind of constraint that bans extra Es and Ws and numbers
          # NOT "NN|NNN|NNNN|NNNNN|SS|SSS|SSSS|SSSSS"
          # NOT "XX0a|XXX0a|XXXX0a|XXXXX0a"
        ]
      ],
      [
        # 369
        ["33a|333a|3333a|33333a"],
        ["66a|666a|6666a|66666a"],
        ["99a|999a|9999a|99999a"],
        [
          #TODO: add some kind of constraint that bans other numbers, like numbers, and winds
          # NOT "XX0a|XXX0a|XXXX0a|XXXXX0a XX1a|XXX1a|XXXX1a|XXXXX1a|XX2a|XXX2a|XXXX2a|XXXXX2a"
          # NOT "XX0a|XXX0a|XXXX0a|XXXXX0a XX0b|XXX0b|XXXX0b|XXXXX0b"
          # NOT "NN|NNN|NNNN|NNNNN|EE|EEE|EEEE|EEEEE|WW|WWW|WWWW|WWWWW|SS|SSS|SSSS|SSSSS"
        ]
      ],
      [
        # 2468
        ["44a|444a|4444a|44444a"],
        ["66a|666a|6666a|66666a"],
        ["22a|222a|2222a|22222a|88a|888a|8888a|88888a"],
        [
          #TODO: add some kind of constraint that bans other numbers, like numbers, and winds
          # NOT "XX0a|XXX0a|XXXX0a|XXXXX0a XX1a|XXX1a|XXXX1a|XXXXX1a|XX3a|XXX3a|XXXX3a|XXXXX3a"
          # NOT "XX0a|XXX0a|XXXX0a|XXXXX0a XX0b|XXX0b|XXXX0b|XXXXX0b"
          # NOT "NN|NNN|NNNN|NNNNN|EE|EEE|EEEE|EEEEE|WW|WWW|WWWW|WWWWW|SS|SSS|SSSS|SSSSS"
        ]
      ],
      [
        # 13579
        ["55a|555a|5555a|55555a"],
        [
          ["11a|111a|1111a|11111a 33a|333a|3333a|33333a"],
          ["33a|333a|3333a|33333a 77a|777a|7777a|77777a"],
          ["77a|777a|7777a|77777a 99a|999a|9999a|99999a"],
        ], #either you have 1&3, or you have 3&7, or you have 7&9
        [
          #TODO: add some kind of constraint that bans other numbers, like numbers, and winds
          # NOT "XX0a|XXX0a|XXXX0a|XXXXX0a XX1a|XXX1a|XXXX1a|XXXXX1a|XX3a|XXX3a|XXXX3a|XXXXX3a"
          # NOT "XX0a|XXX0a|XXXX0a|XXXXX0a XX0b|XXX0b|XXXX0b|XXXXX0b"
          # NOT "NN|NNN|NNNN|NNNNN|EE|EEE|EEEE|EEEEE|WW|WWW|WWWW|WWWWW|SS|SSS|SSSS|SSSSS"
          #TODO: add some kind of constraint that bans 1359 and 1579 w/o 7 and 3 resp.
          # ?????
        ]
      ],
      [
        # Consecutive Run
        # time to add 22 cases! what fun! 😭
        [
          #TODO: add 22 cases here
        ], 
        [
          #TODO: add some kind of constraint that bans other numbers, like numbers, and winds
          # NOT ?????
          # NOT "XX0a|XXX0a|XXXX0a|XXXXX0a XX0b|XXX0b|XXXX0b|XXXXX0b" (bans like numbers)
          # NOT "NN|NNN|NNNN|NNNNN|EE|EEE|EEEE|EEEEE|WW|WWW|WWWW|WWWWW|SS|SSS|SSSS|SSSSS"
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
    ],
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
