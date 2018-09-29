---
layout: post
title: Python Documentation With Read the Docs
author: familyguy
comments: true
---

{% include post-image.html name="logo.png" width="75" height="75" alt="Read 
the Docs logo" %}

This post is aimed at those developing Python packages who would like to use
 [Read the Docs](https://readthedocs.org/) for their documentation.
 
## Getting it to run locally
 
- Pull down the latest code and create a new branch
- Add some docstrings to your code 
- Add `sphinx` and `sphinx-autobuild` to `requirements.txt`
- `pip install --requirement requirements.txt`
- From the project root, `mkdir docs`
- `cd docs`
- `sphinx quickstart`
- Enter values as required, e.g. `<project-name>` when prompted for the 
project name
- If unsure, just enter the default. Personally, I use the defaults except for:
    * `autodoc: automatically insert docstrings from modules (y/n) [n]`, 
    yes
    * yes to Mathjax
    * no to creating a Windows command file
- Once done, this generates `conf.py` which you can modify if 
you'd like to alter any of your choices above or set values you weren't 
prompted for, e.g. I like to set the theme to `sphinx_rtd_theme`
- From the project root, `sphinx-apidoc -o docs/_modules <project-name>` 
(this scans your code for docstrings and outputs the results in `.rst` 
files, the convention is for them to go into a `_modules` directory)
- Next, generate the HTML from the `.rst` files
- `cd docs`
- `make html`
- If you get a theme error, add any missing packages to `requirements.txt` 
and `pip install --requirement requirements.txt`
- Add `docs/_build` to `.gitignore` 
- View your docs in the browser at 
`/path/to/project-root/docs/_build/html/index.html` (note RTD has a nice 
feature where it ignores any docstrings in a class's private methods, i.e. 
those with a name beginning with an underscore)
- Update docstrings as required and rebuild HTML, `make html`

## Getting your docs online

Here, we assume your package's source code is on Github.

- Sign up and login to RTD
- In the top right corner (where email or username is displayed) under 
***settings->connected services,*** add Github
- In Github, go to your project's repository; under 
***settings->integrations and services->add service***, add RTD
- In RTD, under ***email/username->my projects->import a project*** you should 
see a list of your repositories in Github
- Add your project; a build should be kicked off automatically
- Under ***project->overview***, you should see on the right your docs' URLs, 
e.g. 
`http://<project-name>.readthedocs.io/<lang>/latest`
which should display a welcome message
- In Github, under ***settings->webhooks*** you should see something from RTD
- Commit your changes, push up and merge / wait to be merged your new 
branch into master; this should kick off a build in RTD
- Check the status of the build under ***project-name->builds***
- Check the RTD URL

## Troubleshooting

Even if a build succeeds, in RTD you may not see your docstrings
 / have 404s. 

In RTD, under ***project-name->builds->build***, expand the log messages 
and check for errors.

To fix these, I had to

- Under ***projects->my-project->admin->settings***, set ***documentation 
type*** to `sphinx htmldir`, and ***programming language*** to `python`
- Under ***advanced settings->install project***, check ***install your 
project inside a virtualenv***, set ***python configuration file*** to 
`docs/conf.py` and ***python interpreter*** to `3.x`
 
I also had to downgrade one of my package's dependencies that wasn't 
compatible with the version of Python (3.5) running on RTD. 
