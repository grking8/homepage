---
layout: post
title: Scheduling AWS Lambda Functions with SAM and GitLab CI/CD
author: familyguy
comments: true
tags:
---

{% include post-image.html name="download-lambda.png" width="100" height="100" alt="" %}

In the
[previous post](https://www.guyrking.com/2020/03/10/scheduling-aws-lambda-functions-with-sam.html),
we saw how to run Python code on a schedule using AWS Lambda.

We used the SAM CLI to deploy our Python code to AWS from our local machine.

In this post, we will setup a CI/CD pipeline in GitLab to automate the
deployment of our Python code.

## AWS resources

[Create AWS resources](https://www.guyrking.com/2020/03/10/scheduling-aws-lambda-functions-with-sam.html#aws-resources)
as per the previous post, replacing the user name `local-sam` with `ci-cd-sam`.

## Local Git repository

```
scheduled-task/
├── app.py
├── config
│   └── template.yml
├── deploy-scripts
│   ├── build-env.sh
│   ├── deploy.sh
│   └── package.sh
├── environment.yml
├── .gitlab-ci.yml
└── requirements.txt
```

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

`config/template.yml`

```yaml
AWSTemplateFormatVersion: "2010-09-09"
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

`deploy-scripts/build-env.sh`

```bash
#!/usr/bin/env sh

set -xe

echo "Update conda"
conda update conda
echo "Build conda environment"
conda env update --name root --file environment.yml
```

`deploy-scripts/deploy.sh`

```bash
#!/usr/bin/env sh

set -xe

sam deploy --template-file packaged.yml --stack-name scheduled-task --capabilities CAPABILITY_IAM
```

`deploy-scripts/package.sh`

```bash
#!/usr/bin/env sh

set -xe

echo "Check SAM template is valid"
sam validate --template config/template.yml
echo "Create package"
sam build --template config/template.yml --manifest requirements.txt
echo "Upload package to S3"
sam package \
    --template-file .aws-sam/build/template.yaml \
    --output-template-file packaged.yml \
    --s3-bucket "${AWS_ACCOUNT_ID}-lambda-scheduled-task"
```

`environment.yml`

```yaml
name: scheduled-task
dependencies:
  - python=3.7
  - pip=20.0.2
  - pip:
      - aws-sam-cli==0.44.0
```

`.gitlab-ci.yml`

```yaml
stages:
  - package
  - deploy

before_script:
  - ./deploy-scripts/build-env.sh

package:
  stage: package
  image: continuumio/miniconda3:latest
  script:
    - ./deploy-scripts/package.sh
  artifacts:
    paths:
      - packaged.yml

deploy:
  stage: deploy
  image: continuumio/miniconda3:latest
  script:
    - ./deploy-scripts/deploy.sh
```

`requirements.txt`

```
requests==2.23.0
pyquery==1.4.1
```

Ensure this local Git repository points to your GitLab repository.

## GitLab environment variables

In your GitLab repository, set the following environment variables:

- `AWS_DEFAULT_REGION` equal to `us-east-1`
- `AWS_ACCOUNT_ID`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Deploy

- `cd /path/to/scheduled-task`
- `git add .`
- `git push`

You should see the CI/CD pipeline running in GitLab.

After the pipeline has finished, the Python code in the Lambda function should
run every three minutes (you can check this in the Lambda or CloudWatch
console).

In the local repository, make some changes to the logs, e.g. replace

```python
print('Hello, World!\n'
```

with

```python
print('Hello, Universe!\n'
```

and push up again.

After a few minutes, you should again see the Lambda function's logs in AWS, but
this time with the new message.

## Clean up

In the AWS console:

- Remove S3 bucket `<aws-account-id>-lambda-scheduled-task`
- Remove IAM policy `LambdaSAMSchedule`
- Remove IAM user `ci-cd-sam`
- Remove CloudFormation stack `scheduled-task`
- Remove CloudWatch log group `/aws/lambda/scheduled-task-ScheduledTask-<id>`

On your local machine, remove the directory `/path/to/scheduled-task`.

In GitLab, remove the repository that `/path/to/scheduled-task` points to.
