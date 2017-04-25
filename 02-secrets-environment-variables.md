# Secrets and Environment Variables

Set environment variable `RAILS_ENV` to production on our Rails app using `env` config.
Set environment variable `SECRET_KEY_BASE` using a kubernetes secret.
Connect to an externally configured RDS database connecting a pre-configured secret to `DATABASE_URL`.

# Steps

So far we've been using sqlite. If we kill the running pod, and let the deployment recreate it, the hit counter will start over back where it was when we built the docker image.

    $ seq 5 | xargs -I{} curl ae036ae591e7611e782cc0add41e3562-1667221753.us-east-1.elb.amazonaws.com
    {"Hit Count":32}{"Hit Count":33}{"Hit Count":34}{"Hit Count":35}{"Hit Count":36}

    $ k get pods
    NAME                              READY     STATUS             RESTARTS   AGE
    k8sapp-2127871177-pzjld           1/1       Running            0          55s

    $ k delete pods/k8sapp-2127871177-pzjld
    pod "k8sapp-2127871177-pzjld" deleted

    $ k get pods
    NAME                              READY     STATUS             RESTARTS   AGE
    k8sapp-2127871177-m0642           1/1       Running            0          2s
    k8sapp-2127871177-pzjld           1/1       Terminating        0          1m

    $ seq 5 | xargs -I{} curl ae036ae591e7611e782cc0add41e3562-1667221753.us-east-1.elb.amazonaws.com
    {"Hit Count":6}{"Hit Count":7}{"Hit Count":8}{"Hit Count":9}{"Hit Count":10}

We're also still running in development mode.

    $ k get pods
    NAME                              READY     STATUS             RESTARTS   AGE
    k8sapp-2127871177-m0642            1/1       Running            0          7m

    $ k exec -it k8sapp-2127871177-m0642 bash
    root@k8sapp-2127871177-m0642:/app# bundle exec rails c
    Running via Spring preloader in process 46
    Loading development environment (Rails 5.0.2)
    irb(main):001:0> Rails.env
    => "development"

### environment variables

The kubernetes `deployment` is responsible for ensuring N replicas of our `k8sapp` pod is running. So we can actually delete and re-create the deployment without downtime if set `--cascade=false`, this will ensure the pods are not deleted.  We'll then re-create it with environment variables.

    $ k get deployments
    NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    k8sapp    1         1         1            1           10h

    $ k delete deployments/k8sapp --cascade=false
    deployment "k8sapp" deleted
    $ k get pods
    NAME                     READY     STATUS    RESTARTS   AGE
    k8sapp-2127871177-m0642  1/1       Running   0          51m

    $ kubectl run k8sapp --image=engineyard/k8sapp --port 5000 --env="RAILS_ENV=production"

If we load the app in a browser now (via ELB hostname) we should see an error:

    open http://ae036ae591e7611e782cc0add41e3562-1667221753.us-east-1.elb.amazonaws.com/

    Missing `secret_key_base` for 'production' environment, set this value in `config/secrets.yml`

### Other environment variables to consider setting

Tell rails to serve static assest (since we haven't setup nginx or CDN to serve them)

    RAILS_SERVE_STATIC_FILES=true

Tell rails to output all logs to STDOUT instead of log files (so we can use `k logs`)

    RAILS_LOG_TO_STDOUT=true

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
    k8sapp-254138870-vmjj1  1/1       Terminating   0          19s
    k8sapp-596859129-kp76n  1/1       Running       0          14s

    $ k exec -it k8sapp-596859129-kp76n -- bash
    $ env
    ...
    SECRET_KEY_BASE=yH3dBDn6YTate8FXSyhrntDwMCPitSpv0cLmqCtTF1M...
    ...

Now try the app again:

    open http://ae036ae591e7611e782cc0add41e3562-1667221753.us-east-1.elb.amazonaws.com/

Get a 500 error, but we're in `RAILS_ENV=production` now so it's not so easily visible

We can try:

    k logs k8sapp-596859129-kp76n

But that only gives us STDOUT of the puma process (unless `RAILS_LOG_TO_STDOUT` is set)
We can also just exec into the pod again and look at the logs:

    k exec -it k8sapp-596859129-kp76n -- bash
    tail -f log/production.log
    ...
      ActiveRecord::StatementInvalid (SQLite3::SQLException: no such table: hit_counters
    ...

So the database doesn't exist because it's still sqlite and we didn't migrate. Let's switch it to postgres by populating `DATABASE_URL`

In a coming-very-soon version of the Engine Yard CLI: `kubey`, you'll be able to provision RDS databases. In the meantime, you'll have to make use of the one that's already provided.

`k get secrets` should show that there's a `exampledb` secret. We can look at it's contents with a little help from ruby.

`k get secret/exampledb -o yaml` shows a YAML description of the secret with an obfuscated value for `database-url`. But it's only obfuscated with Base64, so to see it's contents:

    k get secret/exampledb -o yaml | ruby -ryaml -rbase64 -e "puts Base64.decode64(YAML.load(STDIN)['data']['database-url'])"

So now let's attach that secret to our cluster as DATABASE_URL

    k get deployments/k8sapp -o json | \
      ruby -rjson -e "puts JSON.pretty_generate(JSON.load(STDIN.read).tap{|x|
        x['spec']['template']['spec']['containers'].first['env'] <<
          {name: 'DATABASE_URL', valueFrom: {secretKeyRef: {name: 'exampledb', key: 'database-url'}}}})" | \
            k replace -f -

And we need to migrate (I'm afraid the solution is rather "manual" at the moment)

    $ k get pods
    NAME                     READY     STATUS    RESTARTS   AGE
    k8sapp-3909670473-7cpz9  1/1       Running   0          1m
    $ k exec -it k8sapp-3909670473-7cpz9 -- bash
    bundle exec rake db:migrate

And now, finally, it's working, right?

    open http://ae036ae591e7611e782cc0add41e3562-1667221753.us-east-1.elb.amazonaws.com/

## proxy / ui

    k proxy

Is a useful little UI we can serve up. It kinda assumes you are running `kubectl` locally and not this weird bridge box setup.

Workaround:

    k proxy --address='0.0.0.0' --disable-filter=true

And to get the public hostname of our bridge box (output you can paste into a web browser)

    echo $(curl -s http://169.254.169.254/latest/meta-data/public-hostname):8001
