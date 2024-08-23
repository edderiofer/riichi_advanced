
defmodule RiichiAdvanced.GameState.Actions do
  alias RiichiAdvanced.GameState.Buttons, as: Buttons
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

  def play_tile(state, seat, tile, index) do
    tile_source = if index < length(state.players[seat].hand) do :hand else :draw end
    if is_playable?(state, seat, tile, tile_source) do
      # IO.puts("#{seat} played tile: #{inspect(tile)} at index #{index}")
      state = update_player(state, seat, &%Player{ &1 |
        hand: List.delete_at(&1.hand ++ &1.draw, index),
        pond: &1.pond ++ [tile],
        discards: &1.discards ++ [tile],
        draw: [],
        last_discard: {tile, index}
      })
      state = update_action(state, seat, :discard, %{tile: tile})

      # trigger play effects
      if Map.has_key?(state.rules, "play_effects") do
        for [tile_spec, actions] <- state.rules["play_effects"], Riichi.tile_matches([tile_spec], %{tile: tile}), reduce: state do
          state -> run_actions(state, actions, %{seat: seat})
        end
      else state end
    else state end
  end

  def draw_tile(state, seat, num, tile_spec) do
    if num > 0 do
      {tile_name, wall_index} = if tile_spec != nil do {tile_spec, state.wall_index} else {Enum.at(state.wall, state.wall_index), state.wall_index + 1} end
      if tile_name == nil do
        IO.puts("Tried to draw a nil tile!")
        state
      else
        state = if is_binary(tile_name) && Map.has_key?(state.reserved_tiles, tile_name) do
            Map.update!(state, :drawn_reserved_tiles, fn tiles -> [tile_name | tiles] end)
          else state end
        tile = from_tile_name(state, tile_name)
        state = update_player(state, seat, &%Player{ &1 |
          hand: &1.hand ++ &1.draw,
          draw: [tile]
        })
        state = Map.put(state, :wall_index, wall_index)
        state = update_action(state, seat, :draw, %{tile: tile})

        # IO.puts("wall index is now #{get_state().wall_index}")
        draw_tile(state, seat, num - 1, tile_spec)
      end
    else state end
  end

  def run_on_no_valid_tiles(state, seat, gas \\ 100) do
    if gas > 0 do
      if not Enum.any?(state.players[seat].hand, fn tile -> is_playable?(state, seat, tile, :hand) end) &&
         not Enum.any?(state.players[seat].draw, fn tile -> is_playable?(state, seat, tile, :draw) end) do
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

      state
    else state end
  end

  def advance_turn(state) do
    # this action is called after playing a tile
    # it should trigger on_turn_change, so don't mark the turn change as via_action
    change_turn(state, if state.reversed_turn_order do Utils.prev_turn(state.turn) else Utils.next_turn(state.turn) end)
  end

  def trigger_call(state, seat, call_name, call_choice, called_tile, call_source) do
    call_style = if Map.has_key?(state.rules["buttons"][call_name], "call_style") do
        state.rules["buttons"][call_name]["call_style"]
      else Map.new(["self", "kamicha", "toimen", "shimocha"], fn dir -> {dir, 0..length(call_choice)} end) end

    # style the call
    # tiles = Enum.map(call_choice, fn t -> {t, false} end)
    call = if called_tile != nil do
      style = call_style[Atom.to_string(Utils.get_relative_seat(seat, state.turn))]
      tiles = if "call" in style or "call_sideways" in style do call_choice else call_choice ++ [called_tile] end
      tiles = Utils.sort_tiles(tiles)
      for style_spec <- style, reduce: [] do
        acc ->
          tile = case style_spec do
            "call"                 -> {called_tile, false}
            "call_sideways"        -> {called_tile, true}
            ix when is_integer(ix) -> {Enum.at(tiles, ix), false}
            tile                   -> {Utils.to_tile(tile), false}
          end
          [tile | acc]
      end |> Enum.reverse()
    else
      Enum.map(call_choice, fn tile -> {tile, false} end)
    end
    call = {call_name, call}
    state = if Map.has_key?(state.rules, "before_call") do
      run_actions(state, state.rules["before_call"]["actions"], %{seat: state.turn, callee: state.turn, caller: seat, call: call})
    else state end
    state = case call_source do
      :discards -> update_player(state, state.turn, &%Player{ &1 | pond: Enum.drop(&1.pond, -1) })
      :hand     -> update_player(state, seat, &%Player{ &1 | hand: (&1.hand ++ &1.draw) -- [called_tile], draw: [] })
      _         -> IO.puts("Unhandled call_source #{inspect(call_source)}")
    end
    state = update_player(state, seat, &%Player{ &1 | hand: &1.hand -- call_choice, calls: &1.calls ++ [call] })
    state = update_action(state, seat, :call,  %{from: state.turn, called_tile: called_tile, other_tiles: call_choice, call_name: call_name})
    state = update_player(state, seat, &%Player{ &1 | call_buttons: %{}, call_name: "" })
    state = if Map.has_key?(state.rules, "after_call") do
      run_actions(state, state.rules["after_call"]["actions"], %{seat: seat, callee: state.turn, caller: seat, call: call})
    else state end
    state
  end

  def upgrade_call(state, seat, call_name, call_choice, called_tile) do
    # find the index of the call whose tiles match call_choice
    index = state.players[seat].calls
      |> Enum.map(fn {_name, call} -> Enum.map(call, fn {tile, _sideways} -> tile end) end)
      |> Enum.find_index(fn call_tiles -> Enum.sort(call_tiles) == Enum.sort(call_choice) end)
    # upgrade that call
    {_name, call} = Enum.at(state.players[seat].calls, index)

    # find the index of the sideways tile
    sideways_index = Enum.find_index(call, fn {_tile, sideways} -> sideways end)
    sideways_index = if sideways_index == nil do -1 else sideways_index end
    upgraded_call = {call_name, List.insert_at(call, sideways_index, {called_tile, true})}
    state = update_player(state, seat, &%Player{ &1 | hand: (&1.hand ++ &1.draw) -- [called_tile], draw: [], calls: List.replace_at(state.players[seat].calls, index, upgraded_call) })
    state = update_action(state, seat, :call,  %{from: state.turn, called_tile: called_tile, other_tiles: call_choice, call_name: call_name})
    state = update_player(state, seat, &%Player{ &1 | call_buttons: %{}, call_name: "" })
    state
  end

  defp _run_actions(state, [], _context), do: {state, []}
  defp _run_actions(state, [[action | opts] | actions], context) do
    buttons_before = Enum.map(state.players, fn {seat, player} -> {seat, player.buttons} end)
    state = case action do
      "play_tile"             -> play_tile(state, context.seat, Enum.at(opts, 0, :"1m"), Enum.at(opts, 1, 0))
      "draw"                  -> draw_tile(state, context.seat, Enum.at(opts, 0, 1), Enum.at(opts, 1, nil))
      "reverse_turn_order"    -> Map.update!(state, :reversed_turn_order, &not &1)
      "call"                  -> trigger_call(state, context.seat, context.call_name, context.call_choice, context.called_tile, :discards)
      "self_call"             -> trigger_call(state, context.seat, context.call_name, context.call_choice, context.called_tile, :hand)
      "upgrade_call"          -> upgrade_call(state, context.seat, context.call_name, context.call_choice, context.called_tile)
      "flower"                -> trigger_call(state, context.seat, context.call_name, context.call_choice, nil, :hand)
      "advance_turn"          -> advance_turn(state)
      "change_turn"           -> change_turn(state, Utils.get_seat(context.seat, String.to_atom(Enum.at(opts, 0, "self"))), true)
      "win_by_discard"        -> win(state, context.seat, get_last_discard_action(state).tile, :discard)
      "win_by_call"           -> win(state, context.seat, get_last_action(state).called_tile, :call)
      "win_by_draw"           -> win(state, context.seat, Enum.at(state.players[context.seat].draw, 0), :draw)
      "set_status"            -> update_player(state, context.seat, fn player -> %Player{ player | status: Enum.uniq(player.status ++ opts) } end)
      "unset_status"          -> update_player(state, context.seat, fn player -> %Player{ player | status: Enum.uniq(player.status -- opts) } end)
      "set_status_all"        -> update_all_players(state, fn _seat, player -> %Player{ player | status: Enum.uniq(player.status ++ opts) } end)
      "unset_status_all"      -> update_all_players(state, fn _seat, player -> %Player{ player | status: Enum.uniq(player.status -- opts) } end)
      "set_callee_status"     -> update_player(state, context.callee, fn player -> %Player{ player | status: Enum.uniq(player.status ++ opts) } end)
      "unset_callee_status"   -> update_player(state, context.callee, fn player -> %Player{ player | status: Enum.uniq(player.status -- opts) } end)
      "set_caller_status"     -> update_player(state, context.caller, fn player -> %Player{ player | status: Enum.uniq(player.status ++ opts) } end)
      "unset_caller_status"   -> update_player(state, context.caller, fn player -> %Player{ player | status: Enum.uniq(player.status -- opts) } end)
      "big_text"              ->
        seat = case Enum.at(opts, 1) do
          "shimocha" -> Utils.get_seat(context.seat, :shimocha)
          "toimen" -> Utils.get_seat(context.seat, :toimen)
          "kamicha" -> Utils.get_seat(context.seat, :kamicha)
          _ -> context.seat
        end
        temp_display_big_text(state, seat, Enum.at(opts, 0, ""))
      "pause"                 -> Map.put(state, :game_active, false)
      "sort_hand"             -> update_player(state, context.seat, fn player -> %Player{ player | hand: Utils.sort_tiles(player.hand) } end)
      "reveal_tile"           -> Map.update!(state, :revealed_tiles, fn tiles -> tiles ++ [Enum.at(opts, 0, :"1m")] end)
      "add_score"             ->
        recipients = case Enum.at(opts, 1) do
          "shimocha" -> [Utils.get_seat(context.seat, :shimocha)]
          "toimen" -> [Utils.get_seat(context.seat, :toimen)]
          "kamicha" -> [Utils.get_seat(context.seat, :kamicha)]
          "last_discarder" -> [get_last_discard_action(state).seat]
          "all" -> [:east, :south, :west, :north]
          "others" -> [:east, :south, :west, :north] -- [context.seat]
          _ -> [context.seat]
        end
        for recipient <- recipients, reduce: state do
          state -> update_player(state, recipient, fn player -> %Player{ player | score: player.score + Enum.at(opts, 0, 0) } end)
        end
      "put_down_riichi_stick" -> state |> Map.update!(:riichi_sticks, & &1 + 1) |> update_player(context.seat, &%Player{ &1 | riichi_stick: true })
      "reveal_hand"           -> update_player(state, context.seat, fn player -> %Player{ player | hand_revealed: true } end)
      "ryuukyoku"             -> exhaustive_draw(state)
      "discard_draw"          ->
        # need to do this or else we might reenter adjudicate_actions
        :timer.apply_after(100, GenServer, :cast, [self(), {:play_tile, context.seat, length(state.players[context.seat].hand)}])
        state
      "press_button"          ->
        # need to do this or else we might reenter adjudicate_actions
        :timer.apply_after(100, GenServer, :cast, [self(), {:press_button, context.seat, Enum.at(opts, 0, "skip")}])
        state
      "when"                  -> if check_cnf_condition(state, Enum.at(opts, 0, []), context) do run_actions(state, Enum.at(opts, 1, []), context) else state end
      "when_anyone"           ->
        for dir <- [:east, :south, :west, :north], check_cnf_condition(state, Enum.at(opts, 0, []), %{seat: dir}), reduce: state do
          state -> run_actions(state, Enum.at(opts, 1, []), %{seat: dir})
        end
      _                       ->
        IO.puts("Unhandled action #{action}")
        state
    end

    if action == "pause" do
      # schedule an unpause after the given delay
      :timer.apply_after(Enum.at(opts, 0, 1500), GenServer, :cast, [self(), {:unpause, actions, context}])
      # IO.puts("Stopping actions due to pause: #{inspect(actions)}")
      {state, []}
    else
      # if our action updates state, then we need to recalculate buttons
      # this is so other players can react to certain actions
      if Map.has_key?(state.rules, "interruptible_actions") && action in state.rules["interruptible_actions"] do
        state = if not Enum.empty?(state.winners) do
          # if there's a winner, never display buttons
          update_all_players(state, fn _seat, player -> %Player{ player | buttons: [] } end)
        else
          Buttons.recalculate_buttons(state)
        end
        buttons_after = Enum.map(state.players, fn {seat, player} -> {seat, player.buttons} end)
        # IO.puts("buttons_before: #{inspect(buttons_before)}")
        # IO.puts("buttons_after: #{inspect(buttons_after)}")
        if buttons_before == buttons_after || Buttons.no_buttons_remaining?(state) do
          _run_actions(state, actions, context)
        else
          # if buttons changed, stop evaluating actions here
          # IO.puts("Stopping actions due to buttons: #{inspect(buttons_after)}")
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
    state = Map.update!(state, :actions_cv, & &1 + 1)
    # if Enum.empty?(actions) || (actions |> Enum.at(0) |> Enum.at(0)) not in ["when", "sort_hand", "unset_status"] do
    #   IO.puts("Running actions #{inspect(actions)} in context #{inspect(context)}; cv = #{state.actions_cv}")
    # end
    # IO.puts("Running actions #{inspect(actions)} in context #{inspect(context)}; cv = #{state.actions_cv}")
    # IO.inspect(Process.info(self(), :current_stacktrace))
    {state, deferred_actions} = _run_actions(state, actions, context)
    # defer the remaining actions
    state = if not Enum.empty?(deferred_actions) do
      # IO.puts("Deferred actions for seat #{context.seat} due to pause or existing buttons / #{inspect(deferred_actions)}")
      state = schedule_actions(state, context.seat, deferred_actions)
      state
    else state end
    state = Map.update!(state, :actions_cv, & &1 - 1)
    state = if state.actions_cv == 0 do
      # notify_ai(state)
      # make our next decision for us (unless these actions were caused by auto buttons)
      state = if not Map.has_key?(context, :auto) || not context.auto do
        # IO.puts("Triggering auto buttons")
        state = Buttons.trigger_auto_buttons(state)
        state
      else state end
      state
    else state end
    state
  end

  def run_deferred_actions(state, context) do
    actions = state.players[context.seat].deferred_actions
    if state.game_active && not Enum.empty?(actions) do
      state = update_player(state, context.seat, &%Player{ &1 | deferred_actions: [] })
      # IO.puts("Running deferred actions #{inspect(actions)} in context #{inspect(context)}")
      state = run_actions(state, actions, context)
      state
    else state end
  end

  def schedule_actions(state, seat, actions) do
    update_player(state, seat, &%Player{ &1 | deferred_actions: &1.deferred_actions ++ actions })
  end

  # return all choices that have no effect due to other players' choices
  def get_superceded_choices(state) do
    Enum.flat_map(state.players, fn {_seat, player} -> 
      if player.choice != nil && player.choice != "skip" && player.choice != "play_tile" do
        if Map.has_key?(state.rules["buttons"], player.choice) && Map.has_key?(state.rules["buttons"][player.choice], "precedence_over") do
          ["skip", "play_tile"] ++ state.rules["buttons"][player.choice]["precedence_over"]
        else
          ["skip", "play_tile"]
        end
      else
        ["skip"]
      end
    end)
  end

  defp adjudicate_actions(state) do
    if state.game_active do
      lock = Mutex.await(state.mutex, __MODULE__)
      # IO.puts("\nAdjudicating actions!")
      # clear last discard
      state = update_all_players(state, fn _seat, player -> %Player{ player | last_discard: nil } end)
      superceded_choices = get_superceded_choices(state)
      state = for {seat, player} <- state.players, reduce: state do
        state ->
          # only trigger choices that aren't superceded
          choice = player.choice
          actions = player.chosen_actions
          state = update_player(state, seat, fn player -> %Player{ player | choice: nil, chosen_actions: nil, deferred_actions: [] } end)
          state = if choice != nil && not Enum.member?(superceded_choices, choice) do
            # IO.puts("It's #{state.turn}'s turn, player #{seat} (choice: #{choice}) gets to run actions #{inspect(actions)}")
            # check if a call action exists, if it's a call and multiple call choices are available
            call_action_exists = Enum.any?(actions, fn [action | _opts] -> action in ["call", "self_call", "upgrade_call", "flower"] end)
            if not call_action_exists do
              # just run all button actions as normal
              state = run_actions(state, actions, %{seat: seat})
              state
            else
              # call button choices logic
              button_name = choice
              # if there is a call action, check if there are multiple call choices
              is_call = Enum.any?(actions, fn [action | _opts] -> action == "call" end)
              is_upgrade = Enum.any?(actions, fn [action | _opts] -> action == "upgrade_call" end)
              is_flower = Enum.any?(actions, fn [action | _opts] -> action == "flower" end)
              call_choices = cond do
                is_upgrade ->
                  state.players[seat].calls
                    |> Enum.filter(fn {name, _call} -> name == state.rules["buttons"][button_name]["upgrades"] end)
                    |> Enum.map(fn {_name, call} -> Enum.map(call, fn {tile, _sideways} -> tile end) end)
                    |> Enum.map(fn call_tiles ->
                       Riichi.make_calls(state.rules["buttons"][button_name]["call"], call_tiles, state.players[seat].hand ++ state.players[seat].draw)
                    end)
                    |> Enum.reduce(%{}, fn call_choices, acc -> Map.merge(call_choices, acc, fn _k, l, r -> l ++ r end) end)
                is_flower ->
                  flowers = Enum.flat_map(actions, fn [action | opts] -> if action == "flower" do opts else [] end end) |> Enum.map(&Utils.to_tile/1)
                  flowers_in_hand = Enum.filter(state.players[seat].hand ++ state.players[seat].draw, fn tile -> tile in flowers end)
                  %{nil => Enum.map(flowers_in_hand, fn tile -> [tile] end)}
                true ->
                  callable_tiles = if is_call do Enum.take(state.players[state.turn].pond, -1) else [] end
                  Riichi.make_calls(state.rules["buttons"][button_name]["call"], state.players[seat].hand ++ state.players[seat].draw, callable_tiles)
              end
              flattened_call_choices = call_choices |> Map.values() |> Enum.concat()
              if length(flattened_call_choices) == 1 do
                # if there's only one choice, automatically choose it
                {called_tile, [call_choice]} = Enum.max_by(call_choices, fn {_tile, choices} -> length(choices) end)
                state = run_actions(state, actions, %{seat: seat, call_name: button_name, call_choice: call_choice, called_tile: called_tile})
                state
              else
                # otherwise, defer all actions and display call choices
                state = schedule_actions(state, seat, actions)
                state = update_player(state, seat, fn player -> %Player{ player | call_buttons: call_choices, call_name: button_name } end)
                notify_ai_call_buttons(state, seat)
                state
              end
            end
          else state end
          state
      end
      # done with all choices
      state = Buttons.recalculate_buttons(state)
      notify_ai(state)
      # state = update_all_players(state, fn _seat, player -> %Player{ player | choice: nil, chosen_actions: nil } end)
      Mutex.release(state.mutex, lock)
      # IO.puts("Done adjudicating actions!\n")
      state
    else state end
  end

  def submit_actions(state, seat, choice, actions) do
    if state.game_active && state.players[seat].choice == nil do
      # IO.puts("Submitting choice for #{seat}: #{choice}, #{inspect(actions)}")
      # IO.puts("Deferred actions for #{seat}: #{inspect(state.players[seat].deferred_actions)}")
      state = update_player(state, seat, &%Player{ &1 | choice: choice, chosen_actions: actions, deferred_actions: [] })

      # for the current turn's player, if they just acted (have deferred actions) and have no buttons, their choice is "skip"
      # for other players who have no buttons and have not made a choice yet, their choice is "skip"
      # also for other players who have made a choice, if their choice is superceded then set it to "skip"
      superceded_choices = get_superceded_choices(state)
      last_action = get_last_action(state)
      turn_just_acted = last_action != nil && not Enum.empty?(state.players[state.turn].deferred_actions) && last_action.seat == state.turn
      state = for {seat, player} <- state.players, reduce: state do
        state -> cond do
          seat == state.turn && turn_just_acted && Enum.empty?(player.buttons) && Enum.empty?(player.call_buttons) ->
            # IO.puts("Player #{seat} must skip due to having just discarded")
            update_player(state, seat, &%Player{ &1 | choice: "skip", chosen_actions: [] })
          seat != state.turn && player.choice == nil && Enum.empty?(player.buttons) && Enum.empty?(player.call_buttons) ->
            # IO.puts("Player #{seat} must skip due to having no buttons")
            update_player(state, seat, &%Player{ &1 | choice: "skip", chosen_actions: [] })
          seat != state.turn && player.choice != nil && Enum.member?(superceded_choices, player.choice) ->
            # IO.puts("Player #{seat} must skip due to having buttons superceded")
            update_player(state, seat, &%Player{ &1 | choice: "skip", chosen_actions: [] })
          true -> state
        end
      end

      # check if nobody else needs to make choices
      if Enum.all?(state.players, fn {_seat, player} -> player.choice != nil end) do
        # if every action is skip, we need to resume deferred actions for all players
        # otherwise, adjudicate actions as normal
        if Enum.all?(state.players, fn {_seat, player} -> player.choice == "skip" end) do
          if state.game_active do
            # IO.puts("All choices are no-ops, running deferred actions")
            state = for {seat, _player} <- state.players, reduce: state do
              state ->
                state = update_player(state, seat, fn player -> %Player{ player | choice: nil, chosen_actions: nil } end)
                state = run_deferred_actions(state, %{seat: seat})
                state
            end
            notify_ai(state)
            state
          else state end
        else
          adjudicate_actions(state)
        end
      else state end
    else state end
  end

end