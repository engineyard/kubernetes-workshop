# This tutorial covers

- Deploying a pre-built super-basic rails app to a running kubernetes cluster
- Connecting to externally configured Database (using Amazon RDS)

# See Also:

- Dockerize for kubernetes a rails app from scratch: TODO link
- Using a containerized database running inside your kubernetes cluster: TODO link

# Step by Step

## 1 Deploy on Kubernetes

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

We are finally publicly exposed!

Also maybe out load balancer has provisioned by now:

    k get services -o wide

    NAME         CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)        AGE       SELECTOR
    k8sapp       10.254.221.20   <none>                                                                    80/TCP         31m       app=k8sapp
    k8sappelb    10.254.147.68   a69c4fa4d252711e7b50a02a1fcd79f8-1821649505.us-west-2.elb.amazonaws.com   80:32592/TCP   21m       app=k8sapp
    kubernetes   10.254.0.1      <none>                                                                    443/TCP        13h       <none>

We are also exposed via ELB:

    curl a69c4fa4d252711e7b50a02a1fcd79f8-1821649505.us-west-2.elb.amazonaws.com








TODO: put the environment name into an environment variable on bridge

Expose external to the cluster by creating a Load Balancer:

    kubectl expose deployment myapp --type=LoadBalancer --name=myapp --port=80 --target-port=5000

e.g:

    $ k get services -o wide
    NAME             CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)        AGE       SELECTOR
    kubernetes       10.254.0.1      <none>                                                                    443/TCP        6d        <none>
    myapp            10.254.55.72    ae036ae591e7611e782cc0add41e3562-1667221753.us-east-1.elb.amazonaws.com   80:32237/TCP   8s        run=myapp

then visit (takes about 5 minutes to provision the Elastic Load Balancer):

    ae036ae591e7611e782cc0add41e3562-1667221753.us-east-1.elb.amazonaws.com

## 4 Connecting to a "real" database (and going to "production")

So far we've been using sqlite. If we kill the running pod, and let the deployment recreate it, the hit counter will start over back where it was when we built the docker image.

    $ seq 5 | xargs -I{} curl ae036ae591e7611e782cc0add41e3562-1667221753.us-east-1.elb.amazonaws.com
    {"Hit Count":32}{"Hit Count":33}{"Hit Count":34}{"Hit Count":35}{"Hit Count":36}

    $ k get pods
    NAME                              READY     STATUS             RESTARTS   AGE
    myapp-2127871177-pzjld            1/1       Running            0          55s

    $ k delete pods/myapp-2127871177-pzjld
    pod "myapp-2127871177-pzjld" deleted

    $ k get pods
    NAME                              READY     STATUS             RESTARTS   AGE
    myapp-2127871177-m0642            1/1       Running            0          2s
    myapp-2127871177-pzjld            1/1       Terminating        0          1m

    $ seq 5 | xargs -I{} curl ae036ae591e7611e782cc0add41e3562-1667221753.us-east-1.elb.amazonaws.com
    {"Hit Count":6}{"Hit Count":7}{"Hit Count":8}{"Hit Count":9}{"Hit Count":10}

We're also still running in development mode.

    $ k get pods
    NAME                              READY     STATUS             RESTARTS   AGE
    myapp-2127871177-m0642            1/1       Running            0          7m

    $ k exec -it myapp-2127871177-m0642 bash
    root@myapp-2127871177-m0642:/app# bundle exec rails c
    Running via Spring preloader in process 46
    Loading development environment (Rails 5.0.2)
    irb(main):001:0> Rails.env
    => "development"

### environment variables

The kubernetes `deployment` is responsible for ensuring N replicas of our `myapp` pod is running. So we can actually delete and re-create the deployment without downtime if set `--cascade=false`, this will ensure the pods are not deleted.  We'll then re-create it with environment variables.

    $ k get deployments
    NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    myapp     1         1         1            1           10h

    $ k delete deployments/myapp --cascade=false
    deployment "myapp" deleted
    $ k get pods
    NAME                     READY     STATUS    RESTARTS   AGE
    myapp-2127871177-m0642   1/1       Running   0          51m

    $ kubectl run myapp --image=jacobo/myapp --port 5000 --env="RAILS_ENV=production"

If we load the app in a browser now (via ELB hostname) we should see an error:

    open http://ae036ae591e7611e782cc0add41e3562-1667221753.us-east-1.elb.amazonaws.com/

    Missing `secret_key_base` for 'production' environment, set this value in `config/secrets.yml`

### secrets

Create a SECRET_KEY_BASE secret:

    ruby -rsecurerandom -e "print SecureRandom.hex(100)" > skb
    kubectl create secret generic secret-key-base --from-file=skb
    rm skb

Verify it:

    $ k get secrets
    NAME                  TYPE                                  DATA      AGE
    secret-key-base       Opaque                                1         5s

Attach the secret to the deployment, by editing and replacing the deployment:

    k get deployments/demoapp -o json | \
      ruby -rjson -e "puts JSON.pretty_generate(JSON.load(STDIN.read).tap{|x|
        x['spec']['template']['spec']['containers'].first['env'] <<
          {name: 'SECRET_KEY_BASE', valueFrom: {secretKeyRef: {name: 'secret-key-base', key: 'skb'}}}})" | \
            k replace -f -

    $ k get pods
    NAME                    READY     STATUS        RESTARTS   AGE
    myapp-254138870-vmjj1   1/1       Terminating   0          19s
    myapp-596859129-kp76n   1/1       Running       0          14s

    $ k exec -it myapp-596859129-kp76n -- bash
    $ env
    ...
    SECRET_KEY_BASE=yH3dBDn6YTate8FXSyhrntDwMCPitSpv0cLmqCtTF1M...
    ...

Now try the app again:

    open http://ae036ae591e7611e782cc0add41e3562-1667221753.us-east-1.elb.amazonaws.com/

Get a 500 error, but we're in `RAILS_ENV=production` now so it's not so easily visible

We can try:

    k logs myapp-596859129-kp76n

But that only gives us STDOUT of the unicorn process (Which, BTW, you can improve with a config option. see: TODO)
We can also just exec into the pod again and look at the logs:

    k exec -it myapp-596859129-kp76n -- bash
    tail -f log/production.log
    ...
      ActiveRecord::StatementInvalid (SQLite3::SQLException: no such table: hit_counters
    ...

So the database doesn't exist because it's still sqlite and we didn't migrate. Let's switch it to postgres by populating `DATABASE_URL`

In a coming-very-soon version of the Engine Yard CLI: `kubey`, you'll be able to provision RDS databases. In the meantime, you'll have to make use of the one that's already provided.

`k get secrets` should show that there's a `exampledb` secret. We can look at it's contents with a little help from ruby.

`k get secret/exampledb -o yaml` shows a YAML description of the secret with an obfuscated value for `database-url`. But it's only obfuscated with Base64, so to see it's contents:

    k get secret/exampledb -o yaml | ruby -ryaml -rbase64 -e "puts Base64.decode64(YAML.load(STDIN)['data']['database-url'])"

TODO: could we instead use AWS CLI to fetch the root creds of the database master and then create the DB directly with a psql command?

So now let's attach that secret to our cluster as DATABASE_URL

    k get deployments/myapp -o json | \
      ruby -rjson -e "puts JSON.pretty_generate(JSON.load(STDIN.read).tap{|x|
        x['spec']['template']['spec']['containers'].first['env'] <<
          {name: 'DATABASE_URL', valueFrom: {secretKeyRef: {name: 'exampledb', key: 'database-url'}}}})" | \
            k replace -f -

And we need to migrate (TODO: discussion about how we are waiting for k8s to implement deploy hooks)

    $ k get pods
    NAME                     READY     STATUS    RESTARTS   AGE
    myapp-3909670473-7cpz9   1/1       Running   0          1m
    $ k exec -it myapp-3909670473-7cpz9 -- bash
    bundle exec rake db:migrate

And now, finally, it's working, right?

    open http://ae036ae591e7611e782cc0add41e3562-1667221753.us-east-1.elb.amazonaws.com/
