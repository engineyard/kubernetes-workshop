# This tutorial covers

- Running PostgreSQL as a container on kubernetes and connecting it to your app.

# Prerequisites

- A Dockerized Rails app, ready to run on kubernetes (see: [Basic Rails App Tutorial](../01-basic-rails-app))

Credit where due: These instructions were developed mostly by ripping off: https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd

# Step by Step

## 1. Storage Class

      k create -f ~/kubernetes-workshop/02-containerized-database/manifests/01-db-storage-class.yaml
      k get storageclasses
      k describe storageclass/pg-pv

## 2. Volume Claim

      k create -f ~/kubernetes-workshop/02-containerized-database/manifests/db-volume-claim.yaml
      k get pvc
      k describe pvc/pg-pv-claim

## 3. Secret

      erb -r base64 -r securerandom ~/kubernetes-workshop/02-containerized-database/manifests/db-secret.yaml | kubectl create -f -
      k get secret/pg-db-secret -o jsonpath="{.data.postgres-password}" | base64 --decode

## 4. Deployment

      k create -f ~/kubernetes-workshop/02-containerized-database/manifests/db-deployment.yaml

Verify with:

      root@pg-for-pg-rails-732073437-tw4vq:/# mount | grep post
      /dev/xvdba on /var/lib/postgresql/data type ext4 (rw,relatime,data=ordered)

## 5. DB Service

      k create -f ~/kubernetes-workshop/02-containerized-database/manifests/db-service.yaml

Go into a new container and connect to your running postgres

      k run debug -it --rm --image=postgres --restart=Never -- bin/bash
      $ psql -h pg-rails-service -U postgres

or connect via already running container

      k exec -it pg-for-pg-rails-732073437-db1nf bash

## 6. Consume DB Service from Rails App

Adjust `database.yml` to read from `DB_HOST` and `DB_PASSWORD` environment variables:

    <% if ENV['DATABASE_URL'].blank? %>
    production:
      # DB Service/Deployment provided by k8s will use shared secret (and become admin on the DB)
      <<: *default
      host: <%= ENV["DB_HOST"] %>
      user: postgres
      password: <%= ENV["DB_PASSWORD"] %>
      database: myapp_prod
    <% end %>

Adjust rails app deployment to remove `DATABASE_URL` and add `DB_HOST` and `DB_PASSWORD`.
Let's use a manifest file this time instead of our `ruby -e` hackery:

(NOTE: you may need to edit `rails-app.yaml` to make sure the names and labels match `k get deployments/myapp -o yaml`)

    k replace deployments/myapp -f ~/kubernetes-workshop/02-containerized-database/manifests/06-rails-app.yaml
