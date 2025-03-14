.set_definitions.am_pung = [0, 0, 0]
|
.set_definitions.am_kong = [0, 0, 0, 0]
|
.set_definitions.am_quint = [0, 0, 0, 0, 0]
|
.set_definitions.am_news_kong = ["NEWS"]
|
.set_definitions.am_dragon_pung = ["RG0"]
|
.set_definitions.am_dragons_love = ["DDDDa DDDDb FFF FFF"]
|
  # NOTE: this hand currently doesn't work (why is it specifically two 1bams?)
# .set_definitions.am_dragons_wings = ["DDDDa DDDDb DDDDc", "1s", "1s"]
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
        ["XX0a XX0b XX0c",
        "XX0a XX0b XXX0c",
        "XX0a XX0b XXXX0c",
        "XX0a XX0b XXXXX0c",
        "XX0a XXX0b XXX0c",
        "XX0a XXXX0b XXXX0c",
        "XX0a XXXXX0b XXXXX0c",
        "XXX0a XXX0b XXX0c",
        "XXX0a XXX0b XXXX0c",
        "XXX0a XXX0b XXXXX0c",
        "XXX0a XXXX0b XXXX0c",
        "XXXX0a XXXX0b XXXX0c",
        "XXXX0a XXXXX0b XXXXX0c"],
        [
          #TODO: add some kind of constraint that bans unlike number tiles
        ]
      ],
      [
        # Winds
        # TODO: add this one
      ],
      [
        # the other ones
        # TODO: add this one
        [
          # categories
          # TODO: add this one
        ],
        [
          # no duplicate number/wind restriction
          # TODO: add this one
        ],
      ]
      # TODO: add this bit
      # dunno yet lol
    ],
      # PATTERN OF BLOCKS
    [
      [[["pair"], 1], [["am_kong", "am_news_kong"], 3]],
      [[["pair"], 3], [["am_kong", "am_news_kong"], 2]],
      [[["pair"], 5], [["am_kong", "am_news_kong"], 1]],
      [[["pair"], 1], [["am_pung", "am_dragon_pung"], 4]],
      [[["pair"], 4], [["am_pung", "am_dragon_pung"], 2]],
      [[["pair"], 2], [["am_quint"], 2]],
      [[["am_pung", "am_dragon_pung"], 3], [["am_quint"], 1]],
      [[["am_kong", "am_news_kong"], 1], [["am_quint"], 2]],
      [[["am_pung", "am_dragon_pung"], 2], [["am_kong", "am_news_kong"], 2]]
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
