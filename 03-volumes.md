# This tutorial covers

- Running PostgreSQL as a container on kubernetes and connecting it to your app.

# Prerequisites

- A Dockerized Rails app, ready to run on kubernetes (see: [Basic Rails App Tutorial](../01-basic-rails-app))

# Step by Step

## 1. Storage Class

      k create -f ~/kubernetes-workshop/k8s-manifests/01-db-storage-class.yaml
      k get storageclasses
      k describe storageclass/pg-pv

## 2. Volume Claim

      k create -f ~/kubernetes-workshop/k8s-manifests/02-db-volume-claim.yaml
      k get pvc
      k describe pvc/pg-pv-claim

## 3. Secret

      erb -r base64 -r securerandom ~/kubernetes-workshop/k8s-manifests/03-db-secret.yaml | kubectl create -f -
      k get secret/pg-db-secret -o jsonpath="{.data.postgres-password}" | base64 --decode

## 4. Deployment

      k create -f ~/kubernetes-workshop/k8s-manifests/04-db-deployment.yaml

Verify with:

      k get pods

      NAME                              READY     STATUS              RESTARTS   AGE
      ...
      pg-for-pg-rails-732073437-tln3r   0/1       ContainerCreating   0          22s

      k exec -it pg-for-pg-rails-732073437-tln3r bash

      root@pg-for-pg-rails-732073437-tw4vq:/# mount | grep post
      /dev/xvdba on /var/lib/postgresql/data type ext4 (rw,relatime,data=ordered)

## 5. DB Service

Create the service for the DB

      k create -f ~/kubernetes-workshop/k8s-manifests/05-db-service.yaml

Output the DB password (you'll need it again):

    k get secrets/pg-db-secret -o yaml | ruby -ryaml -rbase64 -e "YAML.load(STDIN)['data'].each{|k,v| puts [k, Base64.decode64(v)]}"

Go into a new container and connect to your running postgres (exposed via that service)

      k run debug -it --rm --image=postgres --restart=Never -- bin/bash
      $ psql -h pg-rails-service -U postgres

or connect via already running container

      k exec -it pg-for-pg-rails-732073437-tln3r bash

## 6. Consume DB Service from a Rails App

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

This manifest will make a new deployment using an app from an image that does this...

    k create -f ~/kubernetes-workshop/k8s-manifests/06-rails-app.yaml

And we can add it to our ingress with a service:

    k create service clusterip pg-rails --tcp=80:5000

And a ingress

    echo "apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: pg-rails
    spec:
      rules:
        #CAN use underscores but NO dashes
        - host: pg-rails.${ENV_NAME}.my.ey.io
          http:
            paths:
            - backend:
                serviceName: pg-rails
                servicePort: 80" | kubectl create -f -

Open in browser:

      echo pg-rails.${ENV_NAME}.my.ey.io

Still need to `rake db:create` and `rake db:migrate`

    k exec -it pg-rails-2356453321-vw36l bash

    bundle exec rake db:create
    bundle exec rake db:migrate
