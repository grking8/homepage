---
layout: post
title: Jekyll - Continuous Deployment With Github, CircleCI, Kubernetes, and Google Cloud Platform - Part 2
author: familyguy
comments: true
---


{% include post-image.html name="k8.png" width="75" height="75" 
alt="Kubernetes logo" %}

In [Part 1,](/2018/05/01/jekyll-continuous-deployment-with-github-circleci-kubernetes-and-google-cloud-platform-part-1.html) 
we integrated CircleCI with Github to trigger a build of our Jekyll website on each push
to Github.

In this part, we will use **Google Cloud Platform** to achieve **continuous deployment.**

We will do so by adding two **jobs** to our CircleCI **workflow.**

The first job is _containerisation_ which was mentioned in Part 1. As well as creating
the Docker image, we will also upload it to **Google Container Registry** (cloud storage for 
Docker images).

The second job will handle the actual deployment to a production server. This will be
done using **Kubernetes.**

## Preliminary steps

1. Create a Gmail account    

2. Login to Google Cloud

3. Create a project and enable billing

4. [Install the Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstart-linux)

5. [Setup Google Container Registry](https://cloud.google.com/container-registry/docs/quickstart) (step 3 "Enable the API")

6. Create a Kubernetes cluster in Google Cloud (**_Kubernetes Engine_** on 
the left hand side in Google Cloud Console)

7. [Create a Google Cloud service account](https://cloud.google.com/docs/authentication/getting-started) ("Creating a service account")

8. Encode the contents of the JSON file downloaded in 7. `cat path/to/json | base64 | tr -d "\n"`

9. In CircleCI, **_Settings->Projects_**. Find the repository of your Jekyll website and
click on the wheel icon in the top right hand corner. On the left hand side, **_Build Settings->Environment Variables_**, 
then **_Add Variable_** with name: `GCLOUD_SERVICE_KEY`, value: the encoded contents from 8.

10. Same as 9., add remaining environment variables in CircleCI: 
  - `GCLOUD_PROJECT: <my-project>`
  - `GCLOUD_COMPUTE_ZONE: <my-zone>`
  - `GCLOUD_K8_CLUSTER: <my-cluster>`
  - `DOCKER_CONTAINER_REGISTRY: <my-registry>`

## Optional (recommended) steps

To interact with the Kubernetes API on your local computer:

1. Check the Kubernetes command line tool is installed with `kubectl version`. If not,
try `gcloud components install kubectl`, following any prompts

2. `gcloud auth login`

3. Point `kubectl` to the cluster created in 6.

   `gcloud container clusters get-credentials <my-cluster>`

## Add job - containerisation

Firstly, we have to modify our original `build` job so that the contents of `_site` are
persisted and can be used by the next job.

```yaml
version: 2
jobs:
  build:
    docker:
      - image: jekyll/jekyll:3.5.0
    working_directory: /srv/jekyll
    steps:
      - checkout
      - run:
          command: ./build-jekyll.sh
          environment:
            JEKYLL_ENV: production
      # additional step      
      - persist_to_workspace:
          root: /srv/jekyll
          paths:
            - _site
```

Now that the contents of `_site` are persisted, we can create a new job in the workflow:

[bearing in mind that to push to Google Container Registry, we need to install 
and authenticate the Google Cloud SDK first]

```yaml
  # add job `containerise`
  containerise:
    docker:
      - image: google/cloud-sdk:latest
    steps:
      - setup_remote_docker
      - checkout
      - attach_workspace:
          at: .
      - run:
          command: ./authenticate-gcloud.sh
      - run:
          command: docker build --tag "DOCKER_CONTAINER_REGISTRY"/"GCLOUD_PROJECT"/"<my-image>":"<my-image-version>" .
      - run:
          name: Push docker image
          command: docker push "DOCKER_CONTAINER_REGISTRY"/"GCLOUD_PROJECT"/"<my-image>":"<my-image-version>"
workflows:
  version: 2
  build-containerise:
    jobs:
      - build
      # add new job `containerise` to workflow
      - containerise:
          requires:
            - build
          filters:
            branches:
              only: master  
```

with `authenticate-gcloud.sh` in the project root

```bash
#!/usr/bin/env bash

set -e

GCLOUD_SERVICE_KEY_PATH="$HOME"/gcloud-service-key.json
echo "$GCLOUD_SERVICE_KEY" | base64 --decode --ignore-garbage > "$GCLOUD_SERVICE_KEY_PATH"
gcloud auth activate-service-account --key-file="$GCLOUD_SERVICE_KEY_PATH"
gcloud config set project "$GCLOUD_PROJECT"
gcloud config set compute/zone "$GCLOUD_COMPUTE_ZONE"
gcloud auth configure-docker
```

As we want to expose our Jekyll site to the internet, we add `EXPOSE 80` to our `Dockerfile`.

## Add job - Kubernetes deployment

Deployment is done via `kubectl` which is part of the Google Cloud SDK.

Thus the changes to
our CircleCI `config.yml` are quite similar to those above:

```yaml
  # add job `deploy-production`
  deploy-production:
    docker:
      - image: google/cloud-sdk:latest
    steps:
      - checkout
      - run:
          commmand: ./authenticate-gcloud.sh
      - run:
          command: ./deploy.sh
workflows:
  version: 2
  build-containerise-deploy-production:
    jobs:
      - build
      - containerise:
          requires:
            - build
          filters:
            branches:
              only: master
      # add new job `deploy-production` to workflow    
      - deploy-production:
          requires:
            - containerise
          filters:
            branches:
              only: master
```

However, as we will be interacting with the Kubernetes cluster, we add

```bash
gcloud container clusters get-credentials "<my-cluster>"
```

to `authenticate-gcloud.sh`.

The actual deployment happens in `deploy.sh`

```bash
#!/usr/bin/env bash

set -xe

kubectl apply -f deployment.yml
kubectl apply -f service.yml
```

Firstly, a Kubernetes deployment object is created as per `deployment.yml`

```yaml
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: my-deployment
spec:  # specification of desired behaviour of deployment
  selector:  # label selector for pods; must match pod template's labels
    matchLabels:
      app: my-app
  template:  # pod definition
    metadata:
      labels:
        app: my-app
    spec:  # specification of desired behaviour of pod
      containers:  # containers in pod
      - name: my-jekyll-nginx-container
        image: <my-registry>/<my-project>/<my-image>:<my-image-version>
        imagePullPolicy: Always
        ports:
        - containerPort: 80  # as per `EXPOSE 80` in Dockerfile
```




This however
only makes our Jekyll site available within the Kubernetes cluster.

We want to make it also available externally at a static IP address.

Create an external static IP address in Google Cloud; in the console on the left hand side 
**_NETWORKING->VPC network->External IP addresses->RESERVE STATIC ADDRESS._** Make a note of
this IP address.

Secondly, create a Kubernetes service object as per `service.yml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:  # defines behaviour of service
  selector:  # route service traffic to pod(s) with label keys and values matching this selector
    app: my-app  # as per label for pod above
  type:  LoadBalancer  # determines how service is exposed
  loadBalancerIP: <my-static-ip>  # only applies to `type: LoadBalancer`; supported by Google Cloud 
  ports:  # ports exposed by service
  - port: 8080  # exposed port
    targetPort: 80  # number or name of port to access on pod(s) targeted by service; matches `containerPort: 80` in deployment.yml
```

Before pushing these changes to Github, you can check the syntax of your Kubernetes
YAML files:

`kubectl apply --validate=true --dry-run=true --filename=<my-kubernetes-file>`

If all goes well and your jobs build successfully in CircleCI, you should be able
to view your site at `<my-static-ip>:8080`.

NB: This might take a few moments, you can check it is ready with `kubectl get services` 
(assuming you completed the optional steps).
