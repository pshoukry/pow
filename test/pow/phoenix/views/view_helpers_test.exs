defmodule PowTest.Phoenix.TestView do
  def render(_template, _opts), do: :ok
end
defmodule Pow.Test.Phoenix.PowTest.TestView do
  def render(_template, _opts), do: :ok
end
defmodule Pow.Phoenix.ViewHelpersTest do
  use Pow.Test.Phoenix.ConnCase
  doctest Pow.Phoenix.ViewHelpers

  alias Pow.Phoenix.ViewHelpers
  alias Pow.Test.Ecto.Users.User
  alias Plug.Conn

  setup %{conn: conn} do
    changeset   = User.changeset(%User{}, %{})
    action      = "/"
    conn =
      conn
      |> Map.put(:params, %{"_format" => "html"})
      |> Conn.put_private(:pow_config, [])
      |> Conn.put_private(:phoenix_endpoint, Pow.Test.Phoenix.Endpoint)
      |> Conn.put_private(:phoenix_view, Pow.Phoenix.SessionView)
      |> Conn.put_private(:phoenix_layout, {Pow.Phoenix.LayoutView, :app})
      |> Conn.put_private(:phoenix_router, Pow.Test.Phoenix.Router)
      |> Conn.assign(:changeset, changeset)
      |> Conn.assign(:action, action)

    {:ok, %{conn: conn}}
  end

  test "render/3", %{conn: conn} do
    conn = ViewHelpers.render(conn, :new)

    assert conn.private[:phoenix_endpoint] == Pow.Test.Phoenix.Endpoint
    assert conn.private[:phoenix_view] == Pow.Phoenix.SessionView
    assert conn.private[:phoenix_layout] == {Pow.Test.Phoenix.LayoutView, :app}
  end

  test "render/3 with :web_module", %{conn: conn} do
    conn =
      conn
      |> Conn.put_private(:pow_config, [web_module: Pow.Test.Phoenix])
      |> ViewHelpers.render(:new)

    assert conn.private[:phoenix_endpoint] == Pow.Test.Phoenix.Endpoint
    assert conn.private[:phoenix_view] == Pow.Test.Phoenix.Pow.SessionView
    assert conn.private[:phoenix_layout] == {Pow.Test.Phoenix.LayoutView, :app}
  end

  test "render/3 in extension", %{conn: conn} do
    conn =
      conn
      |> Conn.put_private(:phoenix_view, PowTest.Phoenix.TestView)
      |> ViewHelpers.render(:new)

    assert conn.private[:phoenix_endpoint] == Pow.Test.Phoenix.Endpoint
    assert conn.private[:phoenix_view] == PowTest.Phoenix.TestView
    assert conn.private[:phoenix_layout] == {Pow.Test.Phoenix.LayoutView, :app}
  end

  test "render/3 in extension with :web_module", %{conn: conn} do
    conn =
      conn
      |> Conn.put_private(:phoenix_view, PowTest.Phoenix.TestView)
      |> Conn.put_private(:pow_config, [web_module: Pow.Test.Phoenix])
      |> ViewHelpers.render(:new)

    assert conn.private[:phoenix_endpoint] == Pow.Test.Phoenix.Endpoint
    assert conn.private[:phoenix_view] == Pow.Test.Phoenix.PowTest.TestView
    assert conn.private[:phoenix_layout] == {Pow.Test.Phoenix.LayoutView, :app}
  end
end
