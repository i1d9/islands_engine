defmodule IslandsEngine.Rules do
  @behaviour :gen_statem

  alias IslandsEngine.Rules

  defstruct player1: :islands_not_set, player2: :islands_not_set

  # Client Functions

  def start_link do
    :gen_statem.start_link(__MODULE__, :ok, [])
  end

  @doc"""
  After the game has been intialized the next state is to add a player into the game
  """
  def add_player(fsm) do
    :gen_statem.call(fsm, :add_player)
  end

  @doc"""
  Once a player has joined the game they should be able to move their islands in the game
  If player1 has moved their island and their opponent(player2) hasn't, player1 should not be able to modify
  When this condition exists the machine should remain in :players_set state

  The second player setting their island should trigger movement to the next state
  """
  def move_island(fsm, player) when is_atom player do
    :gen_statem.call(fsm, {:move_island, player})
  end

  @doc""""
  Handles island setting when the game is in the :players_set state
  """
  def set_islands(fsm, player) when is_atom player do
    :gen_statem.call(fsm, {:set_islands, player})
  end

  @doc"""
  Initiates state changes between player1_turn and player2_turn
  """
  def guess_coordinate(fsm, player) when is_atom player do
    :gen_statem.call(fsm, {:guess_coordinate, player})
  end

  def win(fsm) do
    :gen_statem.call(fsm, :win)
  end

  def show_current_state(fsm) do
    :gen_statem.call(fsm, :show_current_state)
  end

  # Callbacks

  @doc"""
  Initial State
  """
  def init(:ok) do
    {:ok, :initialized, %Rules{}}
  end

  def callback_mode(), do: :state_functions

  def code_change(_vsn, state_name, state_data, _extra) do
    {:ok, state_name, state_data}
  end

  def terminate(_reason, _state, _data), do: :nothing

  @doc"""
  Defines a rule for the initialized state
  :add_player is the event name
  state_data is the current state values which was defined in init/1

  Returns :ok but to the sender meaning that it is fine to add a new player
  The next state is the :players_set

  called when the state machine is at :intialized and wants to proceed to :players_set
  """
  def initialized({:call, from}, :add_player, state_data) do
    {:next_state, :players_set, state_data, {:reply, from, :ok}}
  end

  def initialized({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :initialized}}
  end

  @doc"""
  Match any other undefined event
  """
  def initialized({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  @doc"""
  Checking the state_data which is the struct %Rule{
    player1: :islands_not_set,
    player2: :islands_not_set
  }

  Pass the player atom in the second param to check if they've set their islands
  """
  def players_set({:call, from}, {:move_island, player}, state_data) do
    case Map.get(state_data, player) do
      :islands_not_set ->
        {:keep_state_and_data, {:reply, from, :ok}}
      :islands_set ->
        {:keep_state_and_data, {:reply, from, :error}}
    end
  end

  @doc"""
  Update the struct %Rules{} with a key that matches the player atom and set its value to :island_set
  Sends a reply to the caller process
  """
  def players_set({:call, from}, {:set_islands, player}, state_data) do
    state_data = Map.put(state_data, player, :islands_set)
    set_islands_reply(from, state_data, state_data.player1, state_data.player2)
  end

  @doc"""
  Shows the current state_data if the state machine is inthe players_set state
  """
  def players_set({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :players_set}}
  end

  @doc""""
  Catch errors
  """
  def players_set({:call, from}, _, state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  @doc""""
  If the reply is :ok it is player2's turn to guess coordinates
  """
  def player1_turn({:call, from}, {:guess_coordinate, :player1}, state_data) do
    {:next_state, :player2_turn, state_data, {:reply, from, :ok}}
  end

  @doc""""
  Ends the game if player1 has guessed all the coordinates in player2's board
  """
  def player1_turn({:call, from}, :win, state_data) do
    {:next_state, :game_over, state_data, {:reply, from, :ok}}
  end

  @doc""""
  Gets the current state_data in the player1_turn state
  """
  def player1_turn({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :player1_turn}}
  end

  @doc""""
  Catches all pattern mismatches
  """
  def player1_turn({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  @doc""""
  Changes the state to player1_turn if the reply is :ok
  """
  def player2_turn({:call, from}, {:guess_coordinate, :player2}, state_data) do
    {:next_state, :player1_turn, state_data, {:reply, from, :ok}}
  end

  @doc""""
  Ends the game if player2 has guessed all of player1's coordinates
  """
  def player2_turn({:call, from}, :win, state_data) do
    {:next_state, :game_over, state_data, {:reply, from, :ok}}
  end

  def player2_turn({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  def player2_turn({:call,from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :player2_turn}}
  end

  
  def game_over({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :game_over}}
  end

  @doc""""
  Returns an error if the player tries to do anything if the game has already ended
  """
  def game_over({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  @doc""""
  Matches if :player1 had already set theirs and the player2 has just finished setting
  Therefore inthe %Rule{} struct, :player1 and :player2 must be :islands_set
  If so change the state to :player1_turn which enables :player1 to start guessing
  """
  defp set_islands_reply(from, state_data, status, status)
       when status == :islands_set do
    {:next_state, :player1_turn, state_data, {:reply, from, :ok}}
  end

  @doc"""
  Matches if one of the players(probably :player1) has just finished setting their island
  and the other one has not set
  """
  defp set_islands_reply(from, state_data, _, _) do
    {:keep_state, state_data, {:reply, from, :ok}}
  end
end
