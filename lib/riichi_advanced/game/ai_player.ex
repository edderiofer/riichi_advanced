defmodule RiichiAdvanced.AIPlayer do
  use GenServer

  @ai_speed 4

  def start_link(init_state) do
    GenServer.start_link(__MODULE__, init_state, name: init_state[:name])
  end

  def init(state) do
    state = Map.put(state, :initialized, false)
    state = Map.put(state, :shanten, 6)
    state = Map.put(state, :preselected_flower, nil)
    if RiichiAdvanced.GameState.Debug.debug_fast_ai() do
      :timer.apply_after(100, Kernel, :send, [self(), :initialize])
    else
      :timer.apply_after(2500, Kernel, :send, [self(), :initialize])
    end
    {:ok, state}
  end

  defp choose_playable_tile(tiles, playables, player, all_tiles, visible_tiles, win_definition) do
    if not Enum.empty?(playables) do
      # rank each playable tile by the ukeire it gives for the next shanten step
      # TODO as well as heuristics provided by the ruleset
      hand = player.hand ++ player.draw
      calls = player.calls
      ordering = player.tile_ordering
      ordering_r = player.tile_ordering_r
      tile_aliases = player.tile_aliases
      playable_waits = playables
      |> Enum.filter(fn {tile, _ix} -> Enum.any?(tiles, &Utils.same_tile(tile, &1)) end)
      |> Enum.map(fn {tile, ix} ->
        if win_definition != nil do
          {tile, ix, Riichi.get_waits_and_ukeire(all_tiles, visible_tiles, hand -- [tile], calls, win_definition, ordering, ordering_r, tile_aliases)}
        else {tile, ix, %{}} end
      end)

      # prefer highest ukeire
      ukeires = Enum.map(playable_waits, fn {tile, ix, waits} -> {tile, ix, Map.values(waits) |> Enum.sum()} end)
      max_ukeire = ukeires
      |> Enum.map(fn {_tile, _ix, outs} -> outs end)
      |> Enum.max(&>=/2, fn -> 0 end)
      best_playables_by_ukeire = for {tile, ix, outs} <- ukeires, outs == max_ukeire do {tile, ix} end

      # prefer outer discards
      {yaochuuhai, rest} = Enum.split_with(best_playables_by_ukeire, fn {tile, _ix} -> Riichi.is_yaochuuhai?(tile) end)
      {tiles28, rest} = Enum.split_with(rest, fn {tile, _ix} -> Riichi.is_num?(tile, 2) || Riichi.is_num?(tile, 8) end) 
      {tiles37, rest} = Enum.split_with(rest, fn {tile, _ix} -> Riichi.is_num?(tile, 3) || Riichi.is_num?(tile, 7) end) 
      for playable_tiles <- [yaochuuhai, tiles28, tiles37, rest], reduce: nil do
        nil -> if not Enum.empty?(playable_tiles) do Enum.random(playable_tiles) else nil end
        ret -> ret
      end
    else nil end
  end

  defp choose_discard(state, player, playables, all_tiles, visible_tiles) do
    hand = player.hand ++ player.draw
    calls = player.calls
    ordering = player.tile_ordering
    ordering_r = player.tile_ordering_r
    tile_aliases = player.tile_aliases
    shanten_definitions = [
      state.shanten_definitions.tenpai,
      state.shanten_definitions.iishanten,
      state.shanten_definitions.ryanshanten,
      state.shanten_definitions.sanshanten
    ]
    win_definitions = [
      state.shanten_definitions.win,
      state.shanten_definitions.tenpai,
      state.shanten_definitions.iishanten,
      state.shanten_definitions.ryanshanten
    ]
    shanten_definitions = Enum.zip(shanten_definitions, win_definitions) |> Enum.with_index()
    # skip tenpai check if 2-shanten, skip tenpai and 1-shanten check if 3-shanten
    shanten_definitions = case state.shanten do
      2 -> shanten_definitions |> Enum.drop(1)
      3 -> shanten_definitions |> Enum.drop(2)
      _ -> shanten_definitions
    end

    # check if tenpai
    {ret, shanten} = for {{shanten_definition, win_definition}, i} <- shanten_definitions, reduce: {nil, 6} do
      {nil, _} ->
        ret = Riichi.get_unneeded_tiles(hand, calls, shanten_definition, ordering, ordering_r, tile_aliases)
        |> choose_playable_tile(playables, player, all_tiles, visible_tiles, win_definition)
        # if ret != nil do
        #   IO.puts(" >> #{state.seat}: I'm currently #{i}-shanten!")
        # end
        {ret, i}
      ret -> ret
    end

    if ret == nil do # shanten > 3
      ret = Riichi.get_disconnected_tiles(hand, ordering, ordering_r, tile_aliases)
      |> choose_playable_tile(playables, player, all_tiles, visible_tiles, nil)
      {ret, 6}
    else {ret, shanten} end
  end

  defp get_mark_choices(source, players, revealed_tiles, num_scryed_tiles, wall) do
    case source do
      :done          -> []
      :hand          -> Enum.flat_map(players, fn {seat, p} -> Enum.map(p.hand ++ p.draw, &{seat, source, &1}) |> Enum.with_index() end)
      :call          -> Enum.flat_map(players, fn {seat, p} -> Enum.map(p.calls, &{seat, source, &1}) |> Enum.with_index() end)
      :discard       -> Enum.flat_map(players, fn {seat, p} -> Enum.map(p.pond, &{seat, source, &1}) |> Enum.with_index() end)
      :aside         -> Enum.flat_map(players, fn {seat, p} -> Enum.map(p.aside, &{seat, source, &1}) |> Enum.with_index() end)
      :revealed_tile -> revealed_tiles |> Enum.map(&{nil, source, &1}) |> Enum.with_index()
      :scry          -> wall |> Enum.take(num_scryed_tiles) |> Enum.map(&{nil, source, &1}) |> Enum.with_index()
      _              ->
        IO.puts("AI does not recognize the mark source #{inspect(source)}")
        {nil, nil, nil}
    end 
  end

  def handle_info(:initialize, state) do
    state = Map.put(state, :initialized, true)
    GenServer.cast(state.game_state, :notify_ai)
    {:noreply, state}
  end

  def handle_info({:your_turn, params}, state) do
    t = System.os_time(:millisecond)
    %{player: player, all_tiles: all_tiles, visible_tiles: visible_tiles} = params
    if state.initialized do
      if GenServer.call(state.game_state, {:can_discard, state.seat}) do
        state = %{ state | player: player }
        playable_hand = player.hand
        |> Enum.with_index()
        playable_draw = player.draw
        |> Enum.with_index()
        |> Enum.map(fn {tile, i} -> {tile, i + length(player.hand)} end)
        playables = playable_hand ++ playable_draw
        |> Enum.filter(fn {tile, _i} -> GenServer.call(state.game_state, {:is_playable, state.seat, tile}) end)

        if not Enum.empty?(playables) do
          # pick a random tile
          # {_tile, index} = Enum.random(playables)
          # pick the first playable tile
          # {_tile, index} = Enum.at(playables, 0)
          # pick the last playable tile (the draw)
          # {_tile, index} = Enum.at(playables, -1)
          # use our rudimentary AI for discarding
          # IO.puts(" >> #{state.seat}: Hand: #{inspect(Utils.sort_tiles(player.hand ++ player.draw))}")
          {{tile, index}, shanten} = if RiichiAdvanced.GameState.Debug.debug() do
            {Enum.at(playables, -1), 6}
          else
            case choose_discard(state, player, playables, all_tiles, visible_tiles) do
              {nil, _} ->
                # IO.puts(" >> #{state.seat}: Couldn't find a tile to discard! Doing tsumogiri instead")
                {Enum.at(playables, -1), 6} # tsumogiri, or last playable tile
              t -> t
            end
          end
          state = Map.put(state, :shanten, shanten)
          # IO.puts(" >> #{state.seat}: It's my turn to play a tile! #{inspect(playables)} / chose: #{inspect(tile)}")
          elapsed_time = System.os_time(:millisecond) - t
          wait_time = trunc(1200 / @ai_speed)
          if elapsed_time < wait_time do
            Process.sleep(wait_time - elapsed_time)
          end

          # if we're about to discard a joker/flower, call it instead
          tile = Utils.strip_attrs(tile)
          button_name = cond do
            "flower" in player.buttons -> "flower"
            "joker" in player.buttons -> "joker"
            true -> nil
          end
          choice = if button_name != nil do
            {:call, choices} = player.button_choices[button_name]
            Enum.find(choices[nil], fn [choice] -> Utils.same_tile(choice, tile) end)
          else nil end
          state = if choice != nil do
            GenServer.cast(state.game_state, {:press_button, state.seat, button_name})
            Map.put(state, :preselected_flower, tile)
          else
            GenServer.cast(state.game_state, {:play_tile, state.seat, index})
            state
          end
          {:noreply, state}
        else
          IO.puts(" >> #{state.seat}: It's my turn to play a tile, but there are no tiles I can play")
          {:noreply, state}
        end
      else
        IO.puts(" >> #{state.seat}: You said it's my turn to play a tile, but I am not in a state in which I can discard")
        {:noreply, state}
      end
    else
      # reschedule this for after we initialize
      :timer.apply_after(1000, Kernel, :send, [self(), {:your_turn, params}])
      {:noreply, state}
    end
  end

  def handle_info({:buttons, %{player: player, turn: turn}}, state) do
    t = System.os_time(:millisecond)
    if state.initialized do
      state = %{ state | player: player }
      # pick a random button
      # button_name = Enum.random(player.buttons)
      # pick the first button
      # button_name = Enum.at(player.buttons, 0)
      # pick the last button
      # button_name = Enum.at(player.buttons, -1)

      button_name = if "void_manzu" in player.buttons do
        # count suits, pick the minimum suit
        hand = player.hand ++ player.draw
        num_manzu = hand |> Enum.filter(&Riichi.is_manzu?/1) |> length()
        num_pinzu = hand |> Enum.filter(&Riichi.is_pinzu?/1) |> length()
        num_souzu = hand |> Enum.filter(&Riichi.is_souzu?/1) |> length()
        minimum = min(num_manzu, num_pinzu) |> min(num_souzu)
        cond do
          num_manzu == minimum -> "void_manzu"
          num_pinzu == minimum -> "void_pinzu"
          num_souzu == minimum -> "void_souzu"
        end
      else
        # pick these (in order of precedence)
        cond do
          "ron" in player.buttons -> "ron"
          "tsumo" in player.buttons -> "tsumo"
          "hu" in player.buttons -> "hu"
          "zimo" in player.buttons -> "zimo"
          "riichi" in player.buttons -> "riichi"
          "ankan" in player.buttons -> "ankan"
          "anfuun" in player.buttons -> "anfuun"
          "flower" in player.buttons -> "flower"
          "extra_turn" in player.buttons -> "extra_turn"
          "skip" in player.buttons -> "skip"
          true -> Enum.random(player.buttons)
        end
      end
      # IO.puts(" >> #{state.seat}: It's my turn to press buttons! #{inspect(player.buttons)} / chose: #{button_name}")
      elapsed_time = System.os_time(:millisecond) - t
      wait_time = trunc(500 / @ai_speed)
      if elapsed_time < wait_time do
        Process.sleep(wait_time - elapsed_time)
      end
      if button_name == "skip" && state.seat == turn do
        GenServer.cast(state.game_state, {:ai_ignore_buttons, state.seat})
      else
        GenServer.cast(state.game_state, {:press_button, state.seat, button_name})
      end
      state = Map.put(state, :preselected_flower, nil)
      {:noreply, state}
    else
      # reschedule this for after we initialize
      :timer.apply_after(1000, Kernel, :send, [self(), {:buttons, %{player: player, turn: turn}}])
      {:noreply, state}
    end
  end

  def handle_info({:call_buttons, %{player: player}}, state) do
    if state.initialized do
      state = %{ state | player: player }
      # pick a random call
      called_tile = player.call_buttons
        |> Map.keys()
        |> Enum.filter(fn tile -> not Enum.empty?(player.call_buttons[tile]) end)
        |> Enum.random()
      if called_tile != "saki" do
        {called_tile, call_choice} = if state.preselected_flower != nil do
          {nil, [state.preselected_flower]}
        else
          {called_tile, Enum.random(player.call_buttons[called_tile])}
        end
        # IO.puts(" >> #{state.seat}: It's my turn to press call buttons! #{inspect(player.call_buttons)} / chose: #{inspect(called_tile)} #{inspect(call_choice)}")
        Process.sleep(trunc(500 / @ai_speed))
        GenServer.cast(state.game_state, {:press_call_button, state.seat, player.call_name, call_choice, called_tile})
      else
        [choice] = Enum.random(player.call_buttons["saki"])
        # IO.puts(" >> #{state.seat}: It's my turn to choose a saki card! #{inspect(player.call_buttons)} / chose: #{inspect(choice)}")
        Process.sleep(trunc(500 / @ai_speed))
        GenServer.cast(state.game_state, {:press_saki_card, state.seat, choice})
      end
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  def handle_info({:mark_tiles, %{player: player, players: players, revealed_tiles: revealed_tiles, wall: wall, marked_objects: marked_objects}}, state) do
    if state.initialized do
      state = %{ state | player: player }
      IO.puts(" >> #{state.seat}: It's my turn to mark tiles!")
      # for each source, generate all possible choices and pick one of them
      Process.sleep(trunc(500 / @ai_speed))
      choices = marked_objects
      |> Enum.flat_map(fn {source, _mark_info} -> get_mark_choices(source, players, revealed_tiles, player.num_scryed_tiles, wall) end)
      choice = choices
      |> Enum.filter(fn {{seat, source, _obj}, i} -> GenServer.call(state.game_state, {:can_mark?, state.seat, seat, i, source}) end)
      |> Enum.shuffle()
      case choice do
        [{{seat, source, _obj}, i} | _] -> GenServer.cast(state.game_state, {:mark_tile, state.seat, seat, i, source})
        _ ->
          IO.puts(" >> #{state.seat}: Unfortunately I cannot mark anything: #{inspect(choice)}")
          IO.puts(" >> #{state.seat}: My choices were: #{inspect(choices)}")
      end
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  def handle_info({:declare_yaku, %{player: player}}, state) do
    if state.initialized do
      state = %{ state | player: player }
      IO.puts(" >> #{state.seat}: It's my turn to declare yaku!")
      GenServer.cast(state.game_state, {:declare_yaku, state.seat, ["Riichi"]})
      {:noreply, state}
    else
      {:noreply, state}
    end
  end
end