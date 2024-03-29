# Godwoken Explorer

> This project is still under development

[![Coverage Status](https://coveralls.io/repos/github/Magickbase/godwoken_explorer/badge.svg?branch=godwoken-v1-mainnet-prod)](https://coveralls.io/github/Magickbase/godwoken_explorer?branch=godwoken-v1-mainnet-prod)

Godwoken Explorer is designed for [godwoken](https://github.com/nervosnetwork/godwoken)(A CKB layer2 roll up solution).Current only support [polyjuice](https://github.com/nervosnetwork/godwoken-polyjuice).

Our dev chatroom [discord](https://discord.com/channels/956765352514183188/958261584004804650).

For technology infrastructure, this project is inspired by [blockscout](https://github.com/blockscout/blockscout).An open-source EVM blockchain explorer.
## Get Started
### Requirements

- Erlang/OTP 24
- Elixir 1.13.x
- Postgresql 10.3+,11,12
- Rust

### Run local development
1. copy [reference](https://github.com/Magickbase/godwoken_explorer/blob/godwoken-v1-mainnet-prod/docker_compose/envs/.env) to project root and rename `.env.dev` and `.env.test`
2. `$ mix ecto.setup`
3. `$ mix phx.server`
4. Visit `http://localhost:4001`

### Docker Compose
1. [Install Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. [Docker README](https://github.com/Magickbase/godwoken_explorer/blob/godwoken-v1-mainnet-prod/docs/docker-compose.md)

### Branch for godwoken version
godwoken-v1-mainnet-prod: godwoken v1 mainnet
godwoken-v1-testnet-prod: godwoken v1 testnet
main: godwoken v0 mainnet
develop: godwoken v0 testnet

### GraphQL API docs
[https://magickbase.github.io/gwscan-graphql-doc/](https://magickbase.github.io/gwscan-graphql-doc/)

### Contribute
Fork it and submit your PR!
