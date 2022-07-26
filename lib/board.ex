defmodule IslandsEngine.Board do

  alias IslandsEngine.Coordinate

  @letters ~W(a b c d e f g h i j)
  @numbers [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

  def start_link do
    Agent.start_link(fn -> initialized_board() end)
  end

  defp keys() do
    #Nested loop(comprehension)
    for letter <- @letters, number <- @numbers do
      String.to_atom("#{letter}#{number}")
    end
  end


  defp initialized_board() do
    Enum.reduce(keys(), %{}, fn(key, board) ->
      {:ok, coord} = Coordinate.start_link
      Map.put_new(board, key, coord)
    end)
  end


  def get_coordinate(board, key) when is_atom key do
    Agent.get(board, fn board -> board[key] end)
  end

  @doc"""
  Gets the coordinate PID from the state board and changes its guessed value
  """
  def guess_coordinate(board, key) do
    get_coordinate(board, key)
    |> Coordinate.guess
  end



  @doc"""
  Checks whether a coordinate has been hit
  1. Gets a coordinate from the board state
  2. Calls internal coordinate function to check if it's been hit
  """
  def set_coordinate_in_island(board, key, island) do
    get_coordinate(board, key)
    |> Coordinate.set_in_island(island)
  end

  @doc"""
  Get the island of a coordinate
  """
  def coordinate_island(board, key) do
    get_coordinate(board, key)
    |> Coordinate.island
  end

  @doc"""
  Converts the board to a string
  """
  def to_string(board)do
    "%{" <> string_body(board) <> "}"
  end

  @doc"""
  Loops through all coordinates in the board, gets each coordinate state the converts it to a string
  """
  defp string_body(board) do
    Enum.reduce(keys(), "", fn key, acc ->
      coord =  get_coordinate(board, key)
      #Appends a new coordinate
      acc <> "#{key} => #{Coordinate.to_string(coord)},\n"
    end)
  end

end
