# config valid for current version and patch releases of Capistrano
lock "~> 3.16.0"

load File.expand_path("../deploy/tasks/buildhost.rake", __FILE__)
load File.expand_path("../deploy/tasks/node.rake", __FILE__)

set :application, "godwoken_explorer"
set :repo_url, "git@github.com:nervina-labs/godwoken_explorer.git"

set :deploy_user, 'ckb'
set :deploy_to, "/home/#{fetch(:deploy_user)}/godwoken_explorer/app"
set :ssh_options, user: 'ckb', verify_host_key: :always
set :default_env, {path: "/home/ckb/.cargo/bin:$PATH"}

set :build_path, "/home/#{fetch(:deploy_user)}/godwoken_explorer/build"
set :repo_path, "/home/#{fetch(:deploy_user)}/godwoken_explorer/repo"
set :app_path, "/home/#{fetch(:deploy_user)}/godwoken_explorer/app"

set :linked_dirs, ["config"]

task "build:hot" => [
  "buildhost:prepare_build_path",
  "buildhost:compile",
  "buildhost:mix:release:upgrade",
  "node:archive:dist",
  "node:migrate"
]

task "build:cold" => [
  "buildhost:prepare_build_path",
  "buildhost:compile",
  "buildhost:mix:release",
  "node:archive:dist",
  "node:migrate"
]

task "deploy:restart" => [
  "build:cold",
  "node:full_restart"
]

task "deploy:upgrade" => [
  "build:hot",
  "node:upgrade",
]