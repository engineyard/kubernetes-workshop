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

We'll be using postgres as the database and unicorn as the app server, so make sure they are in your `Gemfile`:

    gem 'pg'
    gem 'unicorn'

Now do something that would require a database, and respond on "/". (Be creative, or copy directly from this example).

like a model:

    class HitCounter < ApplicationRecord

      def self.counter
        @counter ||= first || create!(hits: 0)
      end

      def self.hit!
        counter.update(hits: hits + 1)
      end

      def self.hits
        counter.hits
      end

    end

and a controller:

    class SlashController < ApplicationController

      def index
        HitCounter.hit!
        render json: {"Hit Count" => HitCounter.hits}
      end
    end

and a route would be nice:

    get "/",  :to => "slash#index", :as => :slash

## 1.5 Detour:

You should be able to run your app locally with:

    bundle exec rails server

If you were doing this on your local dev machine you'd pop open a browser and visit localhost:3000,
but since you are doing this on the "bridge" box you'll need to point your browser at the amazon public hostname plus port 3000.

NOTE: this will NOT work on other machines in your kubernetes cluster which have ports locked down for security reasons, we made a special exemption when we setup your "bridge"
TODO: ^ make this true.

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

Now let's build the image:


## 2.5 Detour:

You should be able to run your app locally inside docker with:

    docker run pg-rails

TODO: test this, elaborate

## 3 Deploy on Kubernetes

Warning: we didn't setup the database yet, so we expect this to fail... That's ok

TODO

## 4 Connect to RDS

TODO

## 5 Setup a container Database and connect to that instead

TODO

