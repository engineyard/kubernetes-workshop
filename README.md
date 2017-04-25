# Hello!

Welcome to our Railsconf workshop repository. We'll walkthrough the [Setup](TODO) and 2 exercises together, with you following along on your own kubernetes cluster. ( [Pods & Services](TODO/01-pods-deployments-services.md) and  [Secrets & Environment Variables](TODO/02-secrets-environment-variables.md) ) Then we'll step back and offer support as you explore on your own.

You can walkthrough the [Volumes](TODO) exercise to deploy a containerized database, go straight into [Dockerizing an App](TODO) (and deploy it on kubernetes), OR investigate other topics (such as the [Topics warranting further investigation](#TODO) at the bottom of this file). If you discover something cool, please share! (in workshop chat, or via spontaneous euphoric vocal exclamation)

# Prerequisites

1. A Working Kubernetes Cluster. (Register for the eventbrite and we'll email you access instruction: http://ey.io/kubey)
2. A Docker Hub Account. (https://hub.docker.com/) (optional, helps you setup your own apps)
3. Join the #workshop-chat channel on the Kubernetes slack: http://slack.k8s.io/ (optional, helps you ask questions)
4. The ability to run SSH and a modern web browser

Your kubernetes cluster is running on Amazon EC2, backed by Engine Yard.

Since we are running on conference wifi, and Docker can be bandwidth intensive, we are also giving you access to what we call a "bridge" box. This is a basic EC2 server you can SSH into. It has Ruby and Docker and other basic tools pre-installed. SSH instructions should be available on the Engine Yard dashboard once you get access to one of the accounts we've setup for this workshop.

Here's some of the pre-installed software on your *bridge* box:

1. *ruby* - It's installed with RVM. (You are welcome to install other versions of ruby, see: https://rvm.io/rubies/installing)
2. *docker* - Will be needed to build and push images to Docker Hub. Kubernetes will then pull these images.
3. *kubectl* - This is the official kubernetes CLI, it's already setup to talk to your cluster. Here are some commands to try: `kubectl cluster-info` `kubectl get pods --all-namespaces` `kubectl describe service/nginx-ingress -n kube-system`
4. This repository (already cloned to ~/kubernetes-workshop)

# Further References

Feel free to take advantage of the provided kubernetes cluster to explore and run through any random tutorial you find on the internet. Here's a few places you could look:

* The official Kubernetes git repository examples: https://github.com/kubernetes/kubernetes/tree/master/examples
* An FAQ from somebody doing a lot of Kubernets stuff on AWS: https://github.com/hubt/kubernetes-faq
* A getting started on kubernetes course provided by Google: https://www.udacity.com/course/scalable-microservices-with-kubernetes--ud615
* Some slides from a kubernetes workshop at OSCON: http://Goo.gl/eexNMT
* Helm Charts: https://github.com/kubernetes/helm (TODO there are more URLS here right?)
* https://kubernetes.io/docs/home/
* 15 kubernetes features in 15 minutes: https://www.youtube.com/watch?v=o85VR90RGNQ

# Topics warranting further investigation

(Pull requests welcome)

* SSL termination
* Asset precompile w/ nginx serving static assets, or CDN (AWS cloudfront)
* Readiness checks vs liveness checks, what happens when a deploy fails, rollback.
* Termination grace period: https://pracucci.com/graceful-shutdown-of-kubernetes-pods.html
* Background tasks (e.g. resque). Use kubernetes job OR just a regular deployment/pods? https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/
* Taking downtime for migrations. (maintenance page)
* How can we ensure `rake db:migrate` is run exactly once on deploy. (and other deploy hooks)
* Helm (TODO: URL). Package management for kubernetes and templating system for manifest files.
* Using container registries other than docker hub (and private ones with credentials).
* init containers
* multiple pods in a single container (sharing a volume)
* statefulsets
* node-affinity
* daemonsets
* resourcequotas
