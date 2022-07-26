defmodule IslandsEngine.IslandSet do
  alias IslandsEngine.{Island, IslandSet}

  defstruct atoll: :none, dot: :none, l_shape: :none, s_shape: :none, square: :none

  def start_link() do
    Agent.start_link(fn -> initialized_set() end
    )
  end


  # Loops through all struct keys
  # Creates an island agent for each type of island set key
  # * Each island has a list of coordinates

  defp initialized_set() do
    Enum.reduce(keys(), %IslandSet{}, fn key, set ->
      {:ok, island} = Island.start_link
      Map.put(set, key, island)
    end)


  end


  # Extracts keys from the island_set struct

  defp keys()do
    %IslandSet{}
    |> Map.from_struct
    |> Map.keys
  end



  # Fetches the state of each type of island in the island_set struct by
  # looping through all the keys in the struct. Since each value at the key
  # is an island agent, we use the Island.to_string to get all the coordinates
  # of that specific island guided by the keys we are looping through


  defp string_body(island_set) do
    Enum.reduce(keys(), "", fn key, acc ->
      island = Agent.get(island_set, &(Map.fetch!(&1, key)))
      acc <> "#{key} => " <> Island.to_string(island) <> "\n"
    end)
  end

  def to_string(island_set)do
    "%IslandSet{" <> string_body(island_set) <>"}"
  end

end
