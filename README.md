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
iex> Exsemantica.Administration.User.create("example", "test_password", "user@example.com", "I'm a tester")
```

If the JSON response's `e` is `"OK"`, then you have successfully logged in and that token is valid.

### Deploying

TODO

[eactivitypub]: https://github.com/Chlorophytus/eactivitypub-legacy-0.2
