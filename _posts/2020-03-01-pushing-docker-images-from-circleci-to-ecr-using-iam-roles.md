---
layout: post
title: Pushing Docker Images from CircleCI to ECR using IAM Roles
author: familyguy
comments: true
tags: aws circleci sts boto3 python ecr iam iam-roles docker
---

{% include post-image.html name="lock-4529981_960_720.webp" width="100" height="100" alt="security padlock" %}

In the [previous post](https://guyrking.com/2020/02/29/pushing-docker-images-from-ec2-to-ecr-using-iam-roles.html), we pushed a Docker image from EC2 to ECR using an IAM role.

The IAM role we used had EC2 as a trusted entity which meant our EC2 instance could 
interact with ECR without explicitly storing any credentials.

The credentials used implicitly were also temporary, as supposed to the long
term credentials of an IAM user with programmatic access.

In this post, we ask: Can we push a Docker image from CircleCI (instead of EC2) to
ECR using an IAM role?

## Trusted entities revisited

If we consider the four trusted entities for IAM roles in the previous post, CircleCI does not 
fit any of them.

However, although they are not displayed in the IAM console when creating a new role,
IAM users can also be trusted entities.

Thus we could push a Docker image from CircleCI to ECR by creating an IAM user and storing 
its credentials in CircleCI. 

The IAM user could then be made a trusted entity for an IAM role with permissions to interact with ECR.

## Giving permissions directly to the IAM user

We could just give the permissions directly to the IAM user whose credentials are stored in CircleCI.

This is probably the more common solution and there do not seem to be any obvious security drawbacks
compared with using an IAM role. It is also probably easier to implement.

However, if all this talk about IAM roles has whetted your appetite, continue reading to see how an
implementation using IAM roles might look.

## Push a Docker image from CircleCI to ECR using an IAM role

### Approach

Same as in the [previous post](https://guyrking.com/2020/02/29/pushing-docker-images-from-ec2-to-ecr-using-iam-roles.html) except:

- Replace our EC2 instance with a server that spins up during a CircleCI build
- In our `containerise` role, change the trusted entity from an EC2 instance to an IAM user
- The IAM user has no permissions, but has programmatic access
- Get the IAM user to assume the `containerise` role via the 
[AWS Security Token Service (STS)](https://docs.aws.amazon.com/STS/latest/APIReference/Welcome.html) 
(which the EC2 instance did under the hood)
- Replace the AWS CLI with the AWS Python SDK, Boto3 (author preference)

### Steps

In what follows, the AWS region is `us-east-1` (North Virginia).

#### Create an ECR repository

In the ECR console, create a repository `circleci-ecr-test`.

#### Create an IAM policy

In the IAM console, create a policy `ECRContainerise` with description `"Allows
Docker images to be built and pushed to the ECR repository circleci-ecr-test"` with the JSON

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:PutLifecyclePolicy",
                "ecr:PutImageTagMutability",
                "ecr:StartImageScan",
                "ecr:CreateRepository",
                "ecr:PutImageScanningConfiguration",
                "ecr:UploadLayerPart",
                "ecr:BatchDeleteImage",
                "ecr:DeleteLifecyclePolicy",
                "ecr:DeleteRepository",
                "ecr:PutImage",
                "ecr:CompleteLayerUpload",
                "ecr:StartLifecyclePolicyPreview",
                "ecr:InitiateLayerUpload",
                "ecr:DeleteRepositoryPolicy"
            ],
            "Resource": "arn:aws:ecr:us-east-1:<aws-account-id>:repository/circleci-ecr-test"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ecr:GetAuthorizationToken",
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "ecr:BatchCheckLayerAvailability",
            "Resource": "arn:aws:ecr:us-east-1:<aws-account-id>:repository/circleci-ecr-test"
        }
    ]
}
```

#### Create an IAM user

In the IAM console, create a user `circleci` with no permissions and programmatic access. 

Make a note of the secret access key as this is the only time it will be available and  
will be needed later. It will be referred to as `<secret-access-key>`

#### Create an IAM role

In the IAM console, create a role `containerise` with description 
`"Allows CircleCI to containerise Docker images"`:

- Select `"AWS service EC2"` as the trusted entity type (we will change this later)
- Attach policy `ECRContainerise` to the role

After creation of the role, select it in the IAM console and from `Trust relationships`,
edit the trust relationship to match the JSON

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<aws-account-id>:user/circleci"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

#### Create a GitHub repository

In GitHub, create an empty repository `circleci-ecr-test`.

#### Create a local repository

Clone `circleci-ecr-test`

`git clone git@github.com:<gh-username>/circleci-ecr-test.git`

Create the files

`environment.yml`

```yml
dependencies:
  - python=3.6.3
  - pip=20.0.2
  - pip:
    - boto3==1.12.8
    - docker==4.2.0
```

`build-env.sh`

```bash
#!/usr/bin/env bash

set -xe

echo "Update conda"
conda update conda
echo "Build conda environment"
conda env update --name root --file environment.yml
```

`Dockerfile`

```docker
FROM alpine:latest

CMD ["sh", "-c", "echo hello"]
```

`containerise.py`

```python
import base64
import os

import boto3
import docker


sts_client = boto3.client(
    'sts',
    aws_access_key_id=os.environ['AWS_IAM_USER_ACCESS_KEY_ID'],
    aws_secret_access_key=os.environ['AWS_IAM_USER_SECRET_ACCESS_KEY'],
)
assumed_role = sts_client.assume_role(
    RoleArn=os.environ['AWS_IAM_ROLE_ARN'],
    RoleSessionName='AssumeRoleSession1',
)
credentials = assumed_role['Credentials']
ecr = {
    'client': boto3.client(
        'ecr',
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken'],
        region_name=os.environ['AWS_REGION'],
    ),
}
ecr['token'] = ecr['client'].get_authorization_token()
ecr['auth_data'] = ecr['token']['authorizationData'][0]
ecr['username'], ecr['password'] = base64.b64decode(
    ecr['auth_data']['authorizationToken']).decode().split(':')
ecr['registry'] = ecr['auth_data']['proxyEndpoint'].split('://')[-1]

docker_client = docker.from_env()
repo_name = 'circleci-ecr-test'
image_tag = 'v1'
image = {
    'repo': f'{ecr["registry"]}/{repo_name}',
    'tag': image_tag,
    'uri': f'{ecr["registry"]}/{repo_name}:{image_tag}',
}
docker_client.images.build(
    path=os.path.dirname(os.path.abspath(__file__)),
    tag=image['uri'],
)
docker_client.login(
    ecr['username'],
    ecr['password'],
    registry=ecr['registry'],
)
images_to_push = docker_client.images.push(
    image['uri'],
    stream=True,
    decode=True
)
for image_to_push in images_to_push:
    print(image_to_push)
```

`.circleci/config.yml`

```yml
version: 2
jobs:
  containerise:
    docker:
      - image: continuumio/miniconda3:latest
    steps:
      - checkout
      - setup_remote_docker
      - run:
          command: ./build-env.sh
      - run:
          command: python containerise.py
workflows:
  version: 2
  containerise:
    jobs:
      - containerise

```

Give `build-env.sh` executable permissions

`chmod u+x build-env.sh`

#### Push local repository to GitHub

Commit and push the above changes

`git add -A`

`git commit -m 'Add files'`

`git push origin master`

A project `circleci-ecr-test` should be created in CircleCI and a build for it triggered.

The build will fail because of missing environment variables; cancel the build.

#### Add environments variable in CircleCI

In CircleCI, add the environment variables:

- Name `AWS_IAM_USER_ACCESS_KEY_ID` and value `<access-key-id>` which is in the IAM console 
under the user `circleci` and `"Access key ID"`
- Name `AWS_IAM_USER_SECRET_ACCESS_KEY` and value `<secret-access-key>`
- Name `AWS_IAM_ROLE_ARN` and value `arn:aws:iam::<aws-account-id>:role/containerise`
- Name `AWS_REGION` and value `us-east-1`

#### Rerun CircleCI build

Should see the build pass.

In ECR, in the repository `circleci-ecr-test`, there should be an image with tag `v1`.

### Clean up

In the AWS console:

- Remove ECR repository `ec2-ecr-test`
- Remove IAM policy `ECRContainerise`
- Remove IAM role `containerise`
- Remove IAM user `circleci`

In GitHub, remove repository `circleci-ecr-test` which should also remove the project in CircleCI.

On your local machine, remove the directory `/path/to/circleci-ecr-test`.
