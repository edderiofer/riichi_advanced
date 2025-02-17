  # Each player begins with a joker.
    # change:

#  "starting_tiles": 13,

    # to:

#  "starting_tiles": 12,

    # and:

#  "after_start": {
#    "actions": [
#      ["set_status_all", "match_start", "first_charleston", "charleston_right", "heavenly_available"],
#      ["set_tile_alias_all", ["1j"], ["any"]],
#      ["set_tile_alias_all", ["2f", "3f", "4f", "1g", "2g", "3g", "4g"], ["1f"]]
#    ]
#  },

    # and:

#  "after_start": {
#    "actions": [
#      ["set_status_all", "match_start", "first_charleston", "charleston_right", "heavenly_available"],
#      ["set_tile_alias_all", ["1j"], ["any"]],
#      ["set_tile_alias_all", ["2f", "3f", "4f", "1g", "2g", "3g", "4g"], ["1f"]],
#      ["as", "all", ["draw", 1, "1j"]]
#    ]
#  },

    # and you might also have to change the wall to have four fewer jokers

  # All players start with thirteen tiles.
    # should be doable. we need to change:
    
#  "after_turn_change": {
#    "actions": [
#      ["when", ["no_tiles_remaining"], [["pause", 1000], ["ryuukyoku"]]],
#      // if dead hand, skip your turn, otherwise, draw a tile
#      ["ite", [{"name": "status", "opts": ["dead_hand"]}], [["advance_turn"]], [
#        ["when", ["not_no_tiles_remaining"], [["draw"]]]
#      ]]
#    ]
#  },

    # to:
    
#  "after_turn_change": {
#    "actions": [
#      ["when", ["no_tiles_remaining"], [["pause", 1000], ["ryuukyoku"]]],
#      // if dead hand, skip your turn, otherwise, draw a tile
#      ["ite", [{"name": "status", "opts": ["dead_hand"]}], [["advance_turn"]], [
#        ["when", ["not_no_tiles_remaining", {"name": "status", "opts": ["after_charleston"]}], [["draw"]]]
#      ]]
#    ]
#  },

    # or something like that, and then set the "after_charleston" variable only after the charleston has started.

  # East deals the tiles.
    # irrelevant
  # All Charleston passes are blind or negotiated.
    # should be easy. change:

#      "charleston_left": {
#      "display_name": "Select three tiles to pass left",
#      "show_when": [{"name": "status", "opts": ["charleston_left"]}],
#      "actions": [
#        ["mark", [["hand", 3, ["self", "not_joker"]]], [
#          ["unset_status", "charleston_left", "heavenly_available"],
#          ["merge_draw"],
#          ["sort_hand"],
#          ["when", [{"name": "status", "opts": ["blind_pass_left"]}], [["draw", 3, "1x"]]]
#        ]],
#        ["charleston_left"],
#        ["when", [{"name": "status", "opts": ["first_charleston"]}], [["unset_status", "first_charleston"], ["set_status", "decide_charleston"]]],
#        ["when", [{"name": "status", "opts": ["second_charleston"]}], [["set_status", "charleston_across"]]]
#      ],
#      "unskippable": true,
#      "cancellable": false
#    },

    # to:

#      "charleston_left": {
#      "display_name": "Select three tiles to pass left",
#      "show_when": [{"name": "status", "opts": ["charleston_left"]}],
#      "actions": [
#        ["mark", [["hand", 3, ["self", "not_joker"]]], [
#          ["unset_status", "charleston_left", "heavenly_available"],
#          ["merge_draw"],
#          ["sort_hand"],
#          ["draw", 3, "1x"]
#        ]],
#        ["charleston_left"],
#        ["when", [{"name": "status", "opts": ["first_charleston"]}], [["unset_status", "first_charleston"], ["set_status", "decide_charleston"]]],
#        ["when", [{"name": "status", "opts": ["second_charleston"]}], [["set_status", "charleston_across"]]]
#      ],
#      "unskippable": true,
#      "cancellable": false
#    },

    # and i guess also change whatever is related to the "blind_pass_left" status to make the messages appear properly. and also ditto for the right passes and across passes.

  # Jokers may be exchanged for natural tiles.
    # should probably also be easy, change:

#    "am_joker_swap": {
#      "display_name": "Swap for exposed joker",
#      "show_when": [{"name": "status_missing", "opts": ["match_start", "dead_hand"]}, "our_turn", "not_just_discarded", {"name": "match", "opts": [["hand_draw_nonjoker_any", "anyone_joker_meld_tiles"], [[[["pair"], 1]]]]}],
#      "actions": [
#        ["big_text", "Swap"],
#        ["mark", [["call", 1, ["call_has_joker", "match_call_to_marked_hand"]], ["hand", 1, ["self", "not_joker", "match_hand_to_marked_call"]]]],
#        ["swap_out_fly_joker", "1j"]
#      ]
#    },

    # add:

#    "am_reverse_joker_swap": {
#      "display_name": "Swap for exposed natural",
#        // does the below even work?
#      "show_when": [{"name": "status_missing", "opts": ["match_start", "dead_hand"]}, "our_turn", "not_just_discarded", {"name": "match", "opts": [["hand_draw_nonjoker_any", "anyone_joker_meld_tiles"], [[[["pair"], 1]]]]}],
#      "actions": [
#        ["big_text", "Swap"],
#             // somehow we need to switch the joker in our hand with the nonjoker in the call. this doesn't seem possible in Riichi Advanced yet...
#??        ["mark", [["call", 1, ["call_has_joker", "match_call_to_marked_hand"]], ["hand", 1, ["self", "not_joker", "match_hand_to_marked_call"]]]],
#??        ["swap_out_fly_joker", "1j"]
#      ]
#    },

    # actually this one might require an engine change to allow swapping out a nonjoker from a call. will have to see whether this is done in a Sakicards implementation.

  # A discarded joker earns an extra pick.
    # should probably also be easy. note that this is optional on the part of the player, so this will want a button:

#    "am_cycle_joker": {
#      "display_name": "Discard joker for extra draw",
#      "show_when": [{"name": "status_missing", "opts": ["match_start", "dead_hand"]}, "our_turn", "not_just_discarded", {"name": "match", "opts": [["hand", "draw"], [["joker"], 1]]}],
#      "actions": [
#        ["big_text", "Discard joker"],
#??      [// discard joker into pond somehow without changing turn //]
#??      [// draw another tile //]
#      ]
#    },

  # Tiles may be added to or removed from exposures.
    # probably difficult, but also probably doable. steal code for kakan:

#    "kakan": {
#      "display_name": "Kong",
#      "call": [[0, 0, 0]],
#      "upgrades": "pon",
#      "show_when": [{"name": "status_missing", "opts": ["match_start"]}, "our_turn", "not_no_tiles_remaining", "has_draw", "can_upgrade_call", {"name": "status_missing", "opts": ["just_reached"]}],
#      "actions": [
#        ["big_text", "Kong"], ["upgrade_call"],
#        ["when", [{"name": "status", "opts": ["kan"]}], [["set_status", "double_kan"]]],
#        ["set_status", "kan"],
#        ["draw", 1, "opposite_end"]
#      ]
#    },

    # and rename to "am_upgrade" vs "am_downgrade"

  # Consecutive runs may be played backwards.
    # probably requires engine change
  # A point-based scoring system is used.
    # probably requires engine change...?
