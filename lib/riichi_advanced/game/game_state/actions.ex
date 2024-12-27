
defmodule RiichiAdvanced.GameState.Actions do
  alias RiichiAdvanced.GameState.Buttons, as: Buttons
  alias RiichiAdvanced.GameState.Conditions, as: Conditions
  alias RiichiAdvanced.GameState.Debug, as: Debug
  alias RiichiAdvanced.GameState.Saki, as: Saki
  alias RiichiAdvanced.GameState.Marking, as: Marking
  alias RiichiAdvanced.GameState.Log, as: Log
  import RiichiAdvanced.GameState

  def temp_disable_play_tile(state, seat) do
    state = Map.update!(state, :play_tile_debounce, &Map.put(&1, seat, true))
    Debounce.apply(state.play_tile_debouncers[seat])
    state
  end

  def temp_display_big_text(state, seat, text) do
    state = update_player(state, seat, &%Player{ &1 | big_text: text })
    Debounce.apply(state.big_text_debouncers[seat])
    state
  end

  # we use this to ensure no double discarding
  def can_discard(state, seat, ignore_turn \\ false) do
    our_turn = seat == state.turn
    ((our_turn && state.players[seat].last_discard == nil && state.awaiting_discard) || ignore_turn)
    && not has_unskippable_button?(state, seat)
    && Enum.empty?(state.players[seat].call_buttons)
    && not Marking.needs_marking?(state, seat)
  end

  def play_tile(state, seat, tile, index) do
    if can_discard(state, seat) && is_playable?(state, seat, tile) do
      # IO.puts("#{seat} played tile: #{inspect(tile)} at index #{index}")
      
      tile = if "discard_facedown" in state.players[seat].status do {:"1x", Utils.tile_to_attrs(tile)} else tile end
      tile = Utils.add_attr(tile, ["discard"])

      tsumogiri = index >= length(state.players[seat].hand)
      state = update_player(state, seat, &%Player{ &1 |
        hand: List.delete_at(&1.hand ++ Utils.remove_attr(&1.draw, ["draw"]), index),
        pond: &1.pond ++ [tile],
        discards: &1.discards ++ [tile],
        draw: [],
        last_discard: {tile, index}
      })
      state = update_action(state, seat, :discard, %{tile: tile})
      push_message(state, [
        %{text: "Player #{seat} #{state.players[seat].nickname} discarded"},
        Utils.pt(tile)
      ] ++ if tsumogiri do [] else [%{text: "from hand"}] end)
      riichi = "just_reached" in state.players[seat].status
      state = Log.log(state, seat, :discard, %{tile: Utils.strip_attrs(tile), tsumogiri: tsumogiri, riichi: riichi})

      click_sounds = [
        "/audio/tile1.mp3",
        "/audio/tile2.mp3",
        "/audio/tile3.mp3",
        "/audio/tile4.mp3",
        "/audio/tile5.mp3",
      ]
      play_sound(state, Enum.random(click_sounds))

      # trigger play effects
      state = if Map.has_key?(state.rules, "play_effects") do
        doras = get_doras(state)
        for [tile_spec, actions] <- state.rules["play_effects"], Riichi.tile_matches(if is_list(tile_spec) do tile_spec else [tile_spec] end, %{tile: tile, doras: doras}), reduce: state do
          state -> run_actions(state, actions, %{seat: seat, tile: tile})
        end
      else state end

      state = Map.put(state, :awaiting_discard, false)

      state
    else
      IO.puts("#{seat} tried to play an unplayable tile: #{inspect(tile)}")
      state
    end
  end

  def draw_tile(state, seat, num, tile_spec \\ nil, to_aside \\ false) do
    if num > 0 do
      {tile_name, wall_index} = if tile_spec != nil do {tile_spec, state.wall_index} else {Enum.at(state.wall, state.wall_index, nil), state.wall_index + 1} end
      if tile_name == nil do
        # move a dead wall tile over
        if not Enum.empty?(state.dead_wall) do
          {wall_tiles, dead_wall} = Enum.split(state.dead_wall, 1)
          state = Map.put(state, :wall, state.wall ++ wall_tiles)
          state = Map.put(state, :dead_wall, dead_wall)
          draw_tile(state, seat, num, tile_spec, to_aside)
        else
          IO.puts("#{seat} tried to draw a nil tile!")
          state
        end
      else
        state = if is_binary(tile_name) && tile_name in state.reserved_tiles do
          Map.update!(state, :drawn_reserved_tiles, fn tiles -> [tile_name | tiles] end)
        else state end
        tile = from_named_tile(state, tile_name) |> Utils.add_attr(["draw"])
        state = if not to_aside do
          state = update_player(state, seat, &%Player{ &1 | draw: &1.draw ++ [tile] })
          state = Map.put(state, :wall_index, wall_index)
          state = update_action(state, seat, :draw, %{tile: tile})
          kan_draw = "kan" in state.players[seat].status
          state = Log.log(state, seat, :draw, %{tile: Utils.strip_attrs(tile), kan_draw: kan_draw})
          state
        else
          state = update_player(state, seat, &%Player{ &1 | aside: [tile | &1.aside] })
          state = Map.put(state, :wall_index, wall_index)
          state
        end

        # IO.puts("wall index is now #{get_state().wall_index}")
        draw_tile(state, seat, num - 1, tile_spec, to_aside)
      end
    else
      # run after_draw actions            
      state = if Map.has_key?(state.rules, "after_draw") do
        run_actions(state, state.rules["after_draw"]["actions"], %{seat: seat})
      else state end

      state
    end
  end

  def run_on_no_valid_tiles(state, seat, gas \\ 100) do
    if gas > 0 do
      if not Enum.any?(state.players[seat].hand, fn tile -> is_playable?(state, seat, tile) end) &&
         not Enum.any?(state.players[seat].draw, fn tile -> is_playable?(state, seat, tile) end) do
        state = run_actions(state, state.rules["on_no_valid_tiles"]["actions"], %{seat: seat})
        if Map.has_key?(state.rules["on_no_valid_tiles"], "recurse") && state.rules["on_no_valid_tiles"]["recurse"] do
          run_on_no_valid_tiles(state, seat, gas - 1)
        else state end
      else state end
    else state end
  end

  def change_turn(state, seat, via_action \\ false) do
    # get previous turn
    prev_turn = state.turn

    # erase previous turn's deferred actions
    state = if prev_turn != nil do
      update_player(state, prev_turn, &%Player{ &1 | deferred_actions: [], deferred_context: %{} })
    else state end

    # IO.puts("Changing turn from #{prev_turn} to #{seat}")

    # change turn
    state = Map.put(state, :turn, seat)

    if state.game_active do
      # run on turn change, unless this turn change was triggered by an action
      state = if not via_action && prev_turn != nil && seat != prev_turn && Map.has_key?(state.rules, "before_turn_change") do
        run_actions(state, state.rules["before_turn_change"]["actions"], %{seat: prev_turn})
      else state end
      state = if not via_action && seat != prev_turn && Map.has_key?(state.rules, "after_turn_change") do
        run_actions(state, state.rules["after_turn_change"]["actions"], %{seat: seat})
      else state end

      # check if any tiles are playable for this next player
      state = if Map.has_key?(state.rules, "on_no_valid_tiles") do
        run_on_no_valid_tiles(state, seat)
      else state end

      # sort hands if debug mode is on
      state = if Debug.debug() do
        update_all_players(state, fn _seat, player -> %Player{ player | hand: Utils.sort_tiles(player.hand) } end)
      else state end

      state = Map.put(state, :awaiting_discard, true)

      # ensure playable_indices is populated for the new turn
      state = broadcast_state_change(state, true)
      
      state
    else state end
  end

  def advance_turn(state) do
    # this action is called after playing a tile
    # it should trigger on_turn_change, so don't mark the turn change as via_action
    if state.game_active do
      new_turn = if state.reversed_turn_order do Utils.prev_turn(state.turn) else Utils.next_turn(state.turn) end
      new_turn = for _ <- 1..4, reduce: new_turn do
        new_turn -> if new_turn in state.available_seats do
          new_turn
        else
          if state.reversed_turn_order do Utils.prev_turn(new_turn) else Utils.next_turn(new_turn) end
        end
      end
      state = change_turn(state, new_turn)
      state
    else
      # reschedule this turn change
      schedule_actions(state, state.turn, [["advance_turn"]], %{seat: state.turn})
    end
  end

  defp style_call(style, call_choice, called_tile) do
    if called_tile != nil do
      tiles = if "call" in style or "call_sideways" in style do call_choice else call_choice ++ [called_tile] end
      for style_spec <- style, reduce: [] do
        acc ->
          tile = case style_spec do
            "call"                                  -> {called_tile, false}
            "call_sideways"                         -> {called_tile, true}
            ix when is_integer(ix)                  -> {Enum.at(tiles, ix), false}
            ["sideways", ix] when is_integer(ix)    -> {Enum.at(tiles, ix), true}
            ["1x", ix] when is_integer(ix)          -> {Enum.at(tiles, ix) |> Riichi.flip_facedown(), false}
            ["1x", "call"]                          -> {called_tile |> Riichi.flip_facedown(), false}
            ["1x", tile]                            -> {Utils.to_tile(tile) |> Riichi.flip_facedown(), false}
            ["1x_sideways", ix] when is_integer(ix) -> {Enum.at(tiles, ix) |> Riichi.flip_facedown(), true}
            ["1x_sideways", "call"]                 -> {called_tile |> Riichi.flip_facedown(), true}
            ["1x_sideways", tile]                   -> {Utils.to_tile(tile) |> Riichi.flip_facedown(), true}
            tile                                    -> {Utils.to_tile(tile), false}
          end
          [tile | acc]
      end |> Enum.reverse()
    else
      Enum.map(call_choice, fn tile -> {tile, false} end)
    end
  end

  def trigger_call(state, seat, button_name, call_choice, called_tile, call_source) do
    # get the actual called tile (with attrs)
    called_tile = case call_source do
      :discards -> Enum.at(state.players[state.turn].pond, -1)
      :hand     -> called_tile
      _         -> IO.puts("Unhandled call_source #{inspect(call_source)}")
    end

    call_name = Map.get(state.rules["buttons"][button_name], "call_name", button_name)
    default_call_style = Map.new(["self", "kamicha", "toimen", "shimocha"], fn dir -> {dir, 0..length(call_choice)} end)
    call_style = Map.merge(default_call_style, Map.get(state.rules["buttons"][button_name], "call_style", %{}))

    # style the call
    call = if called_tile != nil do
      style = call_style[Atom.to_string(Utils.get_relative_seat(seat, state.turn))]
      style_call(style, call_choice, called_tile)
    else
      Enum.map(call_choice, fn tile -> {tile, false} end)
    end

    # run before_call actions
    call = {call_name, call}
    state = if Map.has_key?(state.rules, "before_call") do
      run_actions(state, state.rules["before_call"]["actions"], %{seat: state.turn, callee: state.turn, caller: seat, call: call})
    else state end

    # remove called tiles from its source
    {state, to_remove} = case call_source do
      :discards -> {update_player(state, state.turn, &%Player{ &1 | pond: Enum.drop(&1.pond, -1) }), call_choice}
      :hand     -> {state, if called_tile != nil do [called_tile | call_choice] else call_choice end}
      _         -> IO.puts("Unhandled call_source #{inspect(call_source)}")
    end
    hand = Utils.add_attr(state.players[seat].hand, ["hand"])
    draw = Utils.add_attr(state.players[seat].draw, ["hand"])
    new_hand = Riichi.try_remove_all_tiles(hand ++ draw, to_remove) |> Enum.at(0) |> Utils.remove_attr(["hand", "draw"])
    # actually add the call to the player
    state = update_player(state, seat, &%Player{ &1 | hand: new_hand, draw: [], calls: &1.calls ++ [call] })
    state = if called_tile != nil do
      update_action(state, seat, :call, %{from: state.turn, called_tile: called_tile, other_tiles: call_choice, call_name: call_name})
    else
      # flower
      update_action(state, seat, :call, %{from: state.turn, called_tile: Enum.at(call_choice, 0), other_tiles: [], call_name: call_name})
    end

    # messages and log
    cond do
      Map.get(state.rules["buttons"][button_name], "call_hidden", false) ->
        push_message(state, [
          %{text: "Player #{seat} #{state.players[seat].nickname} called "},
          %{bold: true, text: "#{call_name}"}
        ])
      called_tile != nil ->
        push_message(state, [
          %{text: "Player #{seat} #{state.players[seat].nickname} called "},
          %{bold: true, text: "#{call_name}"},
          %{text: " on "},
          Utils.pt(called_tile),
          %{text: " with "}
        ] ++ Utils.ph(call_choice))
      true ->
        push_message(state, [
          %{text: "Player #{seat} #{state.players[seat].nickname} called "},
          %{bold: true, text: "#{call_name}"},
          %{text: " on "}
        ] ++ Utils.ph(call_choice))
    end
    state = Log.add_call(state, seat, call_name, call_choice, called_tile)
    click_sounds = [
      "/audio/call1.mp3",
      "/audio/call2.mp3",
      "/audio/call3.mp3",
      "/audio/call4.mp3",
      "/audio/call5.mp3",
    ]
    play_sound(state, Enum.random(click_sounds))

    # run after_call actions
    state = if Map.has_key?(state.rules, "after_call") do
      run_actions(state, state.rules["after_call"]["actions"], %{seat: seat, callee: state.turn, caller: seat, call: call})
    else state end

    state = update_player(state, seat, &%Player{ &1 | call_buttons: %{}, call_name: "" })
    state
  end

  defp upgrade_call(state, seat, call_name, call_choice, called_tile) do
    # find the index of the call whose tiles match call_choice
    index = state.players[seat].calls
      |> Enum.map(fn {_name, call} -> Enum.map(call, fn {tile, _sideways} -> tile end) end)
      |> Enum.find_index(fn call_tiles -> Riichi.try_remove_all_tiles(call_choice, call_tiles) == [[]] end)

    # upgrade that call
    {_name, call} = Enum.at(state.players[seat].calls, index)
    call_choice = Riichi.call_to_tiles({"", call})

    # find the index of the sideways tile to determine the direction
    sideways_index = Enum.find_index(call, fn {_tile, sideways} -> sideways end)
    sideways_index_rev = Enum.find_index(Enum.reverse(call), fn {_tile, sideways} -> sideways end)
    dir = cond do
      sideways_index == 0 -> :kamicha
      sideways_index_rev == 0 -> :shimocha # for 2-tile calls
      sideways_index == 1 -> :toimen
      sideways_index == 2 -> :shimocha
      true -> :self
    end

    # style the call
    default_call_style = Map.new(["self", "kamicha", "toimen", "shimocha"], fn dir -> {dir, 0..length(call_choice)} end)
    call_style = Map.merge(default_call_style, Map.get(state.rules["buttons"][call_name], "call_style", %{}))
    style = call_style[Atom.to_string(dir)]
    call = style_call(style, call_choice, called_tile)

    upgraded_call = {call_name, call}
    state = update_player(state, seat, &%Player{ &1 | hand: Riichi.try_remove_all_tiles(Utils.add_attr(&1.hand, ["hand"]) ++ Utils.add_attr(&1.draw, ["hand"]), [called_tile]) |> Enum.at(0) |> Utils.remove_attr(["hand"]), draw: [], calls: List.replace_at(state.players[seat].calls, index, upgraded_call) })
    state = update_action(state, seat, :call, %{from: state.turn, called_tile: called_tile, other_tiles: call_choice, call_name: call_name})
    state = update_player(state, seat, &%Player{ &1 | call_buttons: %{}, call_name: "" })
    state
  end

  def interpret_amount(state, context, amt_spec) do
    case amt_spec do
      ["count_matches" | opts] ->
        # count how many times the given hand calls spec matches the given match definition
        hand_calls = Conditions.get_hand_calls_spec(state, context, Enum.at(opts, 0, []))
        match_definitions = translate_match_definitions(state, Enum.at(opts, 1, []))
        ordering = state.players[context.seat].tile_ordering
        ordering_r = state.players[context.seat].tile_ordering_r
        tile_aliases = state.players[context.seat].tile_aliases
        Riichi.binary_search_count_matches(hand_calls, match_definitions, ordering, ordering_r, tile_aliases)
      ["count_matching_ways" | opts] ->
        # count how many given hand-calls combinations matches the given match definition
        hand_calls = Conditions.get_hand_calls_spec(state, context, Enum.at(opts, 0, []))
        match_definitions = translate_match_definitions(state, Enum.at(opts, 1, []))
        ordering = state.players[context.seat].tile_ordering
        ordering_r = state.players[context.seat].tile_ordering_r
        tile_aliases = state.players[context.seat].tile_aliases
        Enum.count(hand_calls, fn {hand, calls} -> Riichi.match_hand(hand, calls, match_definitions, ordering, ordering_r, tile_aliases) end)
      ["tiles_in_wall" | _opts] -> length(state.wall) - state.wall_index
      ["num_discards" | _opts] -> length(state.players[context.seat].discards)
      ["num_aside" | _opts] -> length(state.players[context.seat].aside)
      ["num_facedown_tiles" | _opts] -> Utils.count_tiles(state.players[context.seat].pond, [:"1x"])
      ["num_facedown_tiles_others" | _opts] ->
        for {seat, player} <- state.players, seat != context.seat do
          Utils.count_tiles(player.pond, [:"1x"])
        end |> Enum.sum()
      ["num_matching_revealed_tiles_all" | opts] ->
        for {_seat, player} <- state.players do
          player.hand ++ player.draw
          |> Enum.filter(&Riichi.tile_matches(opts, %{tile: &1}))
          |> Utils.count_tiles([{:any, ["revealed"]}])
        end |> Enum.sum()
      ["num_matching_melded_tiles_all" | opts] ->
        for {_seat, player} <- state.players do
          player.calls
          |> Enum.flat_map(&Riichi.call_to_tiles/1)
          |> Enum.count(&Riichi.tile_matches(opts, %{tile: &1}))
        end |> Enum.sum()
      ["half_score" | _opts] -> Utils.half_score_rounded_up(state.players[context.seat].score)
      ["100_times_tile_number" | _opts] ->
        cond do
          Riichi.is_num?(context.tile, 1) -> 100
          Riichi.is_num?(context.tile, 2) -> 200
          Riichi.is_num?(context.tile, 3) -> 300
          Riichi.is_num?(context.tile, 4) -> 400
          Riichi.is_num?(context.tile, 5) -> 500
          Riichi.is_num?(context.tile, 6) -> 600
          Riichi.is_num?(context.tile, 7) -> 700
          Riichi.is_num?(context.tile, 8) -> 800
          Riichi.is_num?(context.tile, 9) -> 900
          true                            -> 0
        end
      ["count_draws" | opts] ->
        seat = Conditions.from_seat_spec(state, context, Enum.at(opts, 0))
        length(state.players[seat].draw)
      ["count_dora" | opts] ->
        dora_indicator = from_named_tile(state, Enum.at(opts, 0, :"1m"))
        {hand, calls} = Conditions.get_hand_calls_spec(state, context, Enum.at(opts, 1, [])) |> Enum.at(0)
        hand = hand ++ Enum.flat_map(calls, &Riichi.call_to_tiles/1)
        if dora_indicator != nil do
          doras = Map.get(state.rules["dora_indicators"], Utils.tile_to_string(dora_indicator), []) |> Enum.map(&Utils.to_tile/1)
          Utils.count_tiles(hand, doras)
        else 0 end
      ["count_reverse_dora" | opts] ->
        dora_indicator = from_named_tile(state, Enum.at(opts, 0, :"1m"))
        {hand, calls} = Conditions.get_hand_calls_spec(state, context, Enum.at(opts, 1, [])) |> Enum.at(0)
        hand = hand ++ Enum.flat_map(calls, &Riichi.call_to_tiles/1)
        if dora_indicator != nil do
          doras = Map.get(state.rules["reverse_dora_indicators"], Utils.tile_to_string(dora_indicator), []) |> Enum.map(&Utils.to_tile/1)
          Utils.count_tiles(hand, doras)
        else 0 end
      ["pot" | _opts] -> state.pot
      ["honba" | _opts] -> state.honba
      ["riichi_value" | _opts] -> get_in(state.rules["score_calculation"]["riichi_value"]) || 0
      ["honba_value" | _opts] -> get_in(state.rules["score_calculation"]["honba_value"]) || 0
      [amount | _opts] when is_binary(amount) -> Map.get(state.players[context.seat].counters, amount, 0)
      [amount | _opts] when is_number(amount) -> Utils.try_integer(amount)
      _ ->
        IO.puts("Unknown amount spec #{inspect(amt_spec)}")
        0
    end
  end

  defp set_counter(state, context, counter_name, amt_spec) do
    amount = interpret_amount(state, context, amt_spec)
    put_in(state.players[context.seat].counters[counter_name], amount)
  end

  defp set_counter_all(state, context, counter_name, amt_spec) do
    amount = interpret_amount(state, context, amt_spec)
    for dir <- state.available_seats, reduce: state do
      state -> put_in(state.players[dir].counters[counter_name], amount)
    end
  end

  defp add_counter(state, context, counter_name, amt_spec) do
    amount = interpret_amount(state, context, amt_spec)
    new_ctr = amount + Map.get(state.players[context.seat].counters, counter_name, 0)
    put_in(state.players[context.seat].counters[counter_name], new_ctr)
  end

  defp subtract_counter(state, context, counter_name, amt_spec) do
    amount = interpret_amount(state, context, amt_spec)
    new_ctr = -amount + Map.get(state.players[context.seat].counters, counter_name, 0)
    put_in(state.players[context.seat].counters[counter_name], new_ctr)
  end
  
  defp multiply_counter(state, context, counter_name, amt_spec) do
    amount = interpret_amount(state, context, amt_spec)
    new_ctr = Utils.try_integer(amount * Map.get(state.players[context.seat].counters, counter_name, 0))
    put_in(state.players[context.seat].counters[counter_name], new_ctr)
  end
  
  defp divide_counter(state, context, counter_name, amt_spec) do
    amount = interpret_amount(state, context, amt_spec)
    new_ctr = Integer.floor_div(Map.get(state.players[context.seat].counters, counter_name, 0), amount)
    put_in(state.players[context.seat].counters[counter_name], new_ctr)
  end

  defp do_charleston(state, dir, seat, marked_objects) do
    marked = Marking.get_marked(marked_objects, :hand)
    {_, hand_seat, _} = Enum.at(marked, 0)
    {hand_tiles, hand_indices} = marked
    |> Enum.map(fn {tile, _seat, ix} -> {tile, ix} end)
    |> Enum.unzip()
    # remove specified tiles from hand
    state = for ix <- Enum.sort(hand_indices, :desc), reduce: state do
      state ->
        hand_length = length(state.players[hand_seat].hand)
        if ix < hand_length do
          update_player(state, hand_seat, &%Player{ &1 | hand: List.delete_at(&1.hand, ix) })
        else
          update_player(state, hand_seat, &%Player{ &1 | draw: List.delete_at(&1.draw, ix - hand_length) })
        end
    end
    # send them according to dir
    state = update_player(state, Utils.get_seat(hand_seat, dir), &%Player{ &1 | hand: &1.hand ++ Utils.remove_attr(&1.draw, ["draw"]), draw: hand_tiles, status: MapSet.put(&1.status, "_charleston_completed") })
    state = Marking.mark_done(state, seat)

    # if everyone has charleston completed then we run after_charleston actions
    state = if Enum.all?(state.players, fn {_seat, player} -> "_charleston_completed" in player.status end) do
      state = update_all_players(state, fn _seat, player -> %Player{ player | status: MapSet.delete(player.status, "_charleston_completed") } end)
      if Map.has_key?(state.rules, "after_charleston") do
        run_actions(state, state.rules["after_charleston"]["actions"], %{seat: seat})
      else state end
    else state end
    state
  end

  defp translate_tile_alias(state, context, tile_alias) do
    ret = case tile_alias do
      "draw" -> state.players[context.seat].draw
      "last_discard" -> if get_last_discard_action(state) != nil do [get_last_discard_action(state).tile] else [] end
      "last_called_tile" -> if get_last_call_action(state) != nil do [get_last_call_action(state).called_tile] else [] end
      [tile_alias | attrs] -> translate_tile_alias(state, context, tile_alias) |> Utils.add_attr(attrs)
      _      -> [Utils.to_tile(tile_alias)]
    end
    ret
  end

  defp set_tile_alias(state, seat, from_tiles, to_tiles) do
    from_tiles = MapSet.new(from_tiles)
    aliases = for to <- to_tiles, reduce: state.players[seat].tile_aliases do
      aliases ->
        {to, attrs} = Utils.to_attr_tile(to)
        Map.update(aliases, to, %{attrs => from_tiles}, fn from -> Map.update(from, attrs, from_tiles, &MapSet.union(&1, from_tiles)) end)
    end
    state = update_player(state, seat, &%Player{ &1 | tile_aliases: aliases })
    mappings = for from <- from_tiles, reduce: state.players[seat].tile_mappings do
      mappings -> Map.update(mappings, from, Enum.uniq(to_tiles), fn to -> Enum.uniq(to ++ to_tiles) end)
    end
    state = update_player(state, seat, &%Player{ &1 | tile_mappings: mappings })
    state
  end

  def add_attr_matching(tiles, attrs, tile_specs) do
    for tile <- tiles do
      if Riichi.tile_matches_all(tile_specs, %{tile: tile}) do
        Utils.add_attr(tile, attrs)
      else tile end
    end
  end

  defp call_function(state, context, fn_name, args) do
    if length(state.call_stack) < 10 do
      args = Map.new(args, fn {name, value} -> {"$" <> name, value} end)
      state = Map.update!(state, :call_stack, &[[fn_name | args] | &1])
      actions = Map.get(state.rules["functions"], fn_name)
      actions = map_action_opts(actions, &Map.get(args, &1, &1))
      if Debug.debug_actions() do
        IO.puts("Running function: #{inspect(actions)}")
      end
      state = run_actions(state, actions, context)
      state = Map.update!(state, :call_stack, &Enum.drop(&1, 1))
      state
    else
      IO.puts("Cannot call function #{fn_name}: call stack limit reached")
      state
    end
  end

  defp _run_actions(state, [], _context), do: {state, []}
  defp _run_actions(state, [[action | opts] | actions], context) do
    buttons_before = Enum.map(state.players, fn {seat, player} -> {seat, player.buttons} end)
    marked_objects = state.marking[context.seat]
    uninterruptible = String.starts_with?(action, "uninterruptible_")
    action = if uninterruptible do String.slice(action, 16..-1//1) else action end
    state = case action do
      "noop"                  -> state
      "print"                 ->
        IO.inspect(opts)
        state
      "print_counter"         ->
        IO.inspect({context.seat, Map.get(state.players[context.seat].counters, Enum.at(opts, 0), 0)})
        state
      "push_message"          ->
        push_message(state, Enum.map(["Player #{context.seat} #{state.players[context.seat].nickname}"] ++ opts, fn msg -> %{text: msg} end))
        state
      "push_system_message"   ->
        push_message(state, Enum.map(opts, fn msg -> %{text: msg} end))
        state
      "run"                   -> call_function(state, context, Enum.at(opts, 0, "noop"), Enum.at(opts, 1, %{}))
      "play_tile"             -> play_tile(state, context.seat, Enum.at(opts, 0, :"1m"), Enum.at(opts, 1, 0))
      "draw"                  -> draw_tile(state, context.seat, Enum.at(opts, 0, 1), Enum.at(opts, 1, nil), false)
      "draw_aside"            -> draw_tile(state, context.seat, Enum.at(opts, 0, 1), Enum.at(opts, 1, nil), true)
      "call"                  -> trigger_call(state, context.seat, context.call_name, context.call_choice, context.called_tile, :discards)
      "self_call"             -> trigger_call(state, context.seat, context.call_name, context.call_choice, context.called_tile, :hand)
      "upgrade_call"          -> upgrade_call(state, context.seat, context.call_name, context.call_choice, context.called_tile)
      "flower"                -> trigger_call(state, context.seat, context.call_name, context.call_choice, nil, :hand)
      "draft_saki_card"       -> Saki.draft_saki_card(state, context.seat, context.choice)
      "reverse_turn_order"    -> Map.update!(state, :reversed_turn_order, &not &1)
      "advance_turn"          -> advance_turn(state)
      "change_turn"           -> change_turn(state, Conditions.from_seat_spec(state, context, Enum.at(opts, 0, "self")), true)
      "win_by_discard"        -> win(state, context.seat, get_last_discard_action(state).tile, :discard)
      "win_by_call"           -> win(state, context.seat, get_last_call_action(state).called_tile, :call)
      "win_by_draw"           -> win(state, context.seat, Enum.at(state.players[context.seat].draw, 0), :draw)
      "win_by_second_visible_discard" ->
        seat = get_last_discard_action(state).seat
        tile = state.players[seat].pond
        |> Enum.reverse()
        |> Enum.drop(1)
        |> Enum.find(fn tile -> Utils.count_tiles([tile], [:"1x", :"2x"]) == 0 end)
        win(state, context.seat, tile, :discard)
      "ryuukyoku"             -> exhaustive_draw(state)
      "abortive_draw"         -> abortive_draw(state, Enum.at(opts, 0, "Abortive draw"))
      "set_status"            -> update_player(state, context.seat, fn player -> %Player{ player | status: MapSet.union(player.status, MapSet.new(opts)) } end)
      "unset_status"          -> update_player(state, context.seat, fn player -> %Player{ player | status: MapSet.difference(player.status, MapSet.new(opts)) } end)
      "set_status_all"        -> update_all_players(state, fn _seat, player -> %Player{ player | status: MapSet.union(player.status, MapSet.new(opts)) } end)
      "unset_status_all"      -> update_all_players(state, fn _seat, player -> %Player{ player | status: MapSet.difference(player.status, MapSet.new(opts)) } end)
      "set_counter"           -> set_counter(state, context, Enum.at(opts, 0, "counter"), Enum.drop(opts, 1))
      "set_counter_all"       -> set_counter_all(state, context, Enum.at(opts, 0, "counter"), Enum.drop(opts, 1))
      "add_counter"           -> add_counter(state, context, Enum.at(opts, 0, "counter"), Enum.drop(opts, 1))
      "subtract_counter"      -> subtract_counter(state, context, Enum.at(opts, 0, "counter"), Enum.drop(opts, 1))
      "multiply_counter"      -> multiply_counter(state, context, Enum.at(opts, 0, "counter"), Enum.drop(opts, 1))
      "divide_counter"        -> divide_counter(state, context, Enum.at(opts, 0, "counter"), Enum.drop(opts, 1))
      "big_text"              ->
        seat = Conditions.from_seat_spec(state, context, Enum.at(opts, 1, "self"))
        temp_display_big_text(state, seat, Enum.at(opts, 0, ""))
      "pause"                 ->
        if not state.log_loading_mode do
          Map.put(state, :game_active, false)
        else state end
      "sort_hand"             ->
        {hand, orig_ixs} = Enum.with_index(state.players[context.seat].hand)
        |> Enum.sort_by(fn {tile, _ix} -> Utils.sort_value(tile) end)
        |> Enum.unzip()
        ix_map = Enum.with_index(orig_ixs) |> Map.new()
        # map marked tiles' indices
        state = update_in(state.marking[context.seat], &Enum.map(&1, fn {key, val} ->
          if key == :hand do
            {key, update_in(val.marked, fn marked -> Enum.map(marked, fn {tile, seat, ix} -> {tile, seat, Map.get(ix_map, ix, ix)} end) end)}
          else {key, val} end
        end))
        state = update_player(state, context.seat, fn player -> %Player{ player | hand: hand } end)
        state
      "reveal_tile"           ->
        tile_name = Enum.at(opts, 0, :"1m")
        state = Map.update!(state, :revealed_tiles, fn tiles -> tiles ++ [tile_name] end)
        state = if is_integer(tile_name) do
          Log.log(state, context.seat, :dora_flip, %{dora_count: length(state.revealed_tiles), dora_indicator: from_named_tile(state, tile_name)})
        else state end
        state
      "add_score"             ->
        recipients = Conditions.from_seats_spec(state, context, Enum.at(opts, 1, "self"))
        amount = interpret_amount(state, context, [Enum.at(opts, 0, 0)])
        for recipient <- recipients, reduce: state do
          state -> update_player(state, recipient, fn player -> %Player{ player | score: player.score + amount } end)
        end
      "subtract_score"             ->
        recipients = Conditions.from_seats_spec(state, context, Enum.at(opts, 1, "self"))
        amount = -interpret_amount(state, context, [Enum.at(opts, 0, 0)])
        for recipient <- recipients, reduce: state do
          state -> update_player(state, recipient, fn player -> %Player{ player | score: player.score + amount } end)
        end
      "put_down_riichi_stick" -> state |> Map.update!(:pot, & &1 + Enum.at(opts, 0, 1) * state.rules["score_calculation"]["riichi_value"]) |> update_player(context.seat, &%Player{ &1 | riichi_stick: true, riichi_discard_indices: Map.new(state.players, fn {seat, player} -> {seat, length(player.discards)} end) })
      "bet_points"            ->
        amount = interpret_amount(state, context, opts)
        state |> Map.update!(:pot, & &1 + amount) |> update_player(context.seat, &%Player{ &1 | score: &1.score - amount })
      "add_honba"             -> Map.update!(state, :honba, & &1 + Enum.at(opts, 0, 1))
      "reveal_hand"           -> update_player(state, context.seat, fn player -> %Player{ player | hand_revealed: true } end)
      "reveal_other_hands"    -> update_all_players(state, fn seat, player -> %Player{ player | hand_revealed: player.hand_revealed || seat != context.seat } end)
      "discard_draw"          ->
        # need to do this or else we might reenter adjudicate_actions
        :timer.apply_after(100, GenServer, :cast, [self(), {:play_tile, context.seat, length(state.players[context.seat].hand)}])
        state
      "press_button"          ->
        # need to do this or else we might reenter adjudicate_actions
        :timer.apply_after(100, GenServer, :cast, [self(), {:press_button, context.seat, Enum.at(opts, 0, "skip")}])
        state
      "press_first_call_button" ->
        button_choice = Map.get(state.players[context.seat].button_choices, Enum.at(opts, 0, "skip"), nil)
        case button_choice do
          {:call, call_choices} ->
            {called_tile, choices} = Enum.at(call_choices, 0)
            call_choice = Enum.at(choices, 0)
            # need to do this or else we might reenter adjudicate_actions
            :timer.apply_after(100, GenServer, :cast, [self(), {:press_call_button, context.seat, call_choice, called_tile}])
          _ -> :ok
        end
        state
      "when"                  -> if Conditions.check_cnf_condition(state, Enum.at(opts, 0, []), context) do run_actions(state, Enum.at(opts, 1, []), context) else state end
      "unless"                -> if Conditions.check_cnf_condition(state, Enum.at(opts, 0, []), context) do state else run_actions(state, Enum.at(opts, 1, []), context) end
      "ite"                   -> if Conditions.check_cnf_condition(state, Enum.at(opts, 0, []), context) do run_actions(state, Enum.at(opts, 1, []), context) else run_actions(state, Enum.at(opts, 2, []), context) end
      "as"                    ->
        for dir <- Conditions.from_seats_spec(state, context, Enum.at(opts, 0, [])), reduce: state do
          state -> run_actions(state, Enum.at(opts, 1, []), %{context | seat: dir})
        end
      "when_anyone"           ->
        for dir <- state.available_seats, Conditions.check_cnf_condition(state, Enum.at(opts, 0, []), %{context | seat: dir}), reduce: state do
          state -> run_actions(state, Enum.at(opts, 1, []), %{context | seat: dir})
        end
      "when_everyone"           ->
        if Enum.all?(state.available_seats, fn dir -> Conditions.check_cnf_condition(state, Enum.at(opts, 0, []), %{context | seat: dir}) end) do
          run_actions(state, Enum.at(opts, 1, []), context)
        else state end
      "when_others"           ->
        if Enum.all?(state.available_seats -- [context.seat], fn dir -> Conditions.check_cnf_condition(state, Enum.at(opts, 0, []), %{context | seat: dir}) end) do
          run_actions(state, Enum.at(opts, 1, []), context)
        else state end
      "mark" -> state # no-op
      "swap_marked_hand_and_discard" ->
        {hand_tile, hand_seat, hand_index} = Marking.get_marked(marked_objects, :hand) |> Enum.at(0)
        {discard_tile, discard_seat, discard_index} = Marking.get_marked(marked_objects, :discard) |> Enum.at(0)

        # replace pond tile with hand tile
        state = update_player(state, discard_seat, &%Player{ &1 | pond: List.replace_at(&1.pond, discard_index, hand_tile) })

        # replace hand tile with pond tile
        hand_length = length(state.players[hand_seat].hand)
        state = if hand_index < hand_length do
          update_player(state, hand_seat, &%Player{ &1 | hand: List.replace_at(&1.hand, hand_index, discard_tile) })
        else
          update_player(state, hand_seat, &%Player{ &1 | draw: List.replace_at(&1.draw, hand_index - hand_length, discard_tile) })
        end

        state = update_action(state, context.seat, :swap, %{tile1: {hand_tile, hand_seat, hand_index, :hand}, tile2: {discard_tile, discard_seat, discard_index, :discard}})
        state = Marking.mark_done(state, context.seat)
        state
      "swap_marked_hand_and_dora_indicator" ->
        {hand_tile, hand_seat, hand_index} = Marking.get_marked(marked_objects, :hand) |> Enum.at(0)
        {revealed_tile, _, revealed_tile_index} = Marking.get_marked(marked_objects, :revealed_tile) |> Enum.at(0)

        # replace revealed tile with hand tile
        state = replace_revealed_tile(state, revealed_tile_index, hand_tile)

        # replace hand tile with revealed tile
        hand_length = length(state.players[hand_seat].hand)
        state = if hand_index < hand_length do
          update_player(state, hand_seat, &%Player{ &1 | hand: List.replace_at(&1.hand, hand_index, revealed_tile) })
        else
          update_player(state, hand_seat, &%Player{ &1 | draw: List.replace_at(&1.draw, hand_index - hand_length, revealed_tile) })
        end

        state = update_action(state, context.seat, :swap, %{tile1: {hand_tile, hand_seat, hand_index, :hand}, tile2: {revealed_tile, nil, revealed_tile_index, :discard}})
        state = Marking.mark_done(state, context.seat)
        state
      "swap_marked_hand_and_scry" ->
        marked_hand = Marking.get_marked(marked_objects, :hand)
        marked_scry = Marking.get_marked(marked_objects, :scry)
        {_, hand_seat, _} = Enum.at(marked_hand, 0)
        {hand_tiles, hand_indices} = marked_hand
        |> Enum.map(fn {tile, _seat, ix} -> {tile, ix} end)
        |> Enum.unzip()
        {scry_tiles, scry_indices} = marked_scry
        |> Enum.map(fn {tile, _seat, ix} -> {tile, ix} end)
        |> Enum.unzip()

        zip1 = Enum.zip(hand_tiles, scry_indices)
        zip2 = Enum.zip(scry_tiles, hand_indices)

        # replace wall tiles with hand tiles
        state = for {hand_tile, scry_index} <- zip1, reduce: state do
          state -> update_in(state.wall, &List.replace_at(&1, state.wall_index + scry_index, hand_tile))
        end

        # replace hand tiles with wall tiles
        hand_length = length(state.players[hand_seat].hand)
        state = for {{scry_tile, hand_index}, {hand_tile, scry_index}} <- Enum.zip(zip2, zip1), reduce: state do
          state ->
            state = update_action(state, context.seat, :swap, %{tile1: {hand_tile, hand_seat, hand_index, :hand}, tile2: {scry_tile, nil, scry_index, :discard}})
            if hand_index < hand_length do
              update_player(state, hand_seat, &%Player{ &1 | hand: List.replace_at(&1.hand, hand_index, scry_tile) })
            else
              update_player(state, hand_seat, &%Player{ &1 | draw: List.replace_at(&1.draw, hand_index - hand_length, scry_tile) })
            end
        end

        state = Marking.mark_done(state, context.seat)
        state
      "swap_marked_scry_and_dora_indicator" ->
        {revealed_tile, _, revealed_tile_index} = Marking.get_marked(marked_objects, :revealed_tile) |> Enum.at(0)
        {scry_tile, _, scry_index} = Marking.get_marked(marked_objects, :scry) |> Enum.at(0)

        # replace wall tile with revealed tile
        state = update_in(state.wall, &List.replace_at(&1, state.wall_index + scry_index, revealed_tile))

        # replace revealed tile with wall tile
        state = replace_revealed_tile(state, revealed_tile_index, scry_tile)

        state = Marking.mark_done(state, context.seat)
        state
      "swap_marked_calls" ->
        marked_call = Marking.get_marked(marked_objects, :call)
        {call1, call_seat1, call_index1} = Enum.at(marked_call, 0)
        {call2, call_seat2, call_index2} = Enum.at(marked_call, 1)

        state = update_player(state, call_seat1, &%Player{ &1 | calls: List.replace_at(&1.calls, call_index1, call2) })
        state = update_player(state, call_seat2, &%Player{ &1 | calls: List.replace_at(&1.calls, call_index2, call1) })

        state = Marking.mark_done(state, context.seat)
        state
      "swap_out_fly_joker" ->
        {tile, hand_seat, hand_index} = Marking.get_marked(marked_objects, :hand) |> Enum.at(0)
        {call, call_seat, call_index} = Marking.get_marked(marked_objects, :call) |> Enum.at(0)
        fly_joker = Enum.at(opts, 0, "1j") |> Utils.to_tile()
        call_tiles = Riichi.call_to_tiles(call)

        call_joker_index = Enum.find_index(call_tiles, &Utils.same_tile(&1, fly_joker))
        new_call = with {call_type, call_content} <- call do
          {call_type, List.update_at(call_content, call_joker_index, fn {_t, sideways} -> {tile, sideways} end)}
        end
        push_message(state, [
          %{text: "Player #{context.seat} #{state.players[context.seat].nickname} swapped out a joker from the call"}
        ] ++ Utils.ph(call_tiles))

        # replace hand tile with joker
        hand_length = length(state.players[hand_seat].hand)
        state = if hand_index < hand_length do
          update_player(state, hand_seat, &%Player{ &1 | hand: List.replace_at(&1.hand, hand_index, fly_joker) })
        else
          update_player(state, hand_seat, &%Player{ &1 | draw: List.replace_at(&1.draw, hand_index - hand_length, fly_joker) })
        end

        # replace call with new call
        state = update_player(state, call_seat, &%Player{ &1 | calls: List.replace_at(&1.calls, call_index, new_call) })

        state = Marking.mark_done(state, context.seat)
        state
      "extend_live_wall_with_marked" ->
        marked_hand = Marking.get_marked(marked_objects, :hand)
        marked_scry = Marking.get_marked(marked_objects, :scry)
        {state, hand_tiles} = if not Enum.empty?(marked_hand) do
          {_, hand_seat, _} = Enum.at(marked_hand, 0)
          {hand_tiles, hand_indices} = marked_hand
          |> Enum.map(fn {tile, _seat, ix} -> {tile, ix} end)
          |> Enum.unzip()
          # remove specified tiles from hand (rightmost first)
          hand_length = length(state.players[hand_seat].hand)
          state = for ix <- Enum.sort_by(hand_indices, fn ix -> -ix end), reduce: state do
            state ->
              if ix < hand_length do
                update_player(state, hand_seat, &%Player{ &1 | hand: List.delete_at(&1.hand, ix) })
              else
                update_player(state, hand_seat, &%Player{ &1 | draw: List.delete_at(&1.draw, ix - hand_length) })
              end
          end
          {state, hand_tiles}
        else {state, []} end

        {state, scry_tiles} = if not Enum.empty?(marked_scry) do
          {scry_tiles, scry_indices} = marked_scry
          |> Enum.map(fn {tile, _seat, ix} -> {tile, ix} end)
          |> Enum.unzip()
          state = for _i <- scry_indices, reduce: state do
            state -> update_in(state.wall, &List.delete_at(&1, state.wall_index))
          end
          state = update_all_players(state, fn _seat, player -> %Player{ player | num_scryed_tiles: 0 } end)
          {state, scry_tiles}
        else {state, []} end

        # place them at the end of the live wall
        state = for tile <- (hand_tiles ++ scry_tiles), reduce: state do
          state -> Map.update!(state, :wall, fn wall -> List.insert_at(wall, -1, tile) end)
        end
        state = Marking.mark_done(state, context.seat)
        state
      "extend_dead_wall_with_marked" ->
        marked_hand = Marking.get_marked(marked_objects, :hand)
        {_, hand_seat, _} = Enum.at(marked_hand, 0)
        {hand_tiles, hand_indices} = marked_hand
        |> Enum.map(fn {tile, _seat, ix} -> {tile, ix} end)
        |> Enum.unzip()
        # remove specified tiles from hand (rightmost first)
        hand_length = length(state.players[hand_seat].hand)
        state = for ix <- Enum.sort_by(hand_indices, fn ix -> -ix end), reduce: state do
          state ->
            if ix < hand_length do
              update_player(state, hand_seat, &%Player{ &1 | hand: List.delete_at(&1.hand, ix) })
            else
              update_player(state, hand_seat, &%Player{ &1 | draw: List.delete_at(&1.draw, ix - hand_length) })
            end
        end
        # place them at the end of the dead wall
        state = for tile <- hand_tiles, reduce: state do
          state -> Map.update!(state, :dead_wall, fn dead_wall -> List.insert_at(dead_wall, -1, tile) end)
        end
        state = Marking.mark_done(state, context.seat)
        state
      "set_aside_marked_discard" ->
        {discard_tile, discard_seat, discard_index} = Marking.get_marked(marked_objects, :discard) |> Enum.at(0)

        # replace pond tile with blank
        state = update_player(state, discard_seat, &%Player{ &1 | pond: List.replace_at(&1.pond, discard_index, :"2x") })

        # set discard_tile aside
        state = update_player(state, context.seat, &%Player{ &1 | aside: &1.aside ++ [discard_tile] })

        state = Marking.mark_done(state, context.seat)
        state
      "set_aside_marked_hand" ->
        marked_hand = Marking.get_marked(marked_objects, :hand)
        {_, hand_seat, _} = Enum.at(marked_hand, 0)
        {hand_tiles, hand_indices} = marked_hand
        |> Enum.map(fn {tile, _seat, ix} -> {tile, ix} end)
        |> Enum.unzip()
        # remove specified tiles from hand (rightmost first)
        hand_length = length(state.players[hand_seat].hand)
        state = for ix <- Enum.sort_by(hand_indices, fn ix -> -ix end), reduce: state do
          state ->
            if ix < hand_length do
              update_player(state, hand_seat, &%Player{ &1 | hand: List.delete_at(&1.hand, ix) })
            else
              update_player(state, hand_seat, &%Player{ &1 | draw: List.delete_at(&1.draw, ix - hand_length) })
            end
        end
        # set them aside
        state = update_player(state, context.seat, &%Player{ &1 | aside: &1.aside ++ hand_tiles })
        state = Marking.mark_done(state, context.seat)
        state
      "pon_marked_discard" ->
        {discard_tile, discard_seat, discard_index} = Marking.get_marked(marked_objects, :discard) |> Enum.at(0)

        # replace pond tile with blank
        state = update_player(state, discard_seat, &%Player{ &1 | pond: List.replace_at(&1.pond, discard_index, :"2x") })

        # remove tiles from hand
        call_choice = [:"7z", :"7z"]
        state = update_player(state, context.seat, &%Player{ &1 | hand: &1.hand -- call_choice })

        # make call
        call_style = %{kamicha: ["call_sideways", 0, 1], toimen: [0, "call_sideways", 1], shimocha: [0, 1, "call_sideways"]}
        style = call_style[Utils.get_relative_seat(context.seat, discard_seat)]
        call = style_call(style, call_choice, discard_tile)
        call = {"pon", call}
        state = update_player(state, context.seat, &%Player{ &1 | calls: &1.calls ++ [call] })
        state = update_action(state, context.seat, :call,  %{from: discard_seat, called_tile: discard_tile, other_tiles: call_choice, call_name: "pon"})
        state = if Map.has_key?(state.rules, "after_call") do
          run_actions(state, state.rules["after_call"]["actions"], %{seat: context.seat, callee: discard_seat, caller: context.seat, call: call})
        else state end

        state = Marking.mark_done(state, context.seat)
        state
      "draw_marked_aside" ->
        marked_aside = Marking.get_marked(marked_objects, :aside)
        {_, aside_seat, _} = Enum.at(marked_aside, 0)
        {aside_tiles, aside_indices} = marked_aside
        |> Enum.map(fn {tile, _seat, ix} -> {tile, ix} end)
        |> Enum.unzip()

        # remove specified tiles from aside (rightmost first)
        state = for ix <- Enum.sort_by(aside_indices, fn ix -> -ix end), reduce: state do
          state -> update_player(state, aside_seat, &%Player{ &1 | aside: List.delete_at(&1.aside, ix) })
        end

        # draw aside tiles
        state = update_player(state, context.seat, &%Player{ &1 | hand: &1.hand ++ Utils.remove_attr(&1.draw, ["draw"]), draw: &1.draw ++ Utils.add_attr(aside_tiles, ["draw"]) })
        state = Marking.mark_done(state, context.seat)

        # run after_draw actions            
        state = if Map.has_key?(state.rules, "after_draw") do
          run_actions(state, state.rules["after_draw"]["actions"], %{seat: context.seat})
        else state end

        state
      "draw_marked_scry" ->
        {scry_tile, _, scry_index} = Marking.get_marked(marked_objects, :scry) |> Enum.at(0)

        # move marked tile forward in the wall
        wall_before = Enum.take(state.wall, state.wall_index)
        scryed_tiles = state.wall |> Enum.drop(state.wall_index) |> Enum.take(state.players[context.seat].num_scryed_tiles)
        wall_after = Enum.drop(state.wall, state.wall_index + state.players[context.seat].num_scryed_tiles)

        state = Map.put(state, :wall, wall_before ++ [scry_tile] ++ List.delete_at(scryed_tiles, scry_index) ++ wall_after)
        state = update_all_players(state, fn _seat, player -> %Player{ player | num_scryed_tiles: max(0, player.num_scryed_tiles - 1) } end)

        # draw the tile
        state = draw_tile(state, context.seat, 1)
        state = Marking.mark_done(state, context.seat)

        state
      "flip_marked_discard_facedown" ->
        {_discard_tile, discard_seat, discard_index} = Marking.get_marked(marked_objects, :discard) |> Enum.at(0)

        state = update_in(state.players[discard_seat].pond, &List.update_at(&1, discard_index, fn tile -> {:"1x", Utils.tile_to_attrs(tile)} end))

        state = Marking.mark_done(state, context.seat)

        state
      "clear_marking"         -> Marking.mark_done(state, context.seat)
      "set_tile_alias"        ->
        from_tiles = Enum.at(opts, 0, []) |> Enum.flat_map(&translate_tile_alias(state, context, &1))
        to_tiles = Enum.at(opts, 1, []) |> Enum.map(&Utils.to_tile/1)
        set_tile_alias(state, context.seat, from_tiles, to_tiles)
      "set_tile_alias_all"        ->
        from_tiles = Enum.at(opts, 0, []) |> Enum.flat_map(&translate_tile_alias(state, context, &1))
        to_tiles = Enum.at(opts, 1, []) |> Enum.map(&Utils.to_tile/1)
        for seat <- state.available_seats, reduce: state do
          state -> set_tile_alias(state, seat, from_tiles, to_tiles)
        end
      "clear_tile_aliases"    -> update_player(state, context.seat, &%Player{ &1 | tile_aliases: %{}, tile_mappings: %{} })
      "set_tile_ordering"     ->
        tiles = Enum.map(Enum.at(opts, 0, []), &Utils.to_tile/1)
        ordering = Enum.zip(Enum.drop(tiles, -1), Enum.drop(tiles, 1)) |> Map.new()
        ordering_r = Enum.zip(Enum.drop(tiles, 1), Enum.drop(tiles, -1)) |> Map.new()
        state = update_player(state, context.seat, &%Player{ &1 |
          tile_ordering: Map.merge(&1.tile_ordering, ordering),
          tile_ordering_r: Map.merge(&1.tile_ordering_r, ordering_r)
        })
        state
      "set_tile_ordering_all"     ->
        tiles = Enum.map(Enum.at(opts, 0, []), &Utils.to_tile/1)
        ordering = Enum.zip(Enum.drop(tiles, -1), Enum.drop(tiles, 1)) |> Map.new()
        ordering_r = Enum.zip(Enum.drop(tiles, 1), Enum.drop(tiles, -1)) |> Map.new()
        state = update_all_players(state, fn _seat, player -> %Player{ player |
          tile_ordering: Map.merge(player.tile_ordering, ordering),
          tile_ordering_r: Map.merge(player.tile_ordering_r, ordering_r)
        } end)
        state
      "add_attr" ->
        targets = Enum.at(opts, 0, [])
        attrs = Enum.at(opts, 1, [])
        tile_specs = Enum.at(opts, 2, [])
        for target <- targets, reduce: state do
          state ->
            case target do
              "hand" -> update_in(state.players[context.seat].hand, &add_attr_matching(&1, attrs, tile_specs))
              "draw" -> update_in(state.players[context.seat].draw, &add_attr_matching(&1, attrs, tile_specs))
              "aside" -> update_in(state.players[context.seat].aside, &add_attr_matching(&1, attrs, tile_specs))
              "last_discard" -> update_in(state.players[context.seat].pond, fn pond -> Enum.drop(pond, -1) ++ add_attr_matching([Enum.at(pond, -1)], attrs, tile_specs) end)
              _      ->
                IO.inspect("Unhandled add_attr target #{inspect(target)}")
                state
            end
        end
      "add_attr_first_tile"   ->
        tile = Enum.at(opts, 0, :"1x") |> Utils.to_tile()
        attrs = Enum.at(opts, 1, [])
        ix = Enum.find_index(state.players[context.seat].hand ++ state.players[context.seat].draw, fn t -> Utils.same_tile(t, tile) end)
        hand_len = length(state.players[context.seat].hand)
        cond do
          ix == nil -> state
          ix < hand_len ->
            update_player(state, context.seat, &%Player{ &1 | hand: List.update_at(&1.hand, ix, fn t -> Utils.add_attr(t, attrs) end) })
          true ->
            update_player(state, context.seat, &%Player{ &1 | draw: List.update_at(&1.draw, ix - hand_len, fn t -> Utils.add_attr(t, attrs) end) })
        end
      "remove_attr_hand"   ->
        # TODO generalize to remove_attr
        state = update_player(state, context.seat, &%Player{ &1 | hand: Utils.remove_attr(&1.hand, opts) })
        state
      "remove_attr_all"   ->
        # TODO generalize to remove_attr
        state = update_player(state, context.seat, &%Player{ &1 | hand: Utils.remove_attr(&1.hand, opts), draw: Utils.remove_attr(&1.draw, opts), aside: Utils.remove_attr(&1.aside, opts) })
        state
      "tag_drawn_tile"        ->
        tag = Enum.at(opts, 0, "missing_tag")
        state = put_in(state.tags[tag], Enum.at(state.players[context.seat].draw, 0, :"1x"))
        state
      "tag_last_discard"      ->
        tag = Enum.at(opts, 0, "missing_tag")
        state = put_in(state.tags[tag], get_last_discard_action(state).tile)
        state
      "untag"                 ->
        tag = Enum.at(opts, 0, "missing_tag")
        {_, state} = pop_in(state.tags[tag])
        state
      "convert_last_discard"  ->
        last_discarder = get_last_discard_action(state).seat
        tile = Utils.to_tile(Enum.at(opts, 0, "0m"))
        state = update_in(state.players[last_discarder].pond, fn pond -> Enum.drop(pond, -1) ++ [tile] end)
        state = update_action(state, last_discarder, :discard, %{tile: tile})
        state = Buttons.recalculate_buttons(state) # TODO remove
        state
      "flip_draw_faceup" -> update_player(state, context.seat, fn player -> %Player{ player | draw: Enum.map(player.draw, &Riichi.flip_faceup/1) } end)
      "flip_last_discard_faceup"  ->
        last_discarder = get_last_discard_action(state).seat
        tile = Riichi.flip_faceup(get_last_discard_action(state).tile)
        state = update_in(state.players[last_discarder].pond, fn pond -> Enum.drop(pond, -1) ++ [tile] end)
        state = update_action(state, last_discarder, :discard, %{tile: tile})
        state = Buttons.recalculate_buttons(state) # TODO remove
        state
      "flip_all_calls_faceup"  ->
        update_all_players(state, fn _seat, player ->
          faceup_calls = Enum.map(player.calls, fn {call_name, call} -> {call_name, Enum.map(call, fn {tile, sideways} -> {Riichi.flip_faceup(tile), sideways} end)} end)
          %Player{ player | calls: faceup_calls }
        end)
      "flip_first_visible_discard_facedown" -> 
        ix = Enum.find_index(state.players[context.seat].pond, fn tile -> not Utils.same_tile(tile, :"1x") && not Utils.same_tile(tile, :"2x") end)
        if ix != nil do
          update_in(state.players[context.seat].pond, &List.update_at(&1, ix, fn tile -> {:"1x", Utils.tile_to_attrs(tile)} end))
        else state end
      "flip_aside_facedown" -> update_in(state.players[context.seat].aside, &Enum.map(&1, fn tile -> {:"1x", Utils.tile_to_attrs(tile)} end))
      "shuffle_aside"      -> update_in(state.players[context.seat].aside, &Enum.shuffle/1)
      "set_aside_draw"     -> update_player(state, context.seat, &%Player{ &1 | draw: [], aside: &1.aside ++ &1.draw })
      "draw_from_aside"    ->
        state = case state.players[context.seat].aside do
          [] -> state
          [tile | aside] -> update_player(state, context.seat, &%Player{ &1 | draw: &1.draw ++ [Utils.add_attr(tile, ["draw"])], aside: aside })
        end
        state
      "swap_marked_with_aside" ->
        {hand_tile, hand_seat, hand_index} = Marking.get_marked(marked_objects, :hand) |> Enum.at(0)
        [aside_tile | aside] = state.players[hand_seat].aside
        aside = [hand_tile | aside]

        # replace hand tile with aside tile
        hand_length = length(state.players[hand_seat].hand)
        state = if hand_index < hand_length do
          update_player(state, hand_seat, &%Player{ &1 | aside: aside, hand: List.replace_at(&1.hand, hand_index, aside_tile) })
        else
          update_player(state, hand_seat, &%Player{ &1 | aside: aside, draw: List.replace_at(&1.draw, hand_index - hand_length, aside_tile) })
        end
        
        state = update_action(state, context.seat, :swap, %{tile1: {hand_tile, hand_seat, hand_index, :hand}, tile2: {aside_tile, hand_seat, 0, :aside}})
        state = Marking.mark_done(state, context.seat)
        state
      "charleston_left" -> do_charleston(state, :kamicha, context.seat, marked_objects)
      "charleston_across" -> do_charleston(state, :toimen, context.seat, marked_objects)
      "charleston_right" -> do_charleston(state, :shimocha, context.seat, marked_objects)
      "shift_tile_to_dead_wall" -> 
        {wall, tiles} = Enum.split(state.wall, -Enum.at(opts, 0, 1))
        state
        |> Map.put(:wall, wall)
        |> Map.put(:dead_wall, tiles ++ state.dead_wall)
      "resume_deferred_actions" -> resume_deferred_actions(state)
      "cancel_deferred_actions" -> update_all_players(state, fn _seat, player -> %Player{ player | deferred_actions: [], deferred_context: %{} } end)
      "recalculate_buttons" -> Buttons.recalculate_buttons(state, Enum.at(opts, 0, 0))
      "draw_last_discard" ->
        last_discard_action = get_last_discard_action(state)
        if last_discard_action != nil do
          state = update_player(state, context.seat, &%Player{ &1 | draw: &1.draw ++ [Utils.add_attr(last_discard_action.tile, ["draw"])] })
          state = update_in(state.players[last_discard_action.seat].pond, &Enum.drop(&1, -1))
          state
        else state end
      "check_discard_passed" ->
        last_action = get_last_action(state)
        if last_action != nil && last_action.action == :discard && Map.has_key?(state.rules, "after_discard_passed") do
          run_actions(state, state.rules["after_discard_passed"]["actions"], %{seat: context.seat})
        else state end
      "scry"            -> update_player(state, context.seat, &%Player{ &1 | num_scryed_tiles: Enum.at(opts, 0, 1) })
      "scry_all"        ->
        num = Enum.at(opts, 0, 1)
        push_message(state, [
          %{text: "Player #{context.seat} #{state.players[context.seat].nickname} revealed "}
        ] ++ Utils.ph(state.wall |> Enum.drop(state.wall_index) |> Enum.take(num)))
        update_all_players(state, fn _seat, player -> %Player{ player | num_scryed_tiles: num } end)
      "clear_scry"      -> update_all_players(state, fn _seat, player -> %Player{ player | num_scryed_tiles: 0 } end)
      "set_aside_scry"  ->
        tiles = state.wall |> Enum.drop(state.wall_index) |> Enum.take(state.players[context.seat].num_scryed_tiles)
        state = update_player(state, context.seat, &%Player{ &1 | aside: &1.aside ++ tiles })
        state = update_all_players(state, fn _seat, player -> %Player{ player | num_scryed_tiles: 0 } end)
        state = update_in(state.wall_index, & &1 + length(tiles))
        state
      "choose_yaku"     ->
        state = update_player(state, context.seat, &%Player{ &1 | declared_yaku: [] })
        notify_ai_declare_yaku(state, context.seat)
        state
      "disable_saki_card" ->
        targets = Conditions.from_seats_spec(state, context, Enum.at(opts, 0, "self"))
        state = Saki.disable_saki_card(state, targets)
        state
      "enable_saki_card" ->
        targets = Conditions.from_seats_spec(state, context, Enum.at(opts, 0, "self"))
        state = Saki.enable_saki_card(state, targets)
        state
      "save_revealed_tiles" -> put_in(state.saved_revealed_tiles, state.revealed_tiles)
      "load_revealed_tiles" -> put_in(state.revealed_tiles, state.saved_revealed_tiles)
      "merge_draw"          -> update_player(state, context.seat, &%Player{ &1 | hand: &1.hand ++ Utils.remove_attr(&1.draw, ["draw"]), draw: [] })
      "delete_tiles"    ->
        # TODO allow specifying target
        tiles = Enum.map(opts, &Utils.to_tile/1)
        state = update_player(state, context.seat, &%Player{ &1 | hand: Enum.reject(&1.hand, fn t -> Utils.count_tiles([t], tiles) > 0 end), draw: Enum.reject(&1.draw, fn t -> Utils.count_tiles([t], tiles) > 0 end) })
        state
      "pass_draws"      ->
        to = Conditions.from_seat_spec(state, context, Enum.at(opts, 0, "self"))
        {to_pass, remaining} = Enum.split(state.players[context.seat].draw, Enum.at(opts, 1, 1))
        state = update_player(state, context.seat, &%Player{ &1 | draw: remaining })
        state = update_player(state, to, &%Player{ &1 | draw: &1.draw ++ to_pass })
        state
      "saki_start"      -> Saki.saki_start(state)
      "swap_hand_and_aside" -> update_player(state, context.seat, &%Player{ &1 | hand: &1.aside, aside: &1.hand })
      _                 ->
        IO.puts("Unhandled action #{action}")
        state
    end

    case action do
      "pause" when not state.log_loading_mode ->
        # schedule an unpause after the given delay
        state = schedule_actions_before(state, context.seat, actions, context)
        :timer.apply_after(Enum.at(opts, 0, 1500), GenServer, :cast, [self(), {:unpause, context}])
        if Debug.debug_actions() do
          IO.puts("Stopping actions due to pause: #{inspect([[action | opts] | actions])}")
        end
        {state, []}
      _ ->
        # if our action updates state, then we need to recalculate buttons
        # this is so other players can react to certain actions
        if not uninterruptible && Map.has_key?(state.interruptible_actions, action) do
          state = if state.visible_screen != nil do
            # if viewing a win screen, never display buttons
            update_all_players(state, fn _seat, player -> %Player{ player | buttons: [], button_choices: %{}, call_buttons: %{}, call_name: "", chosen_call_choice: nil, chosen_called_tile: nil, chosen_saki_card: nil } end)
          else
            Buttons.recalculate_buttons(state, state.interruptible_actions[action])
          end
          buttons_after = Enum.map(state.players, fn {seat, player} -> {seat, player.buttons} end)
          # IO.puts("buttons_before: #{inspect(buttons_before)}")
          # IO.puts("buttons_after: #{inspect(buttons_after)}")
          if buttons_before == buttons_after || Buttons.no_buttons_remaining?(state) do
            _run_actions(state, actions, context)
          else
            # if buttons changed, stop evaluating actions here
            if Debug.debug_actions() do
              IO.puts("Stopping actions due to buttons: #{inspect(buttons_after)} actions are: #{inspect([[action | opts] | actions])}")
            end
            {state, actions}
          end
        else
          _run_actions(state, actions, context)
        end
    end
  end
  defp _run_actions(state, [action | actions], context) do
    IO.puts("Unhandled action spec #{action}")
    _run_actions(state, actions, context)
  end

  def run_actions(state, actions, context) do
    if Debug.debug_actions() do
      if (Enum.empty?(actions) || (actions |> Enum.at(0) |> Enum.at(0)) not in ["when", "sort_hand", "unset_status"]) do
        IO.puts("Running actions #{inspect(actions)} in context #{inspect(context)}")
      end
    end
    # IO.puts("Running actions #{inspect(actions)} in context #{inspect(context)}")
    # IO.inspect(Process.info(self(), :current_stacktrace))
    {state, deferred_actions} = _run_actions(state, actions, context)
    # defer the remaining actions
    state = if not Enum.empty?(deferred_actions) do
      if Debug.debug_actions() do
        IO.puts("Deferred actions for seat #{context.seat} due to pause or existing buttons / #{inspect(deferred_actions)}")
      end
      state = schedule_actions(state, context.seat, deferred_actions, context)
      state
    else state end
    state
  end

  def schedule_actions_before(state, seat, actions, context) do
    update_player(state, seat, &%Player{ &1 | deferred_actions: actions ++ &1.deferred_actions, deferred_context: Map.merge(&1.deferred_context, context) })
  end

  def schedule_actions(state, seat, actions, context) do
    update_player(state, seat, &%Player{ &1 | deferred_actions: &1.deferred_actions ++ actions, deferred_context: Map.merge(&1.deferred_context, context) })
  end

  def run_deferred_actions(state, context) do
    actions = state.players[context.seat].deferred_actions
    if state.game_active && not Enum.empty?(actions) do
      state = update_player(state, context.seat, &%Player{ &1 | choice: nil, chosen_actions: nil, deferred_actions: [], deferred_context: %{} })
      if Debug.debug_actions() do
        IO.puts("Running deferred actions #{inspect(actions)} in context #{inspect(context)}")
      end
      state = run_actions(state, actions, context)
      state = Buttons.recalculate_buttons(state)
      notify_ai(state)
      state
    else state end
  end

  def resume_deferred_actions(state) do
    for {seat, player} <- state.players, reduce: state do
      state ->
        state = if not Enum.empty?(player.deferred_actions) do
          if Debug.debug_actions() do
            IO.puts("Resuming deferred actions for #{seat}")
          end
          run_deferred_actions(state, player.deferred_context)
        else state end
        state = if not Enum.empty?(state.marking[seat]) && Marking.is_done?(state, seat) do
          state = Log.log(state, seat, :mark, %{marking: Log.encode_marking(state.marking[seat])})
          Marking.reset_marking(state, seat)
        else state end
        state
    end |> evaluate_choices(true)
  end

  def get_superceded_buttons(state, button_name) do
    if Map.has_key?(state.rules["buttons"], button_name) do
      ["play_tile"] ++ Map.get(state.rules["buttons"][button_name], "precedence_over", [])
    else [] end
  end

  def get_all_superceded_buttons(state, seat) do
    Enum.flat_map(state.players, fn {dir, player} -> if dir != seat do ["skip"] ++ get_superceded_buttons(state, player.choice) else [] end end)
  end

  defp adjudicate_actions(state) do
    if state.game_active do
      lock = Mutex.await(state.mutex, __MODULE__)
      if Debug.debug_actions() do
        IO.puts("\nAdjudicating actions!")
      end
      # clear ai thinking
      state = update_all_players(state, fn _seat, player -> %Player{ player | ai_thinking: false } end)
      # clear last discard
      state = update_all_players(state, fn _seat, player -> %Player{ player | last_discard: nil } end)
      # trigger all non-nil choices
      state = for {seat, player} <- state.players, reduce: state do
        state ->
          choice = player.choice
          actions = player.chosen_actions
          button_choices = player.button_choices
          # don't clear deferred actions here
          # for example, someone might play a tile and have advance_turn interrupted by their own button
          # if they choose to skip, we still want to advance turn
          # also don't clear buttons here!! buttons are only cleared by player and in evaluate_choices
          state = update_player(state, seat, fn player -> %Player{ player | choice: nil, chosen_actions: nil } end)
          state = if choice != nil do
            button_choice = if button_choices != nil do
              Map.get(button_choices, choice, nil)
            else nil end
            case button_choice do
              {:call, _call_choices} ->
                # to have submitted a call action with call choices,
                # we must have a chosen_called_tile and chosen_call_choice available
                context = if player.chosen_saki_card != nil do
                  %{seat: seat, call_name: choice, choice: player.chosen_saki_card}
                else
                  %{seat: seat, call_name: choice, called_tile: player.chosen_called_tile, call_choice: player.chosen_call_choice}
                end
                if Debug.debug_actions() do
                  IO.puts("Running call actions for #{seat}: #{inspect(actions)}")
                end
                state = run_actions(state, actions, context)
                state
              {:mark, mark_spec, pre_actions, post_actions} ->
                # run pre-mark actions
                if Debug.debug_actions() do
                  IO.puts("Running pre-mark actions for #{seat}: #{inspect(pre_actions)}")
                end
                state = run_actions(state, pre_actions, %{seat: seat})
                # setup marking
                cancellable = Map.get(state.rules["buttons"][choice], "cancellable", true)
                state = Marking.setup_marking(state, seat, mark_spec, cancellable, post_actions)
                if Debug.debug_actions() do
                  IO.puts("Scheduling mark actions for #{seat}: #{inspect(actions)}")
                end
                state = schedule_actions(state, seat, actions, %{seat: seat})
                notify_ai_marking(state, seat)
                state
              nil ->
                # just run all button actions as normal
                if Debug.debug_actions() do
                  IO.puts("Running actions for #{seat}: #{inspect(actions)}")
                end
                state = run_actions(state, actions, %{seat: seat})
                state
            end
          else state end
          state
      end
      # done with all choices
      state = if not performing_intermediate_action?(state) do
        state = if Buttons.no_buttons_remaining?(state) do
          Buttons.recalculate_buttons(state, 0)
        else state end
        notify_ai(state)
        state
      else state end
      # clearing choices is done by evaluate_choices now
      # though i guess we could still do it here? no difference
      # state = update_all_players(state, fn _seat, player -> %Player{ player | choice: nil, chosen_actions: nil } end)

      Mutex.release(state.mutex, lock)
      # IO.puts("Done adjudicating actions!\n")
      state
    else state end
  end

  def performing_intermediate_action?(state) do
    Enum.any?(state.available_seats, fn seat -> performing_intermediate_action?(state, seat) end)
  end

  def performing_intermediate_action?(state, seat) do
    no_call_buttons = Enum.empty?(state.players[seat].call_buttons)
    made_choice = state.players[seat].choice != nil && state.players[seat].choice != "skip"
    marking = Marking.needs_marking?(state, seat)
    not no_call_buttons || made_choice || marking
  end

  def evaluate_choices(state, from_deferred_actions \\ false) do
    # for the current turn's player, if they just acted (have deferred actions) and have no buttons, their choice is "skip"
    # for other players who have no buttons and have not made a choice yet, their choice is "skip"
    # also for other players who have made a choice, if their choice is superceded by others then set it to "skip"
    last_action = get_last_action(state)
    turn_just_acted = last_action != nil && not Enum.empty?(state.players[state.turn].deferred_actions) && last_action.seat == state.turn
    last_discard_action = get_last_discard_action(state)
    turn_just_discarded = last_discard_action != nil && last_discard_action.seat == state.turn
    extra_turn = "extra_turn" in state.players[state.turn].status
    state = for {seat, player} <- state.players, reduce: state do
      state -> cond do
        seat == state.turn && (turn_just_acted || (turn_just_discarded && not extra_turn)) && Enum.empty?(player.buttons) && not performing_intermediate_action?(state, seat) ->
          # IO.puts("Player #{seat} must skip due to having just discarded")
          update_player(state, seat, &%Player{ &1 | choice: "skip", chosen_actions: [] })
        seat != state.turn && player.choice == nil && Enum.empty?(player.buttons) && not performing_intermediate_action?(state, seat) ->
          # IO.puts("Player #{seat} must skip due to having no buttons")
          update_player(state, seat, &%Player{ &1 | choice: "skip", chosen_actions: [] })
        seat != state.turn && player.choice != nil && player.choice in get_all_superceded_buttons(state, seat) && player.choice not in get_superceded_buttons(state, player.choice) ->
          # IO.puts("Player #{seat} must skip due to having buttons superceded")
          update_player(state, seat, &%Player{ &1 | choice: "skip", chosen_actions: [] })
        true -> state
      end
    end

    # supercede choices
    # basically, starting from the current turn player's choice, clear out others' choices
    ordered_seats = [state.turn, Utils.next_turn(state.turn), Utils.next_turn(state.turn, 2), Utils.next_turn(state.turn, 3)]
    |> Enum.filter(fn seat -> seat in state.available_seats end)
    state = for seat <- ordered_seats, reduce: state do
      state ->
        choice = state.players[seat].choice
        if choice not in [nil, "skip", "play_tile"] do
          superceded_choices = ["skip", "play_tile"] ++ if Map.has_key?(state.rules["buttons"], choice) do
            Map.get(state.rules["buttons"][choice], "precedence_over", [])
          else [] end
          # replace with "skip" every choice that is superceded by our choice

          update_all_players(state, fn dir, player ->
            not_us = seat != dir
            choice_superceded = player.choice in superceded_choices
            all_choices_superceded = player.choice == nil && Enum.all?(player.buttons, fn button -> button in superceded_choices end)
            if not_us && (choice_superceded || all_choices_superceded) do
              %Player{ player | choice: "skip", chosen_actions: [], buttons: [] }
            else player end
          end)
        else state end
    end

    # check call priority lists
    # if multiple people have the same call, normally it will just trigger both calls
    # define a "call_priority_list" key in your button to prevent this
    # each item should be a CNF condition
    # calls that satisfy the first condition are given priority over calls that don't
    # calls that satisfy the second condition are given priority over calls that don't
    # etc. if there are still multiple of the same call then it reverts to "first in turn order"
    conflicting_players = ordered_seats
    |> Enum.map(fn seat -> {seat, state.players[seat].choice} end)
    |> Enum.filter(fn {_seat, choice} -> get_in(state.rules["buttons"], [choice, "call_priority_list"]) != nil end)
    |> Enum.map(fn {seat, choice} -> %{choice => [seat]} end)
    |> Enum.reduce(%{}, fn m, acc -> Map.merge(m, acc, fn _k, l, r -> l ++ r end) end)
    state = for {choice, seats} <- conflicting_players, reduce: state do
      state ->
        priority_list = state.rules["buttons"][choice]["call_priority_list"]
        winning_seat = seats
        |> Enum.sort_by(fn seat ->
          context = %{seat: seat, call_name: choice, called_tile: state.players[seat].chosen_called_tile, call_choice: state.players[seat].chosen_call_choice}
          ix = Enum.find_index(priority_list, fn conditions -> Conditions.check_cnf_condition(state, conditions, context) end)
          if ix == nil do :infinity else ix end
        end)
        |> Enum.at(0)
        update_all_players(state, fn dir, player ->
          if dir in (seats -- [winning_seat]) do
            %Player{ player | choice: "skip", chosen_actions: [], buttons: [] }
          else player end
        end)
    end

    # check if nobody else needs to make choices
    if Enum.all?(state.players, fn {_seat, player} -> player.choice != nil end) do
      # if every action is skip, we need to resume deferred actions for all players
      # otherwise, adjudicate actions as normal
      if Enum.all?(state.players, fn {_seat, player} -> player.choice == "skip" end) do
        if state.game_active && not from_deferred_actions do
          # IO.puts("All choices are no-ops, running deferred actions")
          state = resume_deferred_actions(state)
          state = update_all_players(state, fn _seat, player -> %Player{ player | choice: nil, chosen_actions: nil } end)
          state
        else state end
      else
        adjudicate_actions(state)
      end
    else
      # when we interrupt the current turn AI with our button choice, they fail to make a choice
      # this rectifies that
      notify_ai(state)
      state
    end
  end

  def submit_actions(state, seat, choice, actions, call_choice \\ nil, called_tile \\ nil, saki_card \\ nil) do
    player = state.players[seat]
    if state.game_active && player.choice == nil do
      if Debug.debug_actions() do
        IO.puts("Submitting choice for #{seat}: #{choice}, #{inspect(actions)}")
        # IO.puts("Deferred actions for #{seat}: #{inspect(state.players[seat].deferred_actions)}")
      end

      {called_tile, call_choice, call_choices} = if called_tile == nil && call_choice == nil && player.button_choices != nil do
        button_choice = Map.get(player.button_choices, choice, nil)
        case button_choice do
          {:call, call_choices} ->
            flattened_call_choices = call_choices |> Map.values() |> Enum.concat()
            if length(flattened_call_choices) == 1 do
              # if there's only one choice, automatically choose it
              {called_tile, [call_choice]} = Enum.max_by(call_choices, fn {_tile, choices} -> length(choices) end)
              if Debug.debug_actions() do
                IO.puts("Submitting actions due to there being only one call choice for #{seat}: #{inspect(actions)}")
              end
              {called_tile, call_choice, call_choices}
            else {nil, nil, call_choices} end
          _ -> {nil, nil, nil}
        end
      else {called_tile, call_choice, nil} end

      if called_tile == nil && call_choice == nil && saki_card == nil && call_choices != nil do
        # show call choice buttons
        # clicking them will call submit_actions again, but with the optional parameters included
        if Debug.debug_actions() do
          IO.puts("Showing call buttons for #{seat}: #{inspect(actions)}")
        end
        state = update_player(state, seat, fn player -> %Player{ player | call_buttons: call_choices, call_name: choice } end)
        notify_ai_call_buttons(state, seat)
        state
      else
        # log the button press
        state = case choice do
          "skip" -> state
          "play_tile" -> state
          _ ->
            data = cond do
              saki_card != nil -> %{choice: saki_card}
              call_choice != nil -> %{call_choice: call_choice, called_tile: called_tile}
              true -> %{}
            end
            Log.add_button_press(state, seat, choice, data)
        end
        state = update_player(state, seat, &%Player{ &1 | choice: choice, chosen_actions: actions, chosen_called_tile: called_tile, chosen_call_choice: call_choice, chosen_saki_card: saki_card })
        state = if choice != "skip" do update_player(state, seat, &%Player{ &1 | deferred_actions: [] }) else state end
        evaluate_choices(state)
      end
    else state end
  end

  def extract_actions([], _names), do: []
  def extract_actions([action | actions], names) do
    case action do
      ["when", _condition, subactions] -> extract_actions(subactions, names)
      ["as", _seats_spec, subactions] -> extract_actions(subactions, names)
      ["when_anyone", _condition, subactions] -> extract_actions(subactions, names)
      ["when_everyone", _condition, subactions] -> extract_actions(subactions, names)
      ["when_others", _condition, subactions] -> extract_actions(subactions, names)
      ["unless", _condition, subactions] -> extract_actions(subactions, names)
      ["ite", _condition, subactions1, subactions2] -> extract_actions(subactions1, names) ++ extract_actions(subactions2, names)
      [action_name | _opts] -> if action_name in names do [action] else [] end
    end ++ extract_actions(actions, names)
  end

  def map_action_opts([], _fun), do: []
  def map_action_opts([action | actions], fun) do
    mapped_action = case action do
      ["when", condition, subactions] -> ["when", condition, map_action_opts(subactions, fun)]
      ["as", seats_spec, subactions] -> ["as", seats_spec, map_action_opts(subactions, fun)]
      ["when_anyone", condition, subactions] -> ["when_anyone", condition, map_action_opts(subactions, fun)]
      ["when_everyone", condition, subactions] -> ["when_everyone", condition, map_action_opts(subactions, fun)]
      ["when_others", condition, subactions] -> ["when_others", condition, map_action_opts(subactions, fun)]
      ["unless", condition, subactions] -> ["unless", condition, map_action_opts(subactions, fun)]
      ["ite", condition, subactions1, subactions2] -> ["ite", condition, map_action_opts(subactions1, fun), map_action_opts(subactions2, fun)]
      ["run", fn_name, args] -> ["run", fn_name, Map.new(args, fn {name, value} -> {name, fun.(value)} end)]
      _ -> Enum.map(action, fun)
    end
    [mapped_action | map_action_opts(actions, fun)]
  end

end
