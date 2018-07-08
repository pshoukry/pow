defmodule Authex.Phoenix.ErrorHandlerTest do
  use ExUnit.Case
  doctest Authex

  alias Authex.Phoenix.ErrorHandler
  alias Phoenix.ConnTest
  alias Authex.Test.ConnHelpers

  setup do
    Application.put_env(:plug, :validate_header_keys_during_test, false)
    conn = :get
            |> ConnTest.build_conn("/")
            |> ConnHelpers.with_session()
            |> ConnTest.fetch_flash()

    {:ok, %{conn: conn}}
  end

  test "call/2 :not_autenticated", %{conn: conn} do
    conn = ErrorHandler.call(conn, :not_authenticated)

    assert ConnTest.redirected_to(conn) == "/"
    assert ConnTest.get_flash(conn, :error) == "You're not authenticated."
  end

  test "call/2 :already_authenticated", %{conn: conn} do
    conn = ErrorHandler.call(conn, :already_authenticated)

    assert ConnTest.redirected_to(conn) == "/"
    assert ConnTest.get_flash(conn, :error) == "You're already authenticated."
  end
end
