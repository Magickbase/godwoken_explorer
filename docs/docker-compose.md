### Docker Compose
1. git clone the project
2. [edit your custom docker environment file](./docker_compose/envs/.env)
3. use docker-compose to build the container(work in project root dir)
`docker-compose --env-file ./docker_compose/envs/[your_custom_env_file].env -f ./docker_compose/gwscan_compose.yml build gwscan`
4. use docker-compose running the container(work in project root dir)
`docker-compose --env-file ./docker_compose/envs/[your_custom_env_file].env -f ./docker_compose/gwscan_compose.yml up -d gwscan`
