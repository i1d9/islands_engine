defmodule IslandsInterfaceWeb.GameChannel do
  use IslandsInterfaceWeb, :channel
  alias IslandsInterfaceWeb.Presence

  @impl true
  def join("game:" <> _player, %{"screen_name" => screen_name}, socket) do
    if authorized?(socket, screen_name)  do
      send(self(), {:after_join, screen_name})
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end


  def handle_info({:after_join, screen_name}, socket) do
    {:ok, _} = Presence.track(socket, screen_name, %{
      online_at: inspect(System.system_time(:seconds))
    })
    {:noreply, socket}
  end

  def handle_in("show_subscribers", _payload, socket) do
    broadcast! socket, "subscribers", Presence.list(socket)
    {:noreply, socket}
  end

  def handle_in("new_game", _payload, socket) do
    "game:" <> player = socket.topic
    case Game.start_link(player) do
      {:ok, _pid} ->
        {:reply, :ok, socket}
      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  def handle_in("add_player", player, socket) do
    case Game.add_player(via(socket.topic), player) do
      :ok ->
        broadcast! socket, "player_added", %{message:
        "New player just joined: " <> player}
        {:noreply, socket}
      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end
  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (game:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  @doc"""
  Handle the hello event from the client
  """
  @impl true
  def handle_in("hello", payload, socket) do
    broadcast! socket, "said_hello", payload
    {:noreply, socket}
  end


  def handle_in("set_island_coordinates", payload, socket)do
    %{"player" => player, "island" => island, "coordinate"=> coordinates} =payload
    player = String.to_atom(player)
    island = String.to_atom(island)

    coordinates = Enum.map(coordinates, fn coord -> String.to_atom(coord) end)

    case Game.set_island_coordinates({:global, socket.topic}, player, island, coordinates)do
      :ok -> {:reply, :ok, socket}
      :error -> {:reply, :error, socket}
    end
  end

  def handle_in("set_islands", player, socket) do
    player = String.to_atom(player)
    case Game.set_islands({:global, socket.topic}, player) do
      :ok ->
        broadcast! socket, "player_set_islands", %{player: player}
        {:noreply, socket}
      :error -> {:reply, :error, socket}
    end
  end


  def handle_in("guess_coordinate", params, socket) do
    %{"player" => player, "coordinate"=> coordinate} = params
    coordinate = String.to_atom(coordinate)

    case Game.guess_coordinate({:global, socket.topic}, player, coordinate) do
      {:hit, island, win} ->
        result = %{hit: true, island: island, win: win}
        broadcast! socket, "player_guessed_coordinate", %{player: player, result: result}
        {:noreply, socket}
      {:miss, island, win} ->
        result = %{hit: false, island: island, win: win}
        broadcast! socket, "player_guessed_coordinate", %{player: player, result: result}
        {:noreply, socket}
      {:error, reason} -> {:reply, {:error, %{player: player, reason: reason}}, socket}
    end
  end

  defp authorized?(socket, screen_name) do
    number_of_players(socket) < 2 && !existing_player?(socket, screen_name)
  end

  defp existing_player?(socket, screen_name) do
    socket
    |> Presence.list()
    |> Map.has_key?(screen_name)
  end

  defp number_of_players(socket) do
    socket
    |> Presence.list()
    |> Map.keys()
    |> length()
  end

  defp via("game:" <> player), do: Game.via_tuple(player)
end
