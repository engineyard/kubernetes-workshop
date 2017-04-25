# The "cool" thing you came for, right?

https://martinfowler.com/bliki/BlueGreenDeployment.html

So we know how to edit deployments

    k edit deployments/k8sapp

We can change the image to deploy different versions

    ...
    image: engineyard/k8sapp:v1
    ...

    ...
    image: engineyard/k8sapp:v2
    ...

And notice it take a little while for the old pods to get rotated and the URL to start returning results from the new version

    k get pods

    NAME                              READY     STATUS              RESTARTS   AGE
    k8sapp-495960030-9jfhw            1/1       Terminating         0          4m
    k8sapp-495960030-bf8rj            1/1       Terminating         0          4m
    k8sapp-495960030-lnl9t            1/1       Terminating         0          4m
    k8sapp-495960030-w9tbl            1/1       Running             0          4m
    k8sapp-495960030-zf0mx            1/1       Running             0          4m
    k8sapp-576962527-1kqb8            0/1       ContainerCreating   0          0s
    k8sapp-576962527-1tmxs            1/1       Running             0          1s
    k8sapp-576962527-54pkc            1/1       Running             0          1s
    k8sapp-576962527-b389b            0/1       ContainerCreating   0          1s

    curl k8sapp.${ENV_NAME}.my.ey.io

Let's "fix" that and make deployments instantaneous (or at least feel that way to the user)

Let's create a blue deployment and a green deployment

    echo "apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: k8sapp-blue
      labels:
        app: k8sapp-blue
    spec:
      strategy:
        type: Recreate
      template:
        metadata:
          labels:
            app: k8sapp-blue
        spec:
          containers:
          - name: k8sapp-blue
            image: engineyard/k8sapp
            imagePullPolicy: Always
            ports:
            - containerPort: 5000
              name: k8sapp" | kubectl create -f -

    echo "apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: k8sapp-green
      labels:
        app: k8sapp-green
    spec:
      strategy:
        type: Recreate
      template:
        metadata:
          labels:
            app: k8sapp-green
        spec:
          containers:
          - name: k8sapp-green
            image: engineyard/k8sapp
            imagePullPolicy: Always
            ports:
            - containerPort: 5000
              name: k8sapp" | kubectl create -f -

We can now scale the deployments, change the version of images running in each, and editing the `services/k8sapp`

Make the `blue` deployment use image `image:engineyard/k8sapp:v1`

    k edit deployments/k8sapp-blue

change the service to point to `blue`

    k edit services/k8sapp

    ...
    selector:
      app: k8sapp-blue

Make the `green` deployment use image `image:engineyard/k8sapp:v2`

    k edit deployments/k8sapp-green

change the service to point to `green`

    k edit services/k8sapp

    ...
    selector:
      app: k8sapp-green
