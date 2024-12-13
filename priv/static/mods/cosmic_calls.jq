def replace($from; $to):
  if . == $from then $to else . end;

def fix_yaku:
  map(.when |= walk(
    replace(
      {"name": "has_no_call_named", "opts": ["chii", "pon", "daiminkan", "kakan"]};
      {"name": "has_no_call_named", "opts": ["ton", "chii", "chon", "chon_honors", "daiminfuun", "pon", "daiminkan", "kapon", "kakakan", "kafuun", "kakan"]}
    )
  ));

.functions.discard_passed += [["as", "others", [["unset_status", "fuun"]]]]
|
# all closed hand checks should check the new calls
.yaku |= fix_yaku
|
.yakuman |= fix_yaku
|
.meta_yaku |= fix_yaku
|
.meta_yakuman |= fix_yaku
|
# the calls:
.buttons += {
  "ton": {
    "display_name": "Ton",
    "call": [[0]],
    "call_style": {"kamicha": ["call_sideways", 0], "shimocha": [0, "call_sideways"]},
    "show_when": ["not_our_turn", "not_no_tiles_remaining", ["kamicha_discarded", "shimocha_discarded"], {"name": "status_missing", "opts": ["riichi"]}, "call_available"],
    "actions": [["big_text", "Ton"], ["call"], ["change_turn", "self"]]
  },
  "chon": {
    "display_name": "Chon",
    "call": [[10, 20]],
    "call_conditions": [
      {"name": "not_match", "opts": [["called_tile"], [[[["1z","2z","3z","4z","5z","6z","7z"], 1]]]]}
    ],
    "call_style": {"kamicha": ["call_sideways", 0, 1], "toimen": [0, "call_sideways", 1], "shimocha": [0, 1, "call_sideways"]},
    "show_when": ["not_our_turn", "not_no_tiles_remaining", "someone_else_just_discarded", {"name": "status_missing", "opts": ["riichi"]}, "call_available"],
    "actions": [["big_text", "Chon"], ["call"], ["change_turn", "self"]],
    "precedence_over": ["ton", "chii", "chon", "chon_honors"]
  },
  "chon_honors": {
    "display_name": "Chon",
    "call": [[-2, -1], [-1, 1], [1, 2]],
    "call_conditions": [
      {"name": "match", "opts": [["called_tile"], [[[["1z","2z","3z","4z","5z","6z","7z"], 1]]]]}
    ],
    "call_style": {"kamicha": ["call_sideways", 0, 1], "toimen": [0, "call_sideways", 1], "shimocha": [0, 1, "call_sideways"]},
    "show_when": ["not_our_turn", "not_no_tiles_remaining", "someone_else_just_discarded", {"name": "status_missing", "opts": ["riichi"]}, "call_available"],
    "actions": [["big_text", "Chon"], ["call"], ["change_turn", "self"]],
    "precedence_over": ["ton", "chii", "chon", "chon_honors"]
  },
  "daiminfuun": {
    "display_name": "Fuun",
    "call": [[1, 2, 3]],
    "call_conditions": [
      {"name": "match", "opts": [["called_tile"], [[[["1z","2z","3z","4z"], 1]]]]}
    ],
    "call_style": {"kamicha": ["call_sideways", 0, 1, 2], "toimen": [0, "call_sideways", 1, 2], "shimocha": [0, 1, 2, "call_sideways"]},
    "show_when": ["not_our_turn", "not_no_tiles_remaining", "someone_else_just_discarded", {"name": "status_missing", "opts": ["riichi"]}, "call_available"],
    "actions": [["big_text", "Fuun"], ["call"], ["change_turn", "self"], ["draw"], ["set_status", "fuun"]],
    "precedence_over": ["ton", "chii", "chon", "chon_honors"]
  },
  "anfuun": {
    "display_name": "Anfuun",
    "call": [[1, 2, 3]],
    "call_style": {"self": [["1x", 2], 0, 1, ["1x", 3]]},
    "call_conditions": [
      {"name": "match", "opts": [["called_tile"], [[[["1z","2z","3z","4z"], 1]]]]},
      [
        {"name": "not_status", "opts": ["riichi"]},
        {"name": "not_call_changes_waits", "opts": ["win"]}
      ]
    ],
    "show_when": [
      "our_turn", "not_no_tiles_remaining", "has_draw", "self_call_available", {"name": "status_missing", "opts": ["just_reached"]},
      [
        {"name": "not_status", "opts": ["riichi"]},
        {"name": "not_call_would_change_waits", "opts": ["win"]}
      ]
    ],
    "actions": [["big_text", "Fuun"], ["self_call"], ["draw"], ["set_status", "fuun"]]
  },
  "kapon": {
    "display_name": "Pon",
    "call": [[0, 0]],
    "call_style": {
      "kamicha": [["sideways", 0], "call_sideways", 1],
      "shimocha": [0, ["sideways", 1], "call_sideways"]
    },
    "upgrades": "ton",
    "show_when": ["our_turn", "not_no_tiles_remaining", "not_just_discarded", "not_just_called", "can_upgrade_call", {"name": "status_missing", "opts": ["just_reached"]}],
    "actions": [["big_text", "Pon"], ["upgrade_call"]]
  },
  "kakakan": {
    "display_name": "Kan",
    "call": [[0, 0, 0]],
    "call_style": {
      "kamicha": [["sideways", 0], ["sideways", 1], "call_sideways", 2],
      "shimocha": [0, ["sideways", 1], ["sideways", 2], "call_sideways"]
    },
    "upgrades": "kapon",
    "show_when": ["our_turn", "not_no_tiles_remaining", "not_just_discarded", "not_just_called", "can_upgrade_call", {"name": "status_missing", "opts": ["just_reached"]}],
    "actions": [["big_text", "Kan"], ["upgrade_call"], ["run", "do_kan_draw"]]
  },
  "kafuun": {
    "display_name": "Fuun",
    "call": [[1, 2, 3]],
    "call_style": {
      "kamicha": [["sideways", 0], "call_sideways", 1, 2],
      "toimen": [0, ["sideways", 1], "call_sideways", 2],
      "shimocha": [0, 1, ["sideways", 2], "call_sideways"]
    },
    "call_conditions": [
      {"name": "match", "opts": [["called_tile"], [[[["1z","2z","3z","4z"], 1]]]]}
    ],
    "upgrades": "chon_honors",
    "show_when": ["our_turn", "not_no_tiles_remaining", "not_just_discarded", "not_just_called", "can_upgrade_call", {"name": "status_missing", "opts": ["just_reached"]}],
    "actions": [["big_text", "Fuun"], ["upgrade_call"], ["draw"], ["set_status", "fuun"]]
  },
  "chanfuun": {
    "display_name": "Ron",
    "show_when": [
      "not_our_turn",
      {"name": "match", "opts": [["hand", "calls"], ["tenpai", "kokushi_tenpai"]]},
      {"name": "not_status", "opts": ["furiten"]},
      {"name": "not_status", "opts": ["just_reached"]},
      {"name": "last_call_is", "opts": ["kafuun"]},
      {"name": "match", "opts": [["hand", "calls", "last_called_tile"], ["win"]]}
    ],
    "actions": [["big_text", "Ron"], ["pause", 1000], ["reveal_hand"], ["set_status", "chanfuun"], ["win_by_call"]],
    "precedence_over": ["ton", "chii", "chon", "chon_honors", "daiminfuun", "pon", "daiminkan"]
  }
}
|
.buttons.chii.call_conditions += [{"name": "not_match", "opts": [["called_tile"], [[[["1z","2z","3z","4z","5z","6z","7z"], 1]]]]}]
|
.buttons.chii.precedence_over += ["ton"]
|
.buttons.pon.precedence_over += ["ton", "chon", "chon_honors", "daiminfuun"]
|
.buttons.daiminkan.precedence_over += ["ton", "chon", "chon_honors", "daiminfuun"]
|
.buttons.ron.precedence_over += ["ton", "chon", "chon_honors", "daiminfuun"]
|
.buttons.chankan.precedence_over += ["ton", "chon", "chon_honors", "daiminfuun"]