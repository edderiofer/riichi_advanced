.after_initialization.actions += [["add_rule", "Rules", "Shuugi", "Part of the player's starting score is composed of shuugi chips worth \($worth) each, which are gained and lost separately from points."]]
|
.after_win.actions += [
  ["when", [{"name": "status", "opts": ["ippatsu"]}, {"name": "status_missing", "opts": ["call_made"]}], [["add_counter", "shuugi_payment", 1]]],
  ["when", [{"name": "has_no_call_named", "opts": ["chii", "pon", "daiminkan", "kakan"]}], [["add_counter", "shuugi_payment", "aka"]]],
  ["when", [{"name": "has_no_call_named", "opts": ["chii", "pon", "daiminkan", "kakan"]}], [["add_counter", "shuugi_payment", "ao"]]],
  ["when", [{"name": "has_no_call_named", "opts": ["chii", "pon", "daiminkan", "kakan"]}], [["add_counter", "shuugi_payment", "kin"]]],
  ["add_counter", "shuugi_payment", "ura"],
  ["when", [{"name": "status", "opts": ["riichi", "shiro_pocchi"]}], [["add_counter", "shuugi_payment", 1]]],
  ["when", [{"name": "status", "opts": ["kindora"]}], [["add_counter", "shuugi_payment", 2]]],
  ["when", [{"name": "has_yaku2", "opts": [1]}], [["set_status", "yakuman"], ["add_counter", "yakuman_payment", 5], ["add_counter", "shuugi_payment", "yakuman_payment"]]],
  ["add_counter", "shuugi_payment", "toriuchi"],
  ["add_counter", "shuugi_payment", "galaxy_shuugi"],
  ["set_counter_all", "shuugi_payment", "shuugi_payment"],
  ["when", ["won_by_discard"], [
    ["when", [{"name": "counter_at_least", "opts": ["aka", 1]}], [["push_system_message", "Discarder pays 1 chip per aka dora in a closed hand (shuugi)"]]],
    ["when", [{"name": "counter_at_least", "opts": ["ao", 1]}], [["push_system_message", "Discarder pays 2 chip per ao dora in a closed hand (shuugi)"]]],
    ["when", [{"name": "counter_at_least", "opts": ["kin", 1]}], [["push_system_message", "Discarder pays 3 chip per kin dora in a closed hand (shuugi)"]]],
    ["when", [{"name": "counter_at_least", "opts": ["ura", 1]}], [["push_system_message", "Discarder pays 1 chip per ura dora (shuugi)"]]],
    ["when", [{"name": "status", "opts": ["ippatsu"]}, {"name": "status_missing", "opts": ["call_made"]}], [["push_system_message", "Discarder pays 1 chip for ippatsu (shuugi)"]]],
    ["when", [{"name": "status", "opts": ["yakuman"]}], [["push_system_message", "Discarder pays $chips chips for a yakuman win (shuugi)", {"chips": "yakuman_payment"}]]],
    ["when", [{"name": "status", "opts": ["kindora"]}], [["push_system_message", "Discarder pays 1 chip for golden chun used as a five (golden chun)"]]],
    ["when", [{"name": "counter_at_least", "opts": ["toriuchi", 1]}], [["push_system_message", "Discarder pays 1 chip per bird tile (toriuchi)"]]],
    ["when", [{"name": "counter_at_least", "opts": ["galaxy_shuugi", 1]}], [["push_system_message", "Discarder pays 1 chip per galaxy joker used as their original value (galaxy)"]]],
    ["as", "last_discarder", [["subtract_counter", "shuugi", "shuugi_payment"]]],
    ["add_counter", "shuugi", "shuugi_payment"]
  ]],
  ["when", ["won_by_draw"], [
    ["when", [{"name": "counter_at_least", "opts": ["aka", 1]}], [["push_system_message", "Everyone pays 1 chip per aka dora in a closed hand (shuugi)"]]],
    ["when", [{"name": "counter_at_least", "opts": ["ao", 1]}], [["push_system_message", "Everyone pays 2 chip per ao dora in a closed hand (shuugi)"]]],
    ["when", [{"name": "counter_at_least", "opts": ["kin", 1]}], [["push_system_message", "Everyone pays 3 chip per kin dora in a closed hand (shuugi)"]]],
    ["when", [{"name": "counter_at_least", "opts": ["ura", 1]}], [["push_system_message", "Everyone pays 1 chip per ura dora (shuugi)"]]],
    ["when", [{"name": "status", "opts": ["ippatsu"]}, {"name": "status_missing", "opts": ["call_made"]}], [["push_system_message", "Everyone pays 1 chip for ippatsu (shuugi)"]]],
    ["when", [{"name": "status", "opts": ["yakuman"]}], [["push_system_message", "Everyone pays $chips chips for a yakuman win (shuugi)", {"chips": "yakuman_payment"}]]],
    ["when", [{"name": "status", "opts": ["kindora"]}], [["push_system_message", "Everyone pays 1 chip for golden chun used as a five (golden chun)"]]],
    ["when", [{"name": "counter_at_least", "opts": ["toriuchi", 1]}], [["push_system_message", "Everyone pays 1 chip per bird tile (toriuchi)"]]],
    ["when", [{"name": "counter_at_least", "opts": ["galaxy_shuugi", 1]}], [["push_system_message", "Everyone pays 1 chip per galaxy joker used as their original value(galaxy)"]]],
    ["when", [{"name": "status", "opts": ["riichi", "shiro_pocchi"]}], [["push_system_message", "Everyone pays 1 chip for winning on shiro pocchi (shuugi)"]]],
    ["as", "others", [
      ["subtract_counter", "shuugi", "shuugi_payment"],
      ["as", "prev_seat", [["add_counter", "shuugi", "shuugi_payment"]]]
    ]]
  ]]
]
|
.after_start.actions += [["when_anyone", [], [["add_counter", "shuugi", 0]]]]
|
.before_conclusion.actions += [
  ["push_system_message", "Converted each shuugi to \($worth) points."],
  ["as", "everyone", [
    ["set_counter", "shuugi_payout", "shuugi"],
    ["multiply_counter", "shuugi_payout", $worth],
    ["add_score", "shuugi_payout"]
  ]]
]
|
.persistent_counters += ["shuugi"]
|
.shown_statuses_public += ["shuugi"]
