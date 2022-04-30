# exsemantica

Open-source microblogging for people with mutual interests.

## Guidance

Builds upon [the previous eactivitypub][eactivitypub] repository.
This is a mix of incomplete pieces `v0.7` (a Phoenix 1.5 monolithic codebase) and `v0.8` (using Mnesia).
Together these make a great concept for a simple, reliable social platform at edge.
This is what I see and hope in `v0.9`, but failure is okay.

## How to use this?

If you want to fetch packages for frontend, use NodeJS NPM in `assets/` to use Alpine.JS
```shell
$ npm install alpinejs
```

You need PostgreSQL for these builds of ExSemantica. You might be able to
dockerize this.

Test in dev...
```shell
$ docker run -e POSTGRES_PASSWORD=postgres --rm -it  -p 5432:5432/tcp postgres:14-alpine
$ mix ecto.create
$ mix ecto.migrate
```

[eactivitypub]: https://github.com/Chlorophytus/eactivitypub-legacy-0.2
