defmodule IslandsInterfaceWeb.PageController do
  use IslandsInterfaceWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end


  def test(conn ,%{"name" => name})do
    {:ok, _pid} = IslandsEngine.Game.start_link(name)

    conn
    |> put_flash(:info, "You entered the name: "<> name)
    |> render("index.html")
  end
end
