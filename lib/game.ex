defmodule IslandsEngine.Game do
  use GenServer


  alias IslandsEngine.{Game, Player, Rules}
  defstruct player1: :none, player2: :none, fsm: :none

  def start_link(name)
  when is_binary(name) and byte_size(name) > 0,
    do: GenServer.start_link(__MODULE__, name, name: {:global, "game:#{name}"})

  def init(name) do
      {:ok, player1} = Player.start_link(name)
      {:ok, player2} = Player.start_link()
      {:ok, fsm} = Rules.start_link
      {:ok, %Game{player1: player1, player2: player2}}

  end



  def state(server),
    do: GenServer.call(server, :state)

  def add_player(server, name)
  when not is_nil(name),
    do: GenServer.call(server, {:add_player, name})

  def set_island_coordinates(server, player, island, coordinates)
  when is_atom(island) and is_atom(player),
    do: GenServer.call(server, {:set_island_coordinates, player, island, coordinates})

  def guess_coordinate(server, player, coordinate)
  when is_atom(player) and is_atom(coordinate),
    do: GenServer.call(server, {:guess, player, coordinate})




  def handle_call({:add_player, name}, _from, state) do
    Rules.add_player(state.fsm)
    |> add_player_reply(state, name)
  end


  def handle_call({:set_island_coordinates, player, island, coordinates}, _from, state) do

    Rules.move_island(state.fsm, player)
    |> set_island_coordinates_reply(player, island, coordinates, state)


  end


  def handle_call({:guess, player, coordinate}, _from, state) do
    opponent = opponent(state, player)
    Player.guess_coordinate(opponent.board, coordinate)
    |> forest_check(opponent, coordinate)
    |> win_check(opponent, state)
  end

  def handle_call({:set_islands, player}, _from, state) do
    reply = Rules.set_islands(state.fsm, player)
    {:reply, reply, state}
  end

  @doc"""
  if the rule fsm replies with :ok, the guess can be made and the response is returned
  """
  def handle_call({:guess, player, coordinate}, _from, state) do
    opponent = opponent(state, player)
    Rules.guess_coordinate(state.fsm, player)
    |> guess_reply(opponent.board, coordinate)
    |> forest_check(opponent, coordinate)
    |> win_check(opponent, state)
  end



  defp guess_reply(:ok, opponent_board, coordinate)do
    Player.guess_coordinate(opponent_board, coordinate)
  end

  defp guess_reply({:error, :action_out_of_sequence}, _opponent_board, _coordinate) do
    {:error, :action_out_of_sequence}
  end

  defp forest_check(:miss, _opponent, _coordinate) do
      {:miss, :none}
  end

  defp forest_check(:hit, opponent, coordinate) do
      island_key = Player.forested_island(opponent, coordinate)
      {:hit, island_key}
  end

  defp forest_check({:error, :action_out_of_sequence}, _opponent_board, _coordinate) do
    {:error, :action_out_of_sequence}
  end

  defp win_check({hit_or_miss, :none}, _opponent, state) do
      {:reply, {hit_or_miss, :none, :no_win}, state}
  end

  defp win_check({:hit, island_key}, opponent, state) do
      win_status =
      case Player.win?(opponent) do
        true -> :win
        false -> :no_win
      end
      {:reply, {:hit, island_key, win_status}, state}
  end

  defp win_check({:error, :action_out_of_sequence}, _opponent_board, state) do
    {:reply, {:error, :action_out_of_sequence}, state}
  end


  defp opponent(state, :player1) do
    state.player2
  end

  defp opponent(state, _player2) do
    state.player1
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  defp add_player_reply(:ok, state, name) do
    Player.set_name(state.player2, name)
    {:reply, :ok, state}
  end

  defp add_player_reply(reply, state, _name) do
    {:reply, reply, state}
  end

  defp set_island_coordinates_reply(:ok, player, island, coordinates, state) do
    state
    |> Map.get(player)
    |> Player.set_island_coordinates(island, coordinates)
    {:reply, :ok, state}
  end

  defp set_island_coordinates_reply(reply, _player, _island, _coordinates, state) do
    {:reply, reply, state}
  end



  def set_islands(pid, player) when is_atom player do
    GenServer.call(pid, {:set_islands, player})
  end

end
