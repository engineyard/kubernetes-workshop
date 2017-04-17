# This tutorial covers

- Running PostgreSQL as a container on kubernetes and connecting it to your app.

# Prerequisites

- A Dockerized Rails app, ready to run on kubernetes (see: [Basic Rails App Tutorial](../01-basic-rails-app/README.md))

Credit where due: These instructions were developed mostly by ripping off: https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd

# Step by Step

## Create a secret for the root password