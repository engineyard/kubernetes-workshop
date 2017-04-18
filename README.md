# Hello!

This repository represents a few of the things we wish we had time to teach you at our Railsconf workshop. However, we only have 90 minutes, so we'll just walkthrough one exercise together, and then step back and offer support as you explore the topics that interest you.

# Prerequisites

1. A Working Kubernetes Cluster. (Register for the eventbrite and we'll email you access instruction: https://www.eventbrite.com/e/kubernetes-workshop-test-run-tickets-33786217486)
2. A Docker Hub Account. (https://hub.docker.com/)
3. Join the #workshop-chat channel on the Kubernetes slack: http://slack.k8s.io/ (optional)
4. The ability to run SSH and a modern web browser

This material assumes your kubernetes cluster is running on Amazon EC2, backed by Engine Yard Managed Kubernetes.

Since we are running on conference wifi, and Docker can be bandwidth intensive, we are also giving you access to what we call a "bridge" box. This is a basic EC2 server you can SSH into. It has Ruby and Docker and other basic tools pre-installed. SSH instructions should be available on the Engine Yard dashboard once you get access to one of the accounts we've setup for this workshop.

Here's an overview of the pre-installed software you'll be using:

1. *ruby* - It's installed with RVM. (You are welcome to install other versions of ruby, see: https://rvm.io/rubies/installing)
2. *docker* - Will be needed to build and push images to Docker Hub. Kubernetes will then pull these images. (you'll need to prefix most docker command with `sudo`)
3. *kubey* - This is the Engine Yard CLI for provisioning and managing Kubernetes clusters on Amazon. Since your cluster is already setup, you'll only need the CLI to get info/status on the cluster or to setup RDS databases.
4. *kubectl* - This is the official kubernetes CLI, it's already setup to talk to your cluster. Here are some commands to try: `kubectl cluster-info` `kubectl get pods --all-namespaces` `kubectl describe service/nginx-ingress -n kube-system`
5. This repository (already cloned to ~/kubernetes-workshop)

# Getting Started

The building block of this workshop is the [Basic Rails App Tutorial](01-basic-rails-app)), the rest of these examples provide avenues of exploration into other aspects of kubernetes and concerns relevant to Ruby on Rails. (e.g [Containerized Database](02-containerized-database))

# Further References

Feel free to take advantage of the provided kubernetes cluster to explore and run through any random tutorial you find on the internet. Here's a few places you could look:

* The official Kubernetes git repository examples: https://github.com/kubernetes/kubernetes/tree/master/examples
* An FAQ from somebody doing a lot of Kubernets stuff on AWS: https://github.com/hubt/kubernetes-faq
* A getting started on kubernetes course provided by Google: https://www.udacity.com/course/scalable-microservices-with-kubernetes--ud615
* Some slides from a kubernetes workshop at OSCON: http://Goo.gl/eexNMT


