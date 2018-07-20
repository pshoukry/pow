# Pow

Pow is a powerful, modular, and extendable authentication and user management solution for Phoenix and Plug based apps.

## Features

* User registration
* Session based authorization
* Per Endpoint/Plug configuration
* Extendable
* I18n

## Installation

Add Pow to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    # ...
    {:pow, "~> 0.1"}
    # ...
  ]
end
```

Run `mix deps.get` to install it.

## Getting started

Install the necessary files:

```bash
mix pow.install
```

This will add the following files to your app:

```bash
LIB_PATH/pow.ex
LIB_PATH/users/user.ex
PRIV_PATH/repo/migrations/TIMESTAMP_create_user.ex
```

Add user and repo to `pow.ex`:

```elixir
defmodule MyApp.Pow do
  use Pow,
    user: MyApp.Users.User,
    repo: MyApp.Repo
end
```

Set up `endpoint.ex` to enable session based authentication:

```elixir
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # ...

  plug Plug.Session,
    store: :cookie,
    key: "_my_project_demo_key",
    signing_salt: "secret"

  plug MyApp.Pow.Plug.Session

  # ...
end
```

And add the Pow routes and plugs to `router.ex`:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use MyApp.Pow.Phoenix.Router

  # ...

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated
  end

  scope "/" do
    pipe_through :browser

    pow_routes()
  end

  # ...

  scope "/", MyAppWeb do
    pipe_through [:browser, :protected]

    # Protected routes ...
  end
end
```

That's it! Run `mix ecto.setup`, and you can now visit `http://localhost:4000/registrations/new`, and create a new user.

By default, Pow will only expose files that are absolutely necessary, but you can expose other files such as views and templates using the `mix pow.phoenix.install` command.

## Extensions

Pow is made so it's easy to extend the functionality with your own complimentary library. The following extensions are included in this library:

* `PowResetPassword`
* `PowEmailConfirmation`

Many extensions requires a mailer to have been set up. Let's create the mailer in `lib/my_app_web/mailer.ex` using [swoosh](https://github.com/swoosh/swoosh):

```elixir
defmodule MyAppWeb.Mailer do
  use Pow.Phoenix.Mailer
  use Swoosh.Mailer, otp_app: :my_app_web
  import Swoosh.Email

  def cast(%{user: user, subject: subject, text: text, html: html}) do
    new()
    |> to({"", user.email})
    |> from({"My App", "myapp@example.com"})
    |> subject(subject)
    |> html_body(html)
    |> text_body(text)
  end

  def process(email) do
    deliver(email)
  end
end
```

Update `lib/my_app/pow.ex` with the `:backend_mailer` key, and any extensions you wish to enable:

```elixir
defmodule MyApp.Pow do
  use Pow,
    user: MyApp.Users.User,
    repo: MyApp.Repo,
    backend_mailer: MyAppWeb.Mailer,
    extensions: [PowResetPassword, PowEmailConfirmation]
end
```

To install any migration files for extensions, run the following:

```bash
mix pow.extension.ecto.gen.migrations --extension PowResetPassword
```

That's it!

## Configuration

Pow is build to be modular, and easy to configure. Configuration is primarily passed through method calls, and plug options and they will take priority over any environment configuration. This is ideal in case you've an umbrella app with multiple separate user domains.

### Module groups

Pow has three main groups of modules that each can used individually, or in conjunction with each other:

#### Pow.Plug

This group will handle the plug connection. The configuration will be assigned to `conn.private[:pow_config]` and passed through the controller to the users context module.

#### Pow.Ecto

This group contains all modules related to the Ecto based user schema and context. By default, Pow will use the `Pow.Ecto.Context` module for authenticating, creating, updating and deleting users. However, it's very simple to extend, or write your own user context. You can do this by setting the `:users_context` configuration key.

#### Pow.Phoenix

This contains the controllers, views and templates for Phoenix. Templates are not generated by default, instead compiled default templates will be used. You can choose to generate these by running `mix pow.phoenix.install --templates`.

### Pow.Extension

This module helps build extensions for Pow. There's two extension mix tasks to generate ecto migrations and phoenix templates.

```bash
mix pow.extension.ecto.gen.migrations
```

```bash
mix pow.extension.phoenix.gen.templates
```

### Authorization plug

Pow ships with a session plug module. You can easily switch it out with a different one. As an example, here's how you do that with [Guardian](https://github.com/ueberauth/guardian):

```elixir
defmodule MyAppWeb.Pow.Plug do
  use Pow.Plug.Base

  def fetch(conn, config) do
    MyApp.Guardian.Plug.current_resource(conn)
  end

  def create(conn, user, config) do
    MyApp.Guardian.Plug.sign_in(conn, user)
  end

  def delete(conn, config) do
    MyApp.Guardian.Plug.sign_out(conn)
  end
end

defmodule MyAppWeb.Endpoint do
  # ...

  plug MyAppWeb.Pow.Plug,
    repo: MyApp.Repo,
    user: MyApp.Users.User
end
```

### Changeset

The user module has a fallback `changeset/2` method. If you need to add custom validations, you can use the  `pow_changeset/2` method like this:

```elixir
defmodule MyApp.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  schema "users" do
    field :custom, :string

    pow_user_fields()

    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user
    |> pow_changeset(attrs)
    |> Ecto.Changeset.cast(attrs, [:custom])
    |> Ecto.Changeset.validate_required([:custom])
  end
end
```

## Plugs

### Pow.Plug.Session

Enables session based authorization. The user struct will be collected from an ETS table through a GenServer using a unique token generated for the session. The token will be reset every time the authorization level changes.

### Pow.Plug.RequireAuthenticated

By default, this will redirect the user to the log in page if the user hasn't been authenticated.

### Pow.Plug.RequireNotAuthenticated

By default, this will redirect the user to the front page if the user is already authenticated.
