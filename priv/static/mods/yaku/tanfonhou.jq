(if .buttons | has("ton") then ["ton", "chii", "chon", "chon_honors", "daiminfuun", "pon", "daiminkan", "kapon", "kakakan", "kafuun", "kakan"] else ["chii", "pon", "daiminkan", "kakan"] end) as $open_calls
|
.yaku += [
  {
    "display_name": "Tanfonhou",
    "value": 2,
    "when": [{"name": "winning_hand_and_tile_consists_of", "opts": ["2p","4p","8p","2s","3s","4s","6s","8s","1z","2z","3z","4z","5z","6z"]}]
  },
  {
    "display_name": "Chintanfon",
    "value": 5,
    "when": [{"name": "winning_hand_and_tile_consists_of", "opts": ["2p","4p","8p","2s","3s","4s","6s","8s"]}]
  }
]
|
.meta_yaku += [
  { "display_name": "Tanfonhou", "value": 1, "when": [{"name": "has_no_call_named", "opts": $open_calls}, {"name": "has_existing_yaku", "opts": ["Tanfonhou"]}] },
  { "display_name": "Chintanfon", "value": 1, "when": [{"name": "has_no_call_named", "opts": $open_calls}, {"name": "has_existing_yaku", "opts": ["Chintanfon"]}] }
]
|
.yaku_precedence += {
  "Chintanfon": ["Tanfonhou"]
}