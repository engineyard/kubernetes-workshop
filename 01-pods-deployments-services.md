# Pods, Deployments, Services

Deploy a rails app to kubernetes using a Deployment. Interact with the created Pods. Scale the Deployment. Expose the app to the internet with a Service.

# Steps

## Deployment

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

We can exec into the running container:

    k exec -it k8sapp-1336000273-0mwsc bash

    wget -qO- http://localhost:5000

Or start a new container just for interacting:

    k run -it bashbox --image=ruby:2.3 --rm -- bash

And using the IP of the running Pod, we see that the app is exposed to other Pods in kubernetes

    wget -qO- http://10.200.1.5:5000
    seq 5 | xargs -I{} wget -qO- http://10.200.1.5:5000

But we're still not exposed outside the cluster. And our IP will change if our Pod is re-created (due to deployment, scaling, etc..)

If we kill the pod, the replica set will re-create it

## Service

Create a clusterIP service

    k create service clusterip k8sapp --tcp=80:5000

    k get services -o wide

    NAME         CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE       SELECTOR
    k8sapp       10.254.221.20   <none>        80/TCP    6s        app=k8sapp
    kubernetes   10.254.0.1      <none>        443/TCP   4h        <none>

List matching pods (by label)

    k get pods -l app=k8sapp
    NAME                      READY     STATUS    RESTARTS   AGE
    k8sapp-3607609085-653nx   1/1       Running   0          3m

Now back to a container just for interacting:

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

## Ingress

We're still not exposed outside the cluster! Let's fix that.

We could use an ELB. We can provision one like so:

    k expose deployment k8sapp --type=LoadBalancer --name=k8sappelb --port=80 --target-port=5000

Or we can use the nginx-ingress, which already has an ELB attached, and will allow us to share that ELB across multiple apps.

    k get services/nginx-ingress -n kube-system -o wide

    NAME            CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)        AGE       SELECTOR
    nginx-ingress   10.254.178.91   a192b4016291211e78cd7023e9bf8dfa-111615484.us-east-1.elb.amazonaws.com   80:31659/TCP   4h        app=nginx-ingress

(FYI `get services --all-namespaces` to explore things in other namespaces)

That ELB that's already setup, also has a useful CNAME (thanks Engine Yard).

    nslookup *.${ENV_NAME}.my.ey.io

    ...
    *.bukeybasha2.my.ey.io	canonical name = a192b4016291211e78cd7023e9bf8dfa-111615484.us-east-1.elb.amazonaws.com.
    Name:	a192b4016291211e78cd7023e9bf8dfa-111615484.us-east-1.elb.amazonaws.com
    Address: 34.197.151.80
    ...

So let's create an ingress (beware of):

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

Our load balancer should by provisioned by now too:

    k get services -o wide

    NAME         CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)        AGE       SELECTOR
    k8sapp       10.254.221.20   <none>                                                                    80/TCP         31m       app=k8sapp
    k8sappelb    10.254.147.68   a69c4fa4d252711e7b50a02a1fcd79f8-1821649505.us-west-2.elb.amazonaws.com   80:32592/TCP   21m       app=k8sapp
    kubernetes   10.254.0.1      <none>                                                                    443/TCP        13h       <none>

We are also exposed via ELB:

    curl a69c4fa4d252711e7b50a02a1fcd79f8-1821649505.us-west-2.elb.amazonaws.com

## Selectors & Labels

Scale up (and expose some more problems with our app as-configured at the moment).

    k scale deployments/k8sapp --replicas=5

Notice we don't have a working hit counter anymore (Hint: it wasn't working to begin with)

    seq 9 | xargs -I{} curl k8sapp.${ENV_NAME}.my.ey.io

    {"Hit Count":8}{"Hit Count":7}{"Hit Count":18}{"Hit Count":7}{"Hit Count":8}{"Hit Count":9}{"Hit Count":9}{"Hit Count":19}{"Hit Count":9}

... Still using sqlite and Rails env development.

Now's a good time for a little sidetrack into selectors and labels

    k get pods

    k8sapp-3607609085-653nx   1/1       Running   0          25m
    k8sapp-3607609085-97f40   1/1       Running   0          11m
    k8sapp-3607609085-ddf9q   1/1       Running   0          11m
    k8sapp-3607609085-qjmhp   1/1       Running   0          11m
    k8sapp-3607609085-v05gz   1/1       Running   0          11m

    k edit pods/k8sapp-3607609085-ddf9q -o yaml

Let's add the label `foo=bar`. (`vi` hint, arrow down to the `app: k8sapp` line, type `Y` to copy the line, `P` to paste it, `i` to begin editing it, `esc :wq` when you are done)

    labels:
      app: k8sapp
      pod-template-hash: "3607609085"

becomes:

    labels:
      app: k8sapp
      foo: bar
      pod-template-hash: "3607609085"

And let's do the same with the service:

    k edit services/k8sapp

    selector:
      app: k8sapp

becomes

    selector:
      foo: bar

Now our service is only hitting that 1 pod

    seq 9 | xargs -I{} curl k8sapp.${ENV_NAME}.my.ey.io

    {"Hit Count":10}{"Hit Count":11}{"Hit Count":12}{"Hit Count":13}{"Hit Count":14}{"Hit Count":15}{"Hit Count":16}{"Hit Count":17}{"Hit Count":18}

Undo our little hacks before the next section
