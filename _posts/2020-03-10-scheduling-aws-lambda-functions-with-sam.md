---
layout: post
title: Scheduling AWS Lambda Functions with SAM
author: familyguy
comments: true
tags:
---

{% include post-image.html name="download-lambda.png" width="100" height="100" alt="lambda" %}

Serverless compute services, or Functions as a Service (FaaS), e.g. AWS Lambda, provide a cost effective,
scalable, and agile way to run scripts or programs on a schedule.

They offer a modern, superior alternative to older solutions like running Cron jobs on an always-on server.

In this post, we will run Python code on a schedule using AWS Lambda.

The main tool we will be using is the AWS Serverless Application Model Command Line Interface (SAM CLI).

To make our example more practical, our Python code will use third party libraries.

In what follows, the AWS region is `us-east-1` (North Virginia).

## AWS resources

### Create an S3 bucket

In the S3 console, create a bucket `<aws-account-id>-lambda-scheduled-task`.

### Create an IAM policy

In the IAM console, create a policy `LambdaSAMSchedule` with description `"Allows
SAM to create Lambda functions that run on a schedule"` with the JSON

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:CreateMultipartUpload"
      ],
      "Resource": [
          "arn:aws:s3:::<aws-account-id>-lambda-scheduled-task/*",
          "arn:aws:s3:::<aws-account-id>-lambda-scheduled-task"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:ListPolicies"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "cloudformation:CreateChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:DescribeStackEvents",
          "cloudformation:DescribeStacks"
      ],
      "Resource": [
          "arn:aws:cloudformation:*:aws:transform/Serverless-2016-10-31",
          "arn:aws:cloudformation:us-east-1:<aws-account-id>:stack/scheduled-task/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "cloudformation:GetTemplateSummary",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "iam:GetRole",
          "iam:CreateRole",
          "iam:PassRole",
          "iam:DeleteRole",
          "iam:GetRolePolicy",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:TagRole",
          "iam:UntagRole"
      ],
      "Resource": "arn:aws:iam::<aws-account-id>:role/scheduled-task-ScheduledTaskRole-*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "lambda:UpdateFunctionCode",
          "lambda:ListTags",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:GetFunctionConfiguration",
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:AddPermission"
      ],
      "Resource": "arn:aws:lambda:us-east-1:<aws-account-id>:function:scheduled-task-ScheduledTask-*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "events:DescribeRule",
          "events:PutRule",
          "events:RemoveTargets",
          "events:DeleteRule",
          "events:PutTargets",
          "events:EnableRule",
          "events:DisableRule",
          "events:DeleteRule",
          "events:RemoveTargets",
          "events:ListTargetsByRule"
      ],
      "Resource": "arn:aws:events:us-east-1:<aws-account-id>:rule/schedule-1"
    }
  ]
}
```

### Create an IAM user

In the IAM console, create a user `local-sam` with programmatic access. 

Attach to `local-sam` the policy `LambdaSAMSchedule` (NB: best practice is to attach `ScheduleAWSLambda` 
to a group and make `local-sam` a member of the group).

Make a note of the secret access key as this is the only time it will be available and 
will be needed later. It will be referred to as `<secret-access-key>`.

## Local development environment

Ideally, we would develop our Python code locally in an environment identical to the production
one in which it will be deployed.

In other words, we would like our local development environment to resemble as much as possible the AWS 
environment in the cloud in which Lambda functions run.

This is one advantage of SAM as it enables you to run code locally in a Docker container
that replicates the AWS Lambda environment.

### Prerequisites

- Docker
- conda

### Hello, World!

#### Create files

- `cd /my/local/path`
- `mkdir -p scheduled-task/config`
- `cd scheduled-task`
- `touch environment.yml`
- `touch app.py`
- `touch event.json`
- `touch config/template.yml`

which gives a directory structure

```
/my/local/path/scheduled-task/
├── app.py
├── config
│   └── template.yml
├── environment.yml
└── event.json
```

In our conda virtual environment `environment.yml` we only have one dependency, the SAM CLI, which is written in Python 
(latest version `0.44.0`, compatible with Python `3.6` at time of writing)

`environment.yml`

```yaml
name: scheduled-task
dependencies:
  - python=3.6
  - pip=20.0.2
  - pip:
    - aws-sam-cli==0.44.0
```

Our Python file `app.py` consists of one function that prints:

- `"Hello, World!"`
- Event that triggered the function invocation
- Context of the function invocation
- Python version

and returns a success message:

`app.py`

```python
import sys


def task(event, context):
    print('Hello, World!\n'
          f'Event: {event}\n'
          f'Context: {context}\n'
          f'Python version: {sys.version}')
    return {'success': True}
```

Our event JSON `event.json` contains a dummy event for local testing

`event.json`

```json
{
  "version": "0",
  "id": "608d7ceb-0671-2677-ac76-6a6c2b45c045",
  "detail-type": "Scheduled Event",
  "source": "aws.events",
  "account": "012345678999",
  "time": "2020-03-15T14:44:00Z",
  "region": "us-east-1",
  "resources": [
    "arn:aws:events:us-east-1:012345678999:rule/schedule-1"
  ],
  "detail": {}
}
```

Our SAM template `template.yml` (a superset of CloudFormation templates) defines the handler for our Lambda function and 
its schedule in [Rate](https://docs.aws.amazon.com/lambda/latest/dg/services-cloudwatchevents-expressions.html) 
syntax.

`config/template.yml`

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: Template for scheduling Lambda functions
Resources:
  ScheduledTask:
    Type: AWS::Serverless::Function
    Properties:
      Runtime: python3.7
      Handler: app.task
      CodeUri: ..
      Timeout: 10
      Events:
        RateSchedule:
          Properties:
            Description: Schedule for testing and demo purposes
            Enabled: true
            Name: schedule-1
            Schedule: rate(3 minutes)
          Type: Schedule
```

_Why is the Python version `3.7` not the same as in `environment.yml`, `3.6`?_

The Python version in `template.yml` refers to the Python version in the Docker container run 
locally by SAM and in the AWS Lambda runtime environment.

It is the Python version that runs the code in `app.py`.

The Python version in `environment.yml` refers to the version that runs inside the conda virtual
environment (that the SAM CLI depends on).

_Why is `CodeUri` set to `..`?_

Because `app.py` is one level above `config/template.yml` in the directory hierarchy.

#### Test it works

Build and activate the conda environment

- `conda env create --file environment.yml`
- `conda activate scheduled-task`

Check we are using Python in the virtual environment and that its version is `3.6`

- `which python`
- `python --version`

Check the SAM CLI is installed `sam --version`.

Create environment variables for the SAM CLI

- `export AWS_ACCESS_KEY_ID=<access-key-id>`
- `export AWS_SECRET_ACCESS_KEY=<secret-access-key>`
- `export AWS_DEFAULT_REGION=us-east-1`

where `<access-key-id>` is in the IAM console under the user `local-sam` and `"Access key ID"`.

Validate the template `sam validate --template config/template.yml`.

Assuming successful validation, invoke our Lambda function:

`sam local invoke ScheduledTask --event event.json --template config/template.yml`.

(Add `--debug` for troubleshooting).

The first time `sam local invoke` runs, it pulls down the Docker image `lambci/lambda`. This will probably take a while
as it is almost `1 GB` in size.

In subsequent runs, add `--skip-pull-image` to avoid pulling down the image again.

If the Lambda function is invoked successfully, you should see some something like:

`Invoking app.task (python3.7)`

`Mounting /Users/guy/Documents/blog-post-repos/scheduled-task as /var/task:ro,delegated inside runtime container`

`START RequestId: 61fc63e3-b7d5-1031-6deb-89fbfac4e697 Version: $LATEST`

`Hello, World!`

`Event: {'version': '0', 'id': '608d7ceb-0671-2677-ac76-6a6c2b45c045', 'detail-type': 'Scheduled Event', 'source': 'aws.events', 'account': '012345678999', 'time': '2020-03-15T14:44:00Z', 'region': 'us-east-1', 'resources': ['arn:aws:events:us-east-1:012345678999:rule/schedule-1'], 'detail': {}}`

`Context: <bootstrap.LambdaContext object at 0x7fcdf65cff90>`

`Python version: 3.7.6 (default, Feb  5 2020, 14:03:26)`

`[GCC 4.8.3 20140911 (Red Hat 4.8.3-9)]`

`END RequestId: 61fc63e3-b7d5-1031-6deb-89fbfac4e697`

`REPORT RequestId: 61fc63e3-b7d5-1031-6deb-89fbfac4e697	Init Duration: 1400.57 ms	Duration: 32.67 ms	Billed Duration: 100 ms	Memory Size: 128 MB	Max Memory Used: 23 MB	`

`{"success":true}`

### A more interesting example

Let's modify our Lambda function so that it extracts some text from the Wikipedia homepage. 

We will use the third party libraries `requests` and `pyquery` to do so.

#### Update files

As our Lambda function requires `requests` and `pyquery`, we have to specify these two
libraries in `requirements.txt` as dependencies

`requirements.txt`

```
requests==2.23.0
pyquery==1.4.1
```

To make use of these two libraries and extract some text from Wikipedia, update `app.py` accordingly

`app.py`

```python
import sys

import requests
from pyquery import PyQuery


def task(event, context):
    print('Hello, World!\n'
          f'Event: {event}\n'
          f'Context: {context}\n'
          f'Python version: {sys.version}')
    r = requests.get('https://www.wikipedia.org/')
    pq = PyQuery(r.content)
    for div in pq('div').filter('.central-featured-lang').items():
        print(f'Language: {div("a strong").text()}')
    return {'success': True}
```

#### Test it works

Download `pyquery` and `requests`

`sam build --template config/template.yml --manifest requirements.txt`

In `/my/local/path/scheduled-task/.aws-sam/build` 
you should see the project files copied over with all third party dependencies.

Invoke the Lambda function

`sam local invoke ScheduledTask --event event.json --template .aws-sam/build/template.yaml --skip-pull-image`

which should output something like

`Language: English`

`Language: Español`

`Language: 日本語`

`Language: Deutsch`

`Language: Русский`

`Language: Français`

`Language: Italiano`

`Language: 中文`

`Language: Português`

`Language: Polski`

NB: each time you make changes to the code you need to build again, i.e.

`sam build --template config/template.yml --manifest requirements.txt && sam local invoke ScheduledTask --event event.json --template .aws-sam/build/template.yaml --skip-pull-image`

## Deploy to production

First, package up the Lambda function.

This takes your code and dependencies and pushes it to our S3 bucket.

Another win for SAM users is the automation around zipping up the Lambda function and pushing it to the S3 bucket. The sam package command zips up your code and artifacts, pushes them to S3 and outputs a modified SAM template ready for deployment via CloudFormation

Run the command

`sam package --template-file .aws-sam/build/template.yaml --output-template-file packaged.yml --s3-bucket <aws-account-id>-lambda-scheduled-task`

can see the new output file `packages.yml` which is basically the same as `template.yml` except the codeUR
points to S3 bucket object.

In s3, can check the bucket now has a new object.

Deploy

`sam deploy --template-file packaged.yml --stack-name scheduled-task --capabilities CAPABILITY_IAM`

Should see the Lambda function in Lambda console. And should see it invoke every 3 minutes with the same
logs as when run locally but now in the CloudWatch console.

## Clean up

- S3 
- IAM
- CloudFormation