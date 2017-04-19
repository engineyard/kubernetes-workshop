Create a deployment:

    k run k8sapp --image=engineyard/k8sapp --port 5000 --labels="app=k8sapp"

See it running

The Pods where the app is actually running:

    k get pods -o wide

    NAME                      READY     STATUS              RESTARTS   AGE       IP        NODE
    k8sapp-1336000273-0mwsc   0/1       ContainerCreating   0          7s        <none>    ip-172-20-1-239.us-west-2.compute.internal

The Deployment which manages the replica sets:

    k get deployments

    NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    k8sapp    1         1         1            0           55s

The replica sets:

    k get replicasets

    NAME                DESIRED   CURRENT   READY     AGE
    k8sapp-1336000273   1         1         0         1m

When everything is up and running, pod will have an IP:

    NAME                      READY     STATUS    RESTARTS   AGE       IP           NODE
    k8sapp-1336000273-0mwsc   1/1       Running   0          3m        10.200.1.5   ip-172-20-1-239.us-west-2.compute.internal

We can start a new container just for interacting:

    k run -it bashbox --image=ruby:2.3 --rm -- bash

And using the IP of the running Pod, we see that the app is exposed to other Pods in kubernetes

    wget -qO- http://10.200.1.5:5000
    seq 5 | xargs -I{} wget -qO- http://10.200.1.5:5000

But we're still not exposed outside the cluster. And our IP will change if our Pod is recreated (due to deployment, scaling, etc..)

If we kill the pod, the replica set will re-create it

Create a clusterIP service

    k create service clusterip k8sapp --tcp=80:5000

    k get services

    NAME         CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
    k8sapp       10.254.221.20   <none>        80/TCP    17s
    kubernetes   10.254.0.1      <none>        443/TCP   12h

Now back to container just for interacting:

    k run -it bashbox --image=ruby:2.3 --rm -- bash

We can see that the cluster ip is usable 

    wget -qO- http://10.254.221.20

And kubeDNS can also get us to the services

    wget -qO- http://k8sapp

And we even have some environment variables

    root@bashbox-2310052996-q6hdc:/# env | grep K8SAPP
    K8SAPP_PORT_80_TCP=tcp://10.254.221.20:80
    K8SAPP_SERVICE_PORT=80
    K8SAPP_SERVICE_PORT_80_5000=80
    K8SAPP_PORT=tcp://10.254.221.20:80
    K8SAPP_PORT_80_TCP_PORT=80
    K8SAPP_PORT_80_TCP_PROTO=tcp
    K8SAPP_SERVICE_HOST=10.254.221.20
    K8SAPP_PORT_80_TCP_ADDR=10.254.221.20

But we're still not exposed outside the cluster!

We need an ELB. We could provision a new one:

    k expose deployment k8sapp --type=LoadBalancer --name=k8sappelb --port=80 --target-port=5000

Or we can use the nginx-ingress (which already has an ELB attached, and a useful CNAME)

    k get services/nginx-ingress -n kube-system

    NAME            CLUSTER-IP       EXTERNAL-IP        PORT(S)        AGE
    nginx-ingress   10.254.146.199   a33df536524bd...   80:31060/TCP   12h

(FYI `get services --all-namespaces` to explore things in other namespaces)

Now let's create an ingress:

    echo "apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: k8sapp
    spec:
      rules:
        #CAN use underscores but NO dashes
        - host: k8sapp.${ENV_NAME}.my.ey.io
          http:
            paths:
            - backend:
                serviceName: k8sapp
                servicePort: 80" | kubectl create -f -

See that the ingress was created

    k get ingress

Try it!

    curl k8sapp.${ENV_NAME}.my.ey.io

Or open in a browser

    echo http://k8sapp.${ENV_NAME}.my.ey.io

(copy/paste into a web browser)

We are finally publicly exposed!

Also maybe out load balancer has provisioned by now:

    k get services -o wide

    NAME         CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)        AGE       SELECTOR
    k8sapp       10.254.221.20   <none>                                                                    80/TCP         31m       app=k8sapp
    k8sappelb    10.254.147.68   a69c4fa4d252711e7b50a02a1fcd79f8-1821649505.us-west-2.elb.amazonaws.com   80:32592/TCP   21m       app=k8sapp
    kubernetes   10.254.0.1      <none>                                                                    443/TCP        13h       <none>

We are also exposed via ELB:

    curl a69c4fa4d252711e7b50a02a1fcd79f8-1821649505.us-west-2.elb.amazonaws.com

