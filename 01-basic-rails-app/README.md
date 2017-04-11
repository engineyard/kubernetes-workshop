# This tutorial covers

- Dockerize a Rails 5 app with Postgres
- Deploying the app to a running kubernetes cluster
- Connecting to externally configured Database (using Amazon RDS)
- Connecting to a Database running on another container inside kubernetes
- rake db:migrate

## Kubernetes concepts:

- Pods
- Deployments
- Services (specifically ELB-backed ones)
- Secrets

## Not covered (but probably of interest):

- asset precompile w/ nginx serving static assets, See example: *TODO*
- exposing your app by domain-prefix (using built-in `nginx-ingress`), See example: *TODO*

# Step by Step

## 1. `rails new`

    rails new pg-rails

Or you can probably use an existing rails app. Or you can use this one: https://github.com/jacobo/pg-rails which already has these next few steps completed.

We'll be using postgres as the database and unicorn as the app server, so make sure they are in your Gemfile (`vi Gemfile`):

    gem 'pg'
    gem 'unicorn'

Now do something that would require a database, and respond on "/". (Be creative, or copy directly from this example).

like a model:

    bundle exec rails generate model HitCounter
    cp ../kubernetes-workshop/01-basic-rails-app/snippets/hit_counter.rb app/models/hit_counter.rb

and a controller :

    bundle exec rails generate controller Slash
    cp ../kubernetes-workshop/01-basic-rails-app/snippets/slash_controller.rb app/controllers/slash_controller.rb

and a route would be nice (`vi config/routes.rb`):

    cp ../kubernetes-workshop/01-basic-rails-app/snippets/routes.rb config/routes.rb

## 1.5 Optional Detour: test run with unicorn

You should be able to run your app locally with:

    bundle exec unicorn -p 5000

If you were doing this on your local dev machine you'd pop open a browser and visit localhost:5000,
but since you are doing this on the "bridge" box you'll need to point your browser at the amazon public hostname plus port 5000.

NOTE: the clusters setup for this workshop have been intentionally "opened-up" to have all ports open to the world so we can debug and inspect, but this is not recommended for production.

## 2. Dockerfile

Our app will run inside a container, so we need a Dockerfile that defines how to setup it's OS-level dependencies and ends with what command to run (`bundle exec unicorn`)

    vi Dockerfile

Here's a basic one:

    #The base image, with ruby pre-installed
    #see: https://hub.docker.com/_/ruby/
    FROM ruby:2.3

    # Install dependencies:
    # - build-essential: To ensure certain gems can be compiled
    # - nodejs: Compile assets
    # - libpq-dev: Communicate with postgres through the postgres gem
    # - postgresql-client-9.4: In case you want to talk directly to postgres
    RUN apt-get update && apt-get install -qq -y build-essential nodejs libpq-dev postgresql-client-9.4 --fix-missing --no-install-recommends

    # Set an environment variable to store where the app is installed to inside
    # of the Docker image.
    ENV INSTALL_PATH /app
    RUN mkdir -p $INSTALL_PATH

    # This sets the context of where commands will be ran in and is documented
    # on Docker's website extensively.
    WORKDIR $INSTALL_PATH

    # Ensure gems are cached and only get updated when they change. This will
    # drastically increase build times when your gems do not change.
    COPY Gemfile Gemfile
    RUN bundle install

    # Copy code from working directory outside Docker to working directory inside Docker
    COPY . .
    #This extra bundle call is needed to avoid
    RUN bundle

    # The default command to start the Unicorn server.
    CMD bundle exec unicorn -p 5000

Next we'll build the docker image for your app.

**IMPORTANT** This is the step where you want to make sure you are not consuming conference bandwidth. If you have been developing you app locally and not the "bridge" box, now is the time to push it up there. Building and pushing docker images consumes significant bandwidth, but if we do it while SSH'd into our "bridge" box we're consuming bandwith on Amazon EC2 instead of locally.

Connect Docker daemon to docker hub using the `login` command:

    sudo docker login

Replace `jacobo` in these next few commands with your account name on Docker hub (hub.docker.com), and `myapp` with the name of your rails app.

Build a docker image and tag it:

    sudo docker build -t jacobo/myapp .

Push the tagged image to docker hub:

    sudo docker push jacobo/myapp

## 2.5 Optional Detour: test run with docker

You should be able to run your app locally inside docker with:

    sudo docker run -d -p 5000:5000 jacobo/myapp

## 3 Deploy on Kubernetes

Warning: we didn't setup the database yet, so we expect this to fail... That's ok

TODO

Can test with `k run`

    k run -it checkurl2 --rm --image=busybox --rm

    env
    wget -qO- http://10.254.78.173
      (because DD_NO_DB_RAILS_SERVICE_HOST=10.254.78.173)
    wget -qO- http://dd-no-db-rails
      (because kubedns)
    wget -qO- http://nodbrails.jacob1.my.ey.io
      WHY DOESN'T THIS WORK when inside a pod???

## 4 Connect to RDS

TODO

## 5 Setup a container Database and connect to that instead

TODO

Requires database.yml

