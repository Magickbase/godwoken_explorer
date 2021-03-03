## Requirements
- Erlang/OTP 23
- Elixir 1.11.x
- Postgresql 10.3+,11,12
- Ruby 2.x and above
- Rust

## Run development
1. `$ mix ecto.setup`
2. Update `config/dev.per.exs` configuration
3. `$ mix phx.server`
4. Visit `http://localhost:4001`

## Deploy

> use capaistrano + distillery

#### Init deploy
1. `$ bundle exec cap staging deploy:check`
2. create "#{app_path}/share/config/#{MIX_ENV}.secret.exs in your server
2. `$ bundle exec cap staging deploy:restart`

#### Upgrade version
1. Update `mix.exs` version number
2. `$ bundle exec cap staging deploy:upgrade`
