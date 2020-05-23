---
layout: post
title: Scheduling AWS Lambda Functions with SAM and GitLab CI/CD
author: familyguy
comments: true
tags:
---

{% include post-image.html name="download-lambda.png" width="100" height="100" alt="" %}


Assuming you have followed the preivous post.

But change IAM user from `local-sam` to `gitlab-sam`
add env vars to gitlab (plus one extra for aws account id)
change python version in conda env to 3.7 so that it matches runtime in template
(required as SAM build looks for the runtime Python version locally so those Python
versions cannot be differetn contrary to previous post)

Each build in GitLab does create a new file in S3, but there is only ever one
function in Lambda (which gets updated with new code each time you there
is a new build in GitLab)

Update clean up