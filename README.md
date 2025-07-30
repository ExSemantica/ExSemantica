# exsemantica

An open-source link aggregator.

## How to use this?

### Developing

The database is a PostgreSQL storage. You can use Docker (or Podman) to run it.

```shell
$ docker run -p 5432:5432 --name exsemantica-postgres -e POSTGRES_PASSWORD=postgres -d postgres:alpine
```

The PostgreSQL database should be initialized in first use.

```shell
$ mix ecto.reset
```

Start the backend API and other services.

```shell
$ iex -S mix
```

#### Creating and logging in as a user

Create the example user

```elixir
iex> Exsemantica.Administration.User.create("example", "Example User", "test_password", "user@example.com", "I'm a test user and this is my biography.")
```

More information should be added here.

### Deploying

TODO
