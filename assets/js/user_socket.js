// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// Bring in Phoenix channels client library:
import { Socket } from "phoenix"

// And connect to the path in "lib/islands_interface_web/endpoint.ex". We pass the
// token for authentication. Read below how it should be used.
let socket = new Socket("/socket", { params: { token: window.userToken } })

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/islands_interface_web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/islands_interface_web/templates/layout/app.html.heex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/islands_interface_web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1_209_600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()

// Now that you are connected, you can join channels with a topic.
// Let's assume you have a channel with a topic named `room` and the
// subtopic is its id - in this case 42:
let channel = socket.channel("game:lobby", {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })



channel.push("hello", { message: "greeting" }).receive("ok", (response) => {
  console.log(response.message);
}).receive("error", (response) => {
  console.log("Unable to say hello to the channel")
});

channel.on("said_hello", response => {
  console.log("Returned Greeting:", response.message)
});

function new_channel(player, screen_name) {
  return socket.channel("game:" + player, { screen_name: screen_name });
}

function join(channel) {
  channel.join().receive("ok", response => {
    console.log("Joined successfully!", response)
  })
    .receive("error", response => {
      console.log("Unable to join", response)
    })
}

function new_game(channel) {
  channel.push("new_game")
    .receive("ok", response => {
      console.log("New Game!", response)
    })
    .receive("error", response => {
      console.log("Unable to start a new game.", response)
    })
}

function add_player(channel, player) {
  channel.push("add_player", player)
    .receive("error", response => {
      console.log("Unable to add new player: " + player, response)
    })
}

function set_island_coordinates(channel, player, island, coordinates) {
  params = { "player": player, "island": island, "coordinates": coordinates }
  channel.push("set_island_coordinates", params)
    .receive("ok", response => {
      console.log("New coordinates set!", response)
    })
    .receive("error", response => {
      console.log("Unable to set new coordinates.", response)
    })
}

function set_islands(channel, player) {
  channel.push("set_islands", player)
    .receive("error", response => {
      console.log("Unable to set islands for: " + player, response)
    })
}

function guess_coordinate(channel, player, coordinate) {
  params = { "player": player, "coordinate": coordinate }
  channel.push("guess_coordinate", params)
    .receive("error", response => {
      console.log("Unable to guess a coordinate: " + player, response)
    })
}

export default socket
