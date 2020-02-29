---
layout: post
title: Pushing Docker images from EC2 to ECR using IAM Roles
author: familyguy
comments: true
tags: aws ec2 ecr iam iam-roles docker
---

{% include post-image.html name="lock-4529981_960_720.webp" width="100" height="100" alt="security padlock" %}

If you wonder about the purpose of IAM roles in AWS, 
hopefully this post will shed some light.

## IAM roles

In AWS, an [IAM role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) gives a trusted entity the ability to perform actions on
AWS resources in your account for a limited period of time.

The actions the trusted entity can perform are determined by the role's permissions (a list of IAM policies).

### Trusted entities

There are four main types of trusted entity:

- AWS service (EC2, Lambda and others)
- Another AWS account (belonging to you or a third party)
- Web identity (Cognito or any OpenID provider)
- SAML 2.0 federation (your corporate directory)

Any number of trusted entities can _assume_ a particular role.

You can determine how long they 
can assume the role for (the duration of an authenticated session), and under what conditions they can assume 
the role, e.g. [the request to assume a role must originate from a prespecified IP address.](https://aws.amazon.com/premiumsupport/knowledge-center/iam-restrict-calls-ip-addresses/)

### Use cases

#### Third party SaaS provider (also running on AWS)

Suppose you use a SaaS product that checks for security flaws in your AWS deployments. In order to 
do this, it needs access to resources in your AWS account.

You could create an IAM user with programmatic access and the relevant permissions, and
send the IAM user's secret access key and access key ID to the 
third party.

The third party could then use those credentials in their application to make AWS
API calls to access the resources in your account.

_Alternatively, you could create an IAM role and make certain IAM users in the third party's
AWS account trusted entities for that role._

Because they are trusted entities, those users
can assume the role, giving them the authorisation to make AWS API calls to 
access your resources.

#### Custom EC2 application

Suppose you have an application on an EC2 instance which needs to interact with another AWS service in
your account, e.g. ECR.

You could create an IAM user with programmatic access and the relevant permissions, and store
those credentials on the instance. 

You could then use the AWS CLI or an AWS SDK, e.g. Boto3, with those credentials to interact with ECR.

_Alternatively, you could create an IAM role and associate that role with your EC2 instance, making
the instance a trusted entity._

Because the instance is a trusted entity, any API calls via the AWS CLI or AWS SDK 
on the instance are authorised,
allowing the instance to interact with ECR.

### Benefits over IAM users

#### Scalability

Imagine in the SaaS example, you use not one provider but 10.

Each provider needs the same authorisation. 

Using IAM roles leads to the creation of one IAM role with 10 trusted entities.

Using IAM users leads to the creation of 10 IAM users*

What if you used 100 providers, or a 1000? It is a silly example, but it shows using IAM
roles is more scalable.

*You could create just one IAM user and give the same credentials to all the providers.
What happens if you stop using a provider? You could rotate the credentials and inform 
the remaining providers. Alternatively, with a separate user for each provider, 
you would simply delete the stopped provider's user.

#### Security 

According to AWS security best practices, you should minimise the number of long term credentials, e.g.
access key IDs and secret access keys, in your account.

This is exactly what using IAM roles rather than IAM users
does.

In the SaaS example, you also end up creating IAM users in your account who are external to your organisation
which is probably something you want to avoid.

## Push a Docker image from EC2 to ECR

Okay enough talking, let's make things more concrete with an example.

We want to push an image on an EC2 instance to an ECR respository.

We are going to do this using an IAM role, rather than an IAM user. 
In what follows, the AWS region is `us-east-1` (North Virginia).

### Create an ECR repository

In the ECR console, create a repository `ec2-ecr-test`.

### Create an IAM policy

In the IAM console, create a policy `ECRContainerise` with description `"Allows
Docker images to be built and pushed to ECR"` using the JSON

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
            "Resource": "arn:aws:ecr:us-east-1:<aws-account-id>:repository/ec2-ecr-test"
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
            "Resource": "arn:aws:ecr:us-east-1:<aws-account-id>:repository/ec2-ecr-test"
        }
    ]
}
```

### Create an IAM role

In the IAM console, create a role `containerise` with description 
`"Allows EC2 instances to containerise Docker images"`:

- Select `"AWS service EC2"` as the trusted entity type
- Attach policy `ECRContainerise` to the role

### Create an EC2 security group

In the EC2 console, create a security group `ec2-ecr-test` with description
`"SSH into instance from which to push Docker image to ECR"`:

- Inbound: `Type = SSH`, `Protocol = TCP`, `Port Range = 22`, `Source = <my-ip-address>`
- Outbound: `Type = All traffic`, `Protocol = All`, `Port Range = All`, `Destination = 0.0.0.0/0` (this is the default)

### Create an EC2 instance

In the EC2 console, create an instance `ec2-ecr-test`:

- Select AMI `"Amazon Linux AMI 2018.03.0 (HVM), SSD Volume Type - ami-0e2ff28bfb72a4e45"`
- Select instance type `t2.nano`
- Select IAM role `containerise`
- Add tag with key `Name` and value `ec2-ecr-test`
- Assign security group `ec2-ecr-test`
- Select an existing SSH key pair or download a new pair (do not proceed without a key pair)

Make a note of the instance's public IP address which will be referred to as `<ec2-ip-address>`.

### SSH into the EC2 instance

`ssh -i /path/to/my/ssh/key ec2-user@<ec2-ip-address>`

### Install Docker

`sudo yum update -y`

`sudo yum install -y docker`

`sudo service docker start`

To run Docker commands without root privileges

`sudo usermod -aG docker ec2-user`

`exit`

Log back in

`ssh -i /path/to/my/ssh/key ec2-user@<ec2-ip-address>`

Run Docker without root privileges

`docker ps`

### Create and test Docker image

Create a `Dockerfile`

```docker
FROM alpine:latest

CMD ["sh", "-c", "echo hello"]
```

Build the Docker image

`docker build --tag hello-test .`

Check it works

`docker run hello-test`

### Check the AWS CLI

Check the AWS CLI is installed and the version is prior to `1.17.10`

`aws --version` 

### Authenticate to ECR

`aws ecr get-login --region us-east-1 --no-include-email`

Copy the output and paste

`docker login -u AWS -p <my-token>`

### Push the Docker image to ECR

Tag the Docker image so that it points to the ECR repository `ec2-ecr-test`

`docker tag hello-test <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/ec2-ecr-test:v1`

Push the image to ECR

`docker push <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/ec2-ecr-test`

In the ECR console, you should see the image with tag `v1` in the repository `ec2-ecr-test`

### Clean up

In the AWS console:

- Remove ECR repository `ec2-ecr-test`
- Remove IAM policy `ECRContainerise`
- Remove IAM role `containerise`
- Terminate EC2 instance `ec2-ecr-test`
- Remove EC2 security group `ec2-ecr-test`
