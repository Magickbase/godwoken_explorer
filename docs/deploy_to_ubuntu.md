
# Deploy To Ubuntu 20.04.2

## Server Requirement

### STEP 1: Install Elixir

```
$ wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && sudo dpkg -i erlang-solutions_2.0_all.deb
$ sudo apt-get update
$ sudo apt-get install esl-erlang
$ sudo apt-get install elixir
```

### STEP 2: Install PostgreSQL

```
$ sudo apt-get install wget ca-certificates
$ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
$ sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
$ sudo apt-get update
$ sudo apt-get install postgresql postgresql-contrib
```

### STEP 3. Install Rust

```
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Use Deploy Command

### STEP 1: Generate Directroy
> At local machine

```
$ bundle exec cap staging deploy:check
$ bundle exec cap staging buildhost:prepare_build_path
```

### STEP 2: Generate Secret Key
> At remote server

```
$ cd ~/godwoken_explorer/build
$ mix do local.hex, deps.get, local.rebar --force
$ mix phx.gen.secret
```

### STEP 3: Config confirguration
> At remote server

1. Create `~/godwoken_explorer/app/share/config/#{MIX_ENV}.secret.exs`
2. Copy config/dev.per.exs content to secret.exs and update them to your own
3. Add under code to secret.exs file
```
  config :godwoken_explorer, GodwokenExplorerWeb.Endpoint,
  secret_key_base: #{GENERATED SECRET_KEY FROM STEP 2}
```
### STEP 4: Setup Database
> At remote server

```
$ cd ~/godwoken_explorer/build
$ ln -sfT ~/godwoken_explorer/app/shared/config/staging.secret.exs  config/staging.secret.exs
$ MIX_ENV=staging mix ecto.setup
```

### STEP 5: Deploy and Run
> At local machine

- use current version

```
$ bundle exec cap staging deploy:restart
```

- upgrade version
```
1. Update `mix.exs` version number
2. `$ bundle exec cap staging deploy:upgrade`
```