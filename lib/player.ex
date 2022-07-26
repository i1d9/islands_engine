defmodule IslandsEngine.Player do

  alias IslandsEngine.{IslandSet,Board, Coordinate, Player}
  defstruct name: :none, board: :none, island_set: :none

  @doc"""
  Links a player to a board, island set and sets their name
  """
  def start_link(name \\ :none) do
    {:ok, board} = Board.start_link
    {:ok, island_set} = IslandSet.start_link
    Agent.start_link(fn -> %Player{
      board: board,
      island_set: island_set,
      name: name
    } end)
  end

  @doc"""
  Sets the players name if it had not been initalized when the player agent was called
  """
  def set_name(player, name) do
    Agent.update(player, fn state -> Map.put(state, :name, name) end)
  end
end
