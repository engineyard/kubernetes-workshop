# This tutorial covers

- Dockerize a Rails 5 app with Postgres
- Deploying the app to a running kubernetes cluster
- Connecting to externally configured Database (using Amazon RDS)
- Connecting to a Database running on another container inside kubernetes
- rake db:migrate

# Step by Step

## 1. `rails new`

Or you can probably use an existing rails app, as long as it doesn't have too many dependencies. Or you can use this one if you want to skip ahead: https://github.com/jacobo/pg-rails

    rails new myapp

## 2. Dockerfile

    vi Dockerfile

  (esc, :set paste, command-V from: [Dockefile](../examples/Dockerfile))