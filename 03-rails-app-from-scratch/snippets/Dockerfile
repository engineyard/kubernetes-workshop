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
RUN bundle install --deployment

# Copy code from working directory outside Docker to working directory inside Docker
COPY . .
#Sometime an extra bundle call is needed to install binaries / native extensions
RUN bundle install --deployment

# The default command to start the Unicorn server.
CMD bundle exec puma -p 5000
