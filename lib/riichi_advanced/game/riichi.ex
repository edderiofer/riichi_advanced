defmodule RiichiAdvanced.Riichi do
  alias RiichiAdvanced.Constants, as: Constants
  alias RiichiAdvanced.GameState.TileBehavior, as: TileBehavior
  alias RiichiAdvanced.Match, as: Match
  alias RiichiAdvanced.Utils, as: Utils
  use Nebulex.Caching

  @flower_names ["start_flower", "start_joker", "flower", "joker"]
  def flower_names(), do: @flower_names

  @manzu      [:"1m", :"2m", :"3m", :"4m", :"5m", :"6m", :"7m", :"8m", :"9m", :"10m", :"0m",
               :"01m", :"02m", :"03m", :"04m", :"05m", :"06m", :"07m", :"08m", :"09m", :"010m",
               :"11m", :"12m", :"13m", :"14m", :"15m", :"16m", :"17m", :"18m", :"19m", :"110m",
               :"21m", :"22m", :"23m", :"24m", :"25m", :"26m", :"27m", :"28m", :"29m", :"210m",
               :"31m", :"32m", :"33m", :"34m", :"35m", :"36m", :"37m", :"38m", :"39m", :"310m",
               :"41m", :"42m", :"44m", :"44m", :"45m", :"46m", :"47m", :"48m", :"49m", :"410m"]
  @pinzu      [:"1p", :"2p", :"3p", :"4p", :"5p", :"6p", :"7p", :"8p", :"9p", :"10p", :"0p",
               :"01p", :"02p", :"03p", :"04p", :"05p", :"06p", :"07p", :"08p", :"09p", :"010p",
               :"11p", :"12p", :"13p", :"14p", :"15p", :"16p", :"17p", :"18p", :"19p", :"110p",
               :"21p", :"22p", :"23p", :"24p", :"25p", :"26p", :"27p", :"28p", :"29p", :"210p",
               :"31p", :"32p", :"33p", :"34p", :"35p", :"36p", :"37p", :"38p", :"39p", :"310p",
               :"41p", :"42p", :"44p", :"44p", :"45p", :"46p", :"47p", :"48p", :"49p", :"410p"]
  @souzu      [:"1s", :"2s", :"3s", :"4s", :"5s", :"6s", :"7s", :"8s", :"9s", :"10s", :"0s", :"00s",
               :"01s", :"02s", :"03s", :"04s", :"05s", :"06s", :"07s", :"08s", :"09s", :"010s", :"000s",
               :"11s", :"12s", :"13s", :"14s", :"15s", :"16s", :"17s", :"18s", :"19s", :"110s", :"100s",
               :"21s", :"22s", :"23s", :"24s", :"25s", :"26s", :"27s", :"28s", :"29s", :"210s", :"200s",
               :"31s", :"32s", :"33s", :"34s", :"35s", :"36s", :"37s", :"38s", :"39s", :"310s", :"300s",
               :"41s", :"42s", :"44s", :"44s", :"45s", :"46s", :"47s", :"48s", :"49s", :"410s", :"400s",
               :"1's", :"01's", :"11's", :"21's", :"31's", :"41's"]
  @jihai      [:"1z", :"2z", :"3z", :"4z", :"5z", :"6z", :"7z", :"8z", :"0z",
               :"01z", :"02z", :"03z", :"04z", :"05z", :"06z", :"07z", :"08z", :"00z",
               :"11z", :"12z", :"13z", :"14z", :"15z", :"16z", :"17z", :"18z",
               :"21z", :"22z", :"23z", :"24z", :"25z", :"26z", :"27z", :"28z", :"20z",
               :"31z", :"32z", :"33z", :"34z", :"35z", :"36z", :"37z", :"38z", :"30z",
               :"41z", :"42z", :"44z", :"44z", :"45z", :"46z", :"47z", :"48z", :"40z",
               :"5j", :"15j", :"4j", :"14j", :"3j"]
  @wind       [:"1z", :"2z", :"3z", :"4z",
               :"01z", :"02z", :"03z", :"04z",
               :"11z", :"12z", :"13z", :"14z",
               :"21z", :"22z", :"23z", :"24z",
               :"31z", :"32z", :"33z", :"34z",
               :"41z", :"42z", :"43z", :"44z",
               :"5j", :"15j"]
  @dragon     [:"5z", :"0z", :"8z", :"6z", :"7z",
               :"05z", :"00z", :"08z", :"06z", :"07z",
               :"15z", :"10z", :"18z", :"16z", :"17z",
               :"25z", :"20z", :"28z", :"26z", :"27z",
               :"35z", :"30z", :"38z", :"36z", :"37z",
               :"45z", :"40z", :"48z", :"46z", :"47z",
               :"4j", :"14j",
               :"9z", :"5'z", :"05'z", :"25'z", :"35'z", :"45'z", :"5`z", :"05`z", :"15`z", :"25`z", :"35`z", :"45`z"]
  @terminal   [:"1m", :"01m", :"11m", :"21m", :"31m", :"41m",
               :"1p", :"01p", :"11p", :"21p", :"31p", :"41p",
               :"1s", :"01s", :"11s", :"21s", :"31s", :"41s",
               :"9m", :"09m", :"19m", :"29m", :"39m", :"49m",
               :"9p", :"09p", :"19p", :"29p", :"39p", :"49p",
               :"9s", :"09s", :"19s", :"29s", :"39s", :"49s",
               :"10m", :"010m", :"110m", :"210m", :"310m", :"410m",
               :"10p", :"010p", :"110p", :"210p", :"310p", :"410p",
               :"10s", :"010s", :"110s", :"210s", :"310s", :"410s",
               :"1's", :"01's", :"11's", :"21's", :"31's", :"41's"]
  # TODO somehow change these when ten mod is active
  @flower     [:"1f", :"2f", :"3f", :"4f", :"1g", :"2g", :"3g", :"4g", :"1k", :"2k", :"3k", :"4k", :"1q", :"2q", :"3q", :"4q", :"1a", :"2a", :"3a", :"4a", :"1y"]
  @joker      [:"0j", :"1j", :"2j", :"3j", :"4j", :"5j", :"6j", :"7j", :"8j", :"9j", :"10j", :"12j", :"13j", :"14j", :"15j", :"16j", :"17j", :"18j", :"19j", :"37j", :"46j", :"147j", :"258j", :"369j", :"123j", :"456j", :"789j", :"91j", :"73j", :"64j", :"852j", :"20j", :"11j", :"22j", :"30j", :"31j", :"32j", :"33j", :"34j", :"2y"]
  @aka        [:"0m", :"0p", :"0s",
               :"01m", :"02m", :"03m", :"04m", :"05m", :"25m", :"35m", :"06m", :"07m", :"08m", :"09m", :"010m",
               :"01p", :"02p", :"03p", :"04p", :"05p", :"25p", :"35p", :"06p", :"07p", :"08p", :"09p", :"010p",
               :"01s", :"02s", :"03s", :"04s", :"05s", :"25s", :"35s", :"06s", :"07s", :"08s", :"09s", :"010s",
               :"01's", :"05's", :"05`s"]

  def is_manzu?(tile), do: Enum.any?(@manzu, &Utils.same_tile(tile, &1))
  def is_pinzu?(tile), do: Enum.any?(@pinzu, &Utils.same_tile(tile, &1))
  def is_souzu?(tile), do: Enum.any?(@souzu, &Utils.same_tile(tile, &1))
  def is_jihai?(tile), do: Enum.any?(@jihai, &Utils.same_tile(tile, &1))
  def is_suited?(tile), do: is_manzu?(tile) or is_pinzu?(tile) or is_souzu?(tile)
  def is_wind?(tile), do: Enum.any?(@wind, &Utils.same_tile(tile, &1))
  def is_dragon?(tile), do: Enum.any?(@dragon, &Utils.same_tile(tile, &1))
  def is_terminal?(tile), do: Enum.any?(@terminal, &Utils.same_tile(tile, &1))
  def is_yaochuuhai?(tile), do: is_terminal?(tile) or is_wind?(tile) or is_dragon?(tile)
  def is_tanyaohai?(tile), do: is_suited?(tile) and not is_terminal?(tile)
  def is_flower?(tile), do: Enum.any?(@flower, &Utils.same_tile(tile, &1))
  def is_joker?(tile), do: Enum.any?(@joker, &Utils.same_tile(tile, &1))
  def is_aka?(tile), do: Enum.any?(@aka, &Utils.same_tile(tile, &1))

  @one [:"1m", :"1p", :"1s", :"01m", :"01p", :"01s", :"11m", :"11p", :"11s", :"21m", :"21p", :"21s", :"31m", :"31p", :"31s", :"41m", :"41p", :"41s"]
  @two [:"2m", :"2p", :"2s", :"02m", :"02p", :"02s", :"12m", :"12p", :"12s", :"22m", :"22p", :"22s", :"32m", :"32p", :"32s", :"42m", :"42p", :"42s"]
  @three [:"3m", :"3p", :"3s", :"03m", :"03p", :"03s", :"13m", :"13p", :"13s", :"23m", :"23p", :"23s", :"33m", :"33p", :"33s", :"43m", :"43p", :"43s"]
  @four [:"4m", :"4p", :"4s", :"04m", :"04p", :"04s", :"14m", :"14p", :"14s", :"24m", :"24p", :"24s", :"34m", :"34p", :"34s", :"44m", :"44p", :"44s"]
  @five [:"0m", :"0p", :"0s", :"5m", :"5p", :"5s", :"05m", :"05p", :"05s", :"15m", :"15p", :"15s", :"25m", :"25p", :"25s", :"35m", :"35p", :"35s", :"45m", :"45p", :"45s"]
  @six [:"6m", :"6p", :"6s", :"06m", :"06p", :"06s", :"16m", :"16p", :"16s", :"26m", :"26p", :"26s", :"36m", :"36p", :"36s", :"46m", :"46p", :"46s"]
  @seven [:"7m", :"7p", :"7s", :"07m", :"07p", :"07s", :"17m", :"17p", :"17s", :"27m", :"27p", :"27s", :"37m", :"37p", :"37s", :"47m", :"47p", :"47s"]
  @eight [:"8m", :"8p", :"8s", :"08m", :"08p", :"08s", :"18m", :"18p", :"18s", :"28m", :"28p", :"28s", :"38m", :"38p", :"38s", :"48m", :"48p", :"48s"]
  @nine [:"9m", :"9p", :"9s", :"09m", :"09p", :"09s", :"19m", :"19p", :"19s", :"29m", :"29p", :"29s", :"39m", :"39p", :"39s", :"49m", :"49p", :"49s"]
  @ten [:"10m", :"10p", :"10s", :"010m", :"010p", :"010s", :"110m", :"110p", :"110s", :"210m", :"210p", :"210s", :"310m", :"310p", :"310s", :"410m", :"410p", :"410s"]
  def is_num?(tile, num) do
    Enum.any?(case num do
      1 -> @one
      2 -> @two
      3 -> @three
      4 -> @four
      5 -> @five
      6 -> @six
      7 -> @seven
      8 -> @eight
      9 -> @nine
      10 -> @ten
    end, &Utils.same_tile(tile, &1))
  end
  def to_num(tile) do
    {tile, _attrs} = Utils.to_attr_tile(tile)
    cond do
      tile in @one   -> 1
      tile in @two   -> 2
      tile in @three -> 3
      tile in @four  -> 4
      tile in @five  -> 5
      tile in @six   -> 6
      tile in @seven -> 7
      tile in @eight -> 8
      tile in @nine  -> 9
      tile in @ten   -> 10
      true           -> nil
    end
  end
  @east [:"1z", :"01z", :"11z", :"21z", :"31z", :"41z"]
  @south [:"2z", :"02z", :"12z", :"22z", :"32z", :"42z"]
  @west [:"3z", :"03z", :"13z", :"23z", :"33z", :"43z"]
  @north [:"4z", :"04z", :"14z", :"24z", :"34z", :"44z"]
  @white [:"5z", :"05z", :"15z", :"25z", :"35z", :"45z", :"9z", :"5'z", :"05'z", :"25'z", :"35'z", :"45'z", :"5`z", :"05`z", :"15`z", :"25`z", :"35`z", :"45`z"]
  @green [:"6z", :"06z", :"16z", :"26z", :"36z", :"46z"]
  @red [:"7z", :"07z", :"17z", :"27z", :"37z", :"47z"]
  def to_letter(tile) do
    {tile, _attrs} = Utils.to_attr_tile(tile)
    cond do
      tile in @east  -> "E"
      tile in @south -> "S"
      tile in @west  -> "W"
      tile in @north -> "N"
      tile in @white -> "Wh"
      tile in @green -> "G"
      tile in @red   -> "R"
      true           -> nil
    end
  end

  def same_suit?(tile, tile2) do
    cond do
      is_manzu?(tile) -> is_manzu?(tile2)
      is_pinzu?(tile) -> is_pinzu?(tile2)
      is_souzu?(tile) -> is_souzu?(tile2)
      is_jihai?(tile) -> is_jihai?(tile2)
      true            -> false
    end
  end
  def same_number?(tile, tile2) do
    cond do
      is_num?(tile, 1) -> is_num?(tile2, 1) 
      is_num?(tile, 2) -> is_num?(tile2, 2) 
      is_num?(tile, 3) -> is_num?(tile2, 3) 
      is_num?(tile, 4) -> is_num?(tile2, 4) 
      is_num?(tile, 5) -> is_num?(tile2, 5) 
      is_num?(tile, 6) -> is_num?(tile2, 6) 
      is_num?(tile, 7) -> is_num?(tile2, 7) 
      is_num?(tile, 8) -> is_num?(tile2, 8) 
      is_num?(tile, 9) -> is_num?(tile2, 9) 
      true            -> false
    end
  end

  # return all possible calls of each tile in called_tiles, given hand
  # includes returning multiple choices for jokers (incl. red fives)
  # if called_tiles is an empty list, then we choose from our hand
  # example output: %{:"5m" => [[:"4m", :"6m"], [:"6m", :"7m"]]}
  def make_calls(calls_spec, hand, tile_behavior, called_tiles \\ []) do
    # t = System.os_time(:millisecond)

    # IO.puts("#{inspect(calls_spec)} / #{inspect(hand)} / #{inspect(called_tiles)}")
    from_hand = Enum.empty?(called_tiles)
    {calls_spec, tile_behavior} = if Enum.at(calls_spec, 0) == "nojoker" do
      {Enum.drop(calls_spec, 1), %TileBehavior{ tile_behavior | aliases: %{} }}
    else {calls_spec, tile_behavior} end
    ret = for tile <- (if from_hand do hand else called_tiles end) do
      {tile, Enum.flat_map(calls_spec, fn call_spec ->
        hand = if from_hand do List.delete(hand, tile) else hand end
        # before we make calls using the offsets,
        # we must instantiate the tile in case it's a joker
        instances = Utils.apply_tile_aliases(tile, tile_behavior)
        if :any in instances do hand else instances end
        |> Enum.reject(fn tile -> with {tile, _attrs} <- Utils.to_attr_tile(tile) do tile == :any end end)
        |> Enum.reject(&TileBehavior.is_joker?(&1, tile_behavior))
        |> Utils.strip_attrs()
        |> Enum.flat_map(fn instance ->
          target_tiles = Enum.map(call_spec, &Match.offset_tile(instance, &1, tile_behavior))
          if nil in target_tiles do
            []
          else
            possible_removals = Match.try_remove_all_tiles(hand, target_tiles, tile_behavior)
            Enum.map(possible_removals, fn remaining -> Utils.sort_tiles(hand -- remaining) end)
          end
        end)
      end) |> Enum.uniq()}
    end |> Enum.uniq_by(fn {tile, choices} -> Enum.map(choices, fn choice -> Enum.sort([tile | choice]) end) end) |> Map.new()

    # elapsed_time = System.os_time(:millisecond) - t
    # if elapsed_time > 10 do
    #   IO.puts("make_calls/can_call: #{inspect(elapsed_time)} ms")
    # end
    
    ret
  end
  def can_call?(calls_spec, hand, tile_behavior, called_tiles \\ []), do: Enum.any?(make_calls(calls_spec, hand, tile_behavior, called_tiles), fn {_tile, choices} -> not Enum.empty?(choices) end)

  # get all unique waits for a given 14-tile match definition, like win
  # will not remove a wait if you have four of the tile in hand or calls
  @decorate cacheable(cache: RiichiAdvanced.Cache, key: {:get_waits, hand, calls, match_definitions, TileBehavior.hash(tile_behavior)})
  def get_waits(hand, calls, match_definitions, tile_behavior, skip_tenpai_check \\ false) do
    # only check for waits if we're tenpai
    if skip_tenpai_check or Match.match_hand(hand, calls, Enum.map(match_definitions, &["almost" | &1]), tile_behavior) do
      # go through each match definition and see what tiles can be added for it to match
      # as soon as something doesn't match, get all tiles that help make it match
      # take the union of helpful tiles across all match definitions
      for match_definition <- match_definitions do
        # make it exhaustive, unless it's unique
        match_definition = if "unique" not in match_definition and "exhaustive" not in match_definition do ["exhaustive" | match_definition] else match_definition end
        # IO.puts("\n" <> inspect(match_definition))
        {_keywords, waits_complement, waits_complement_across_restarts} = for {last_match_definition_elem, i} <- Enum.with_index(match_definition), reduce: {[], tile_behavior.tile_freqs, %{}} do
          {keywords, waits_complement, waits_complement_across_restarts} -> case last_match_definition_elem do
            "restart" -> {keywords ++ ["restart"], tile_behavior.tile_freqs, Map.merge(waits_complement, waits_complement_across_restarts, fn _k, l, r -> max(l, r) end) }
            keyword when is_binary(keyword) -> {keywords ++ [keyword], waits_complement, waits_complement_across_restarts}
            [_groups, num] when num <= 0 -> {keywords, waits_complement, waits_complement_across_restarts} # ignore lookaheads
            [groups, num] ->
              # get all other groups in the current restart of our match definition
              remaining_match_definition = List.delete_at(match_definition, i)
              |> Utils.split_on("restart")
              |> Enum.at(Enum.count(keywords, & &1 == "restart"))

              # first remove all other groups
              hand_calls = [{hand, calls}]
              hand_calls = Enum.flat_map(hand_calls, fn {hand, calls} ->
                Match.remove_match_definition(hand, calls, remaining_match_definition, tile_behavior)
              end)
              |> Enum.uniq()

              # then remove groups num-1 times no matter what
              # num_hand_calls = length(hand_calls)
              hand_calls = if num > 1 do
                Enum.flat_map(hand_calls, fn {hand, calls} ->
                  Match.remove_match_definition(hand, calls, keywords ++ [[groups, num - 1]], tile_behavior)
                end)
                |> Enum.uniq()
              else hand_calls end

              # try to remove the last one
              final_match_definition = keywords ++ [[groups, 1]]
              {hand_calls_success, hand_calls_failure} = Enum.map(hand_calls, fn {hand, calls} ->
                case Match.remove_match_definition(hand, calls, final_match_definition, tile_behavior) do
                  []         -> {[], [{hand, calls}]} # failure
                  hand_calls -> {hand_calls, []} # success (new hand_calls)
                end
              end)
              |> Enum.unzip()
              hand_calls_success = Enum.concat(hand_calls_success)
              hand_calls_failure = Enum.concat(hand_calls_failure)
              # IO.puts("#{inspect(keywords)} #{inspect(last_match_definition_elem)}: #{num_hand_calls} tries (#{length(hand_calls)} after filtering), #{length(hand_calls_success)} successes, #{length(hand_calls_failure)} failures")
              # IO.inspect(hand_calls_success, label: "hand_calls_success")
              # IO.inspect(hand_calls_failure, label: "hand_calls_failure")

              # waits_complement = all waits that don't help
              # remove waits that do help
              waits_complement = if Enum.empty?(hand_calls_success) do
                Enum.reject(waits_complement, fn {wait, _freq} ->
                  Enum.any?(hand_calls_failure, fn {hand, calls} ->
                    Match.match_hand([wait | hand], calls, [final_match_definition], tile_behavior)
                  end)
                end) |> Map.new()
              else %{} end # the match definition succeeding without having to add a tile implies all tiles are a wait

              {keywords, waits_complement, waits_complement_across_restarts}
            _ -> {keywords, waits_complement, waits_complement_across_restarts}
          end
        end
        # IO.inspect({match_definition, Utils.inverse_frequencies(waits_complement, tile_behavior), Utils.inverse_frequencies(waits_complement_across_restarts, tile_behavior)})
        waits_complement_across_restarts = Map.merge(waits_complement, waits_complement_across_restarts, fn _k, l, r -> max(l, r) end)
        waits = Utils.inverse_frequencies(waits_complement_across_restarts, tile_behavior)
        |> Map.keys()
        |> MapSet.new()
        # IO.inspect(hand, label: "===\nhand")
        # IO.inspect(match_definition, label: "match_definition")
        # IO.inspect(waits, label: "waits")
        waits
      end
      |> Enum.reduce(MapSet.new(), &MapSet.union/2)
    else MapSet.new() end
  end

  @decorate cacheable(cache: RiichiAdvanced.Cache, key: {:get_waits_and_ukeire, hand, calls, match_definitions, visible_tiles, TileBehavior.hash(tile_behavior)})
  def get_waits_and_ukeire(hand, calls, match_definitions, visible_tiles, tile_behavior, skip_tenpai_check \\ false) do
    waits = get_waits(hand, calls, match_definitions, tile_behavior, skip_tenpai_check)
    freqs = Utils.inverse_frequencies(visible_tiles, tile_behavior)
    Map.new(waits, &{&1, Map.get(freqs, &1, 0)})
  end

  def get_safe_tiles_against(seat, players, turn \\ nil) do
    riichi_safe = if players[seat].cache.riichi_discard_indices != nil do
      for {dir, ix} <- players[seat].cache.riichi_discard_indices do
        discards = Enum.drop(players[dir].discards, ix)
        # last discard is not safe
        if turn == dir do Enum.drop(discards, -1) else discards end
      end |> Enum.concat()
    else [] end
    players[seat].discards ++ riichi_safe |> Utils.strip_attrs() |> Enum.uniq()
  end

  def tile_matches(tile_specs, context) do
    Enum.any?(tile_specs, fn tile_spec ->
      negated = String.starts_with?(tile_spec, "not_")
      tile_spec = if negated do String.replace_leading(tile_spec, "not_", "") else tile_spec end
      negated != case tile_spec do
        "any" -> true
        "same" ->  Utils.same_tile(context.tile, context.tile2, context.players[context.seat].tile_behavior)
        "not_same" -> not Utils.same_tile(context.tile, context.tile2, context.players[context.seat].tile_behavior)
        "manzu" -> is_manzu?(context.tile)
        "pinzu" -> is_pinzu?(context.tile)
        "souzu" -> is_souzu?(context.tile)
        "jihai" -> is_jihai?(context.tile)
        "dragon" -> is_dragon?(context.tile)
        "wind" -> is_wind?(context.tile)
        "terminal" -> is_terminal?(context.tile)
        "yaochuuhai" -> is_yaochuuhai?(context.tile)
        "tanyaohai" -> is_tanyaohai?(context.tile)
        "flower" -> is_flower?(context.tile)
        "joker" -> is_joker?(context.tile)
        "1" -> is_num?(context.tile, 1)
        "2" -> is_num?(context.tile, 2)
        "3" -> is_num?(context.tile, 3)
        "4" -> is_num?(context.tile, 4)
        "5" -> is_num?(context.tile, 5)
        "6" -> is_num?(context.tile, 6)
        "7" -> is_num?(context.tile, 7)
        "8" -> is_num?(context.tile, 8)
        "9" -> is_num?(context.tile, 9)
        "tedashi" -> not Utils.has_attr?(context.tile, ["_draw"])
        "tsumogiri" -> Utils.has_attr?(context.tile, ["_draw"])
        "dora" -> Utils.has_matching_tile?([context.tile], context.doras)
        "kuikae" ->
          player = context.players[context.seat]
          base_tiles = Match.collect_base_tiles(player.hand, player.calls, [0,1,2], player.tile_behavior)
          potential_set = Utils.add_attr(Enum.take(context.call.other_tiles, 2) ++ [context.tile2], ["_hand"])
          triplet = Match.remove_group(potential_set, [], [0,0,0], base_tiles, player.tile_behavior)
          sequence = Match.remove_group(potential_set, [], [0,1,2], base_tiles, player.tile_behavior)
          not Enum.empty?(triplet ++ sequence)
        tile_spec ->
          tile_behavior = Map.get(context, :tile_behavior, %TileBehavior{})
          # "1m", "2z" are also specs
          if Utils.is_tile(tile_spec) do
            Utils.same_tile(context.tile, Utils.to_tile(tile_spec), tile_behavior)
          else
            IO.puts("Unhandled tile spec #{inspect(tile_spec)}")
            true
          end
      end
    end)
  end
  def tile_matches_all(tile_specs, context) do
    Enum.all?(tile_specs, &tile_matches([&1], context))
  end

  # given a 14-tile hand, and match definitions for 13-tile hands,
  # return all the (unique) tiles that are not needed to match the definitions
  @decorate cacheable(cache: RiichiAdvanced.Cache, key: {:get_unneeded_tiles, hand, calls, match_definitions, TileBehavior.hash(tile_behavior)})
  def get_unneeded_tiles(hand, calls, match_definitions, tile_behavior) do
    t = System.os_time(:millisecond)
    tile_behavior = Match.filter_irrelevant_tile_aliases(tile_behavior, hand ++ Enum.flat_map(calls, &Utils.call_to_tiles/1))

    {match_definitions, hand_calls} = for match_definition <- match_definitions do
      # initial guess comes from just removing each match definition and seeing what's left
      hand_calls = Match.remove_match_definition(hand, calls, match_definition, tile_behavior)
      # filter out lookaheads from match definition
      match_definition = Enum.filter(match_definition, fn match_definition_elem -> is_binary(match_definition_elem) or with [_groups, num] <- match_definition_elem do num > 0 end end)
      # add exhaustive unless unique
      match_definition = if "unique" not in match_definition and "exhaustive" not in match_definition do ["exhaustive" | match_definition] else match_definition end
      {match_definition, hand_calls}
    end
    # filter out match definitions that don't match at all
    |> Enum.reject(fn {_match_definition, hand_calls} -> Enum.empty?(hand_calls) end)
    |> Enum.unzip()

    # get union of unneeded tiles found this way
    unneeded = hand_calls
    |> Enum.concat()
    |> Enum.flat_map(fn {hand, _calls} -> hand end)
    |> Enum.uniq()

    elapsed_time = System.os_time(:millisecond) - t
    if elapsed_time > 250 do
      IO.puts("get_unneeded_tiles: #{inspect(elapsed_time)} ms to get initial tiles")
    end

    ret = if not Enum.empty?(match_definitions) do
      # # method 1: keep tiles in hand that are not needed to match the given match definitions
      # ret = hand
      # |> Enum.uniq()
      # |> Enum.filter(&Match.match_hand(hand -- [&1], calls, match_definitions, tile_behavior))

      # # method 2: remove each match definition individually and take union of all leftover tiles
      # note: doesn't work if you have 2+ extra tiles
      # {leftover_tiles, _} = Enum.map(match_definitions, fn match_definition ->
      #   Task.async(fn -> Match.remove_match_definition(hand, calls, match_definition, tile_behavior) end)
      # end)
      # |> Task.yield_many(timeout: :infinity)
      # |> Enum.flat_map(fn {_task, {:ok, res}} -> res end)
      # |> Enum.unzip()
      # ret = leftover_tiles
      # |> Enum.concat()
      # |> Enum.uniq()
      # |> IO.inspect()

      # # method 3: method 2, but make each match definition non-exhaustive to get an initial set,
      # #           then use method 1 on the remaining tiles
      # {leftover_tiles, _} = Enum.map(match_definitions, fn match_definition ->
      #   match_definition = Enum.reject(match_definition, & &1 == "exhaustive")
      #   Task.async(fn -> Match.remove_match_definition(hand, calls, match_definition, tile_behavior) end)
      # end)
      # |> Task.yield_many(timeout: :infinity)
      # |> Enum.flat_map(fn {_task, {:ok, res}} -> res end)
      # |> Enum.unzip()
      # leftover_tiles = Enum.concat(leftover_tiles) |> IO.inspect(label: "a")
      # remaining = Enum.uniq(hand -- leftover_tiles)
      # ret = Enum.filter(remaining, &Match.match_hand(hand -- [&1], calls, match_definitions, tile_behavior)) |> IO.inspect(label: "b")
      # ret = Enum.uniq(ret ++ leftover_tiles)
      # ret |> IO.inspect(label: "c")

      # # method 4: same as method 3 but we already have an initial set from above
      # remaining = Enum.uniq(hand) -- unneeded
      # IO.puts("get_unneeded_tiles: now checking each of #{inspect(remaining)} individually")
      # ret = Enum.filter(remaining, &Match.match_hand(hand -- [&1], calls, match_definitions, tile_behavior))
      # ret = Enum.uniq(ret ++ unneeded)
      # ret

      # method 5: same as method 4 but parallel
      remaining = Enum.uniq(hand) -- unneeded
      # IO.puts("get_unneeded_tiles: now checking each of #{inspect(remaining)} individually")
      ret = for tile <- remaining do
        Task.async(fn -> if Match.match_hand(hand -- [tile], calls, match_definitions, tile_behavior) do [tile] else [] end end)
      end
      |> Task.yield_many(timeout: :infinity)
      |> Enum.flat_map(fn {_task, {:ok, res}} -> res end)
      ret = Enum.uniq(ret ++ unneeded)
      ret

      # i think a good method 6 is to use prepend_group_all on individual groups in a match definition
      # like take all the groups appearing in match definitions
      # then take each group, say [groups, n]
      # use prepend_group_all to get all instances of removing n of those groups
      # oh, but what if groups is multiple groups?

    else [] end

    elapsed_time = System.os_time(:millisecond) - t
    if elapsed_time > 250 do
      IO.puts("get_unneeded_tiles: #{inspect(elapsed_time)} ms")
    end
    ret
  end

  def needed_for_hand(hand, calls, tile, match_definitions, tile_behavior) do
    tile not in get_unneeded_tiles(hand, calls, match_definitions, tile_behavior)
  end

  def get_round_wind(kyoku, num_players) do
    case num_players do
      1 -> cond do
        kyoku == 0 -> :east
        kyoku == 1 -> :south
        kyoku == 2 -> :west
        kyoku >= 3 -> :north
      end
      2 -> cond do
        kyoku >= 0 and kyoku < 2 -> :east
        kyoku >= 2 and kyoku < 4 -> :south
        kyoku >= 4 and kyoku < 6 -> :west
        kyoku >= 6 -> :north
      end
      3 -> cond do
        kyoku >= 0 and kyoku < 3 -> :east
        kyoku >= 3 and kyoku < 6 -> :south
        kyoku >= 6 and kyoku < 9 -> :west
        kyoku >= 9 -> :north
      end
      4 -> cond do
        kyoku >= 0 and kyoku < 4 -> :east
        kyoku >= 4 and kyoku < 8 -> :south
        kyoku >= 8 and kyoku < 12 -> :west
        kyoku >= 12 -> :north
      end
    end
  end

  def get_seat_wind(kyoku, seat, available_seats) do
    ix = Enum.find_index(available_seats, & &1 == seat)
    if ix == nil do nil else Enum.at(available_seats, Integer.mod(ix - kyoku, length(available_seats))) end
  end

  def get_player_from_seat_wind(kyoku, wind, available_seats) do
    ix = Enum.find_index(available_seats, & &1 == wind)
    if ix == nil do nil else Enum.at(available_seats, rem(ix + kyoku, length(available_seats))) end
  end

  def get_east_player_seat(kyoku, available_seats) do
    Enum.at(available_seats, rem(kyoku, length(available_seats)))
  end

  def get_seat_scoring_offset(kyoku, seat, available_seats) do
    case get_seat_wind(kyoku, seat, available_seats) do
      :east  -> 3
      :south -> 2
      :west  -> 1
      :north -> 0
    end
  end

  def get_break_direction(dice_roll, kyoku, seat, available_seats) do
    wall_dir = cond do
      dice_roll in [2, 6, 10] -> :south
      dice_roll in [3, 7, 11] -> :west
      dice_roll in [4, 8, 12] -> :north
      true                    -> :east
    end
    get_seat_wind(kyoku, seat, available_seats) |> Utils.get_relative_seat(wall_dir)
  end

  def calc_ko_oya_points(score, is_dealer, num_players, han_fu_rounding_factor) do
    divisor = if num_players == 4 do
      if is_dealer do 3 else 4 end
    else # sanma
      if is_dealer do 2 else 3 end
    end
    ko_payment = trunc(Float.ceil(score / divisor / han_fu_rounding_factor) * han_fu_rounding_factor)
    oya_payment = trunc(Float.round(2 * score / divisor / han_fu_rounding_factor) * han_fu_rounding_factor)
    # oya_payment is only relevant if is_dealer is false
    # (it is just double ko payment if is_dealer is true, which is useless)
    {ko_payment, oya_payment}
  end

  def test_tiles(hand, tiles, tile_behavior) do
    not Enum.empty?(Match.try_remove_all_tiles(hand, tiles, tile_behavior))
  end

  def get_disconnected_tiles(hand, tile_behavior) do
    hand
    |> Enum.uniq()
    |> Enum.filter(fn tile ->
      cond do
        Utils.count_tiles(hand, [tile], tile_behavior) >= 2 -> false
        Utils.count_tiles(hand, [Utils.strip_attrs(tile)], tile_behavior) >= 2 -> false
        is_jihai?(tile) -> true
        true ->
          past_suji_left = test_tiles(hand, [Match.offset_tile(tile, -4, tile_behavior), tile], tile_behavior)
          suji_left = test_tiles(hand, [Match.offset_tile(tile, -3, tile_behavior), tile], tile_behavior)
          jump_left = test_tiles(hand, [Match.offset_tile(tile, -2, tile_behavior), tile], tile_behavior)
          adjacent_left = test_tiles(hand, [Match.offset_tile(tile, -1, tile_behavior), tile], tile_behavior)
          adjacent_right = test_tiles(hand, [Match.offset_tile(tile, 1, tile_behavior), tile], tile_behavior)
          jump_right = test_tiles(hand, [Match.offset_tile(tile, 2, tile_behavior), tile], tile_behavior)
          suji_right = test_tiles(hand, [Match.offset_tile(tile, 3, tile_behavior), tile], tile_behavior)
          past_suji_right = test_tiles(hand, [Match.offset_tile(tile, 4, tile_behavior), tile], tile_behavior)
          arr = [past_suji_left, suji_left, jump_left, adjacent_left, true, adjacent_right, jump_right, suji_right, past_suji_right]
          # IO.inspect({tile, arr})
          case arr do
            [_, _, false, false, _t, false, false, _, _] -> true
            [_, _, false, false, _t, _, _, true, false] -> true # 14 or 134 or 124 -> toss 1
            [false, true, _, _, _t, false, false, _, _] -> true # 69 or 679 or 689 -> toss 9
            # [_, _, _, _, _t, true, _, _, _] -> false
            _ -> false
          end
      end
    end)
    # |> IO.inspect(label: "result")
  end

  def get_centralness(tile) do
    cond do
      is_num?(tile, 1) -> 1
      is_num?(tile, 2) -> 2
      is_num?(tile, 3) -> 3
      is_num?(tile, 4) -> 4
      is_num?(tile, 5) -> 4
      is_num?(tile, 6) -> 4
      is_num?(tile, 7) -> 3
      is_num?(tile, 8) -> 2
      is_num?(tile, 9) -> 1
      is_num?(tile, 10) -> 1
      true             -> 0
    end
  end

  def genbutsu_to_suji(genbutsu, tile_behavior) do
    Enum.flat_map(genbutsu, &cond do
      Enum.any?([1,2,3], fn k -> is_num?(&1, k) end) -> if Match.offset_tile(&1, 6, tile_behavior) in genbutsu do [Match.offset_tile(&1, 3, tile_behavior)] else [] end
      Enum.any?([4,5,6], fn k -> is_num?(&1, k) end) -> [Match.offset_tile(&1, -3, tile_behavior), Match.offset_tile(&1, 3, tile_behavior)]
      Enum.any?([7,8,9], fn k -> is_num?(&1, k) end) -> if Match.offset_tile(&1, -6, tile_behavior) in genbutsu do [Match.offset_tile(&1, -3, tile_behavior)] else [] end
      true -> []
    end)
  end

  def prepend_group(hand, calls, winning_tiles, group, win_definitions, tile_behavior) do
    # return hand, but reordered so that all `group` are at the front (after existing prepended groups)
    # if no `group`s exist, return hand unchanged
    # hand is expected to be tenpai for N sets and a pair

    # split at the last :separator in hand
    # we will only arrange the contents of the hand after that
    ix = Enum.find_index(Enum.reverse(hand), & &1 == :separator)
    {prearranged, hand} = if ix == nil do {[], hand} else Enum.split(hand, length(hand) - ix) end
    prearranged_as_calls = prearranged
    |> Utils.split_on(:separator)
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.map(&{"", &1})
    calls = calls ++ prearranged_as_calls

    # add "dismantle_calls" in case `group` contains multiple sets
    win_definitions = Enum.map(win_definitions, &["dismantle_calls" | &1])

    Enum.flat_map(winning_tiles, fn winning_tile ->
      hand_groups = Match.extract_groups([winning_tile | hand], group, tile_behavior)

      # `hand_groups` is sorted starting with greatest number of groups
      # if we have {hand, [group1, group2, group3]} and it matches,
      # then {hand ++ group1, [group2, group3]} also obviously matches
      # use this to reduce the number of calls to `match_hand`

      # also, we want to remove a maximal number of groups that matches
      # so if we ever find a matching solution with e.g. 3 groups,
      # drop all `hand_groups` with less than 3 groups

      {hand_groups, _cache, _max_groups} = for {hand, groups} <- hand_groups, reduce: {[], [], 0} do
        # {return value, groups that match, the largest number of groups in cache}
        {acc, cache, max_groups} ->
          groups_set = MapSet.new(groups)
          num_groups = MapSet.size(groups_set)
          cond do
            # ignore if num of groups is less than highest seen so far
            num_groups < max_groups -> {acc, cache, max_groups}
            # check cache to see if a larger set of groups matched; if so, this obviously matches
            Enum.any?(cache, &MapSet.subset?(groups_set, &1)) -> {[{hand, groups} | acc], cache, max_groups}
            # otherwise call the match function to see if these groups match
            Match.match_hand(hand, calls ++ Enum.map(groups, &{"", &1}), win_definitions, tile_behavior) ->
              {[{hand, groups} | acc], [groups_set | cache], max(num_groups, max_groups)}
            true -> {acc, cache, max_groups}
          end
      end
      Enum.map(hand_groups, fn {hand, groups} -> {winning_tile, hand, groups} end)
    end)
    |> Enum.map(fn {winning_tile, hand, groups} ->
      groups = groups
      |> Enum.sort_by(fn [t | _] -> Constants.sort_value(t) end)
      |> Enum.map(& &1 ++ [:separator]) # add a spacing marker after each group
      |> Enum.concat()
      # delete last instance of winning tile
      prearranged ++ groups ++ hand
      |> Enum.reverse()
      |> List.delete(winning_tile)
      |> Enum.reverse()
    end)
    |> then(& &1 ++ [prearranged ++ hand]) # append original handm
  end
  def prepend_group_all(hands, calls, winning_tiles, group, win_definitions, tile_behavior) do
    hands = Enum.flat_map(hands, &prepend_group(&1, calls, winning_tiles, group, win_definitions, tile_behavior))
    if Enum.empty?(hands) do [] else
      num_ungrouped_tiles = Enum.map(hands, &Utils.split_on(&1, :separator) |> Enum.at(-1) |> length())
      min_ungrouped_tiles = Enum.min(num_ungrouped_tiles)
      hands
      |> Enum.zip(num_ungrouped_tiles)
      |> Enum.filter(fn {_hand, num} -> num == min_ungrouped_tiles end)
      |> Enum.map(fn {hand, _num} -> hand end)
    end
  end

end
