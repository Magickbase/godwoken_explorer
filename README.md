# Godwoken Explorer

> This project is still under development

Godwoken Explorer is design for display [godwoken](https://github.com/nervosnetwork/godwoken)(A CKB layer2 roll up solution) data.

## Requirements

- Erlang/OTP 23
- Elixir 1.11.x
- Postgresql 10.3+,11,12
- Rust

## Run local development
1. `$ mix ecto.setup`
2. Update `config/dev.per.exs` configuration
3. `$ mix phx.server`
4. Visit `http://localhost:4001`

## Deploy
[Deploy to Ubuntu](https://github.com/nervina-labs/godwoken_explorer/blob/main/docs/deploy_to_ubuntu.md)
