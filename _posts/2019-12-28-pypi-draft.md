---
layout: post
title: PyPI Draft
author: familyguy
comments: true
tags: python
---

{% include post-image.html name="cof_orange_hex_400x400.jpg" width="100" height="100" 
alt="ubuntu logo" %}

Firstly, terminology

PyPI = Python package index

So it contains Python packages, e.g. `requests`. You might also see them
referred to as libraries.

Not to be confused with a directory of Python files (modules) which is also
known as a package. 

These are the most popular PyPI packages - https://hugovk.github.io/top-pypi-packages/

We are going to create a minimal Python package and show how it can be published
to PyPI via CI (CircleCI)

First, naming conventions

These are the restrictions

>
name is the distribution name of your package. This can be any name as long as only contains letters, numbers, _ , and -. It also must not already be taken on pypi.org.

taken from https://packaging.python.org/tutorials/packaging-projects/

naming is a bit awkward
couplel of sources
https://stackoverflow.com/questions/33712857/are-there-rules-for-naming-single-module-python-packages
https://stackoverflow.com/questions/52827722/folder-naming-convention-for-python-projects

basically there are a few things to consider

- the name of the package on PyPI. this only has to meet the guidelines below

>
name is the distribution name of your package. This can be any name as long as only contains letters, numbers, _ , and -. It also must not already be taken on pypi.org.

Now convention is to NOT have underscores in this, but to use hyphens if it 
improves readability, but to not use hyphens if you can, e.g. `pytz`, but
something like `flask-cors` rather than `flaskcors` or `sqlalchemy-searchable`
rather than `sqlalchemysearchable`. 

The other things to name are

the repository, e.g. in GitHub. This is the name of the project folder, which
contains the Python code of your PyPI package.

A PyPI package repository contains Python files (modules) and directories
containing Python files (packages).

PEP says modules should be in lowercase, and separated with underscores, 
and packages should be lowercase, no underscores. 

In reality, packages can have underscores, this is completely fine.

Further, in your PyPI package, there is an actual packages (directory) of 
modules, which is what gets installed when a user does `pip install ..`.

This can be different to the name of the package in PyPI

The convention is for the name of the PyPI package to be exactly the same as the
name of the project repository, e.g.

```
└── my-pypi-package
    ├── my_pypi_package
    └── setup.py
```

which corresponds to a PyPI package called `my-pypi-package`

So basically you have to check if your name is available in PyPI and GitHub.

This name will be all lowercase, and might have hyphens to improve readability,
but no hyphens if you can get away with it.

This name above is used as the name of the package distribution in PyPI, and
the repo in GitHub.

In your repo, you then have a package (which contains the actual library) which 
is mapped from the name above. Basically, it is the same, replacing hyphens 
with underscores, e.g. `pytz` maps to `pytz`, `my-long-package-name` maps to
`my_long_package_name`.

The GitHub check for your repository name occurs when you create it. It is 
not very restrictive, you just have to make sure there does not already exist
a repo with the same name in your account, e.g. I could make a repo call `django`

The bigger restriction is on PyPI, which you check by searching here - https://pypi.org
under search projects.

Once you have your names sorted out, off you go

- `mkdir pyexample` on local machine
- In GitHub, create a repo `pyexample`
- Make your folder a git repo `git init` in project root
- Link the GitHub repo with your local project (convention is to call the remote
repository 
`origin`); `git remote add origin git@github.com:grking8/pyexample.git`
- check with `git remote -vv`
- Add a file and push up `touch README.md`; `git add README.md`;
`git commit -m 'Add docs'`; `git push origin master`
- You should see your repo in GitHub with the REadme file

Now make your actual package (the one that gets downloaded when 
people do `pip install pyexample`)

- Other key step is to choose the Python version

then you end up with this

```
pyexample/
├── pyexample
│   ├── __init__.py
│   └── utils
│       ├── __init__.py
│       └── pi.py
├── README.md
└── setup.py

```

with content 

```python
from setuptools import setup


package_name = 'pyexample'
version = '0.0.1'
classifiers = [
    'Development Status :: 1 - Planning',

    'Intended Audience :: Developers',

    'Programming Language :: Python :: 3.6',
]

setup(
    name=package_name,
    version=version,
    classifiers=classifiers,
    author='Guy King',
    author_email='grking8@gmail.com',
    license='MIT',
    url='https://github.com/family-guy/pyexample.git',
)
```

```python
import math


def get_pi_digit(n):
    digits = list(str(math.pi))
    digits.remove('.')
    return int(digits[n-1])
```

and 

```python
from .utils.pi import get_pi_digit
```

Then you do the CI part with CircleCI, (specifying the same Python version as
above)

So setup your GitHub repo in CircleCI so the integration is done

Create API token in PyPI
Set scope to be whole account (as it is a future project)
Name the token, here I used `pyexample`
Once done, lower the scope to one project only rather than whole account


In circleCI, add project `pyexample` and start buildingn (it will fail as
no `config.yml`)

Now you can add the environment variables in circleci

`PYPI_USERNAME` to be the value of `__token`
and `PYPI_PASSWORD` as per the token in PyPI (`pypi-....`)

have to add the build scripts

in project root, `build-scripts/upload-project.sh`

```bash
#!/usr/bin/env bash

set -e

PYPI_CONFIG="${HOME}/.pypirc"
pip install --upgrade pip
pip install twine
echo $'[distutils]\nindex-servers = pypi\n[pypi]' > $PYPI_CONFIG
echo "username=$PYPI_USERNAME" >> $PYPI_CONFIG
echo "password=$PYPI_PASSWORD" >> $PYPI_CONFIG
twine upload dist/*.tar.gz
```

so project now looks like

```bash
pyexample/
├── build-scripts
│   └── upload-project.sh
├── pyexample
│   ├── __init__.py
│   └── utils
│       ├── __init__.py
│       └── pi.py
├── README.md
└── setup.py
```

then push up to github should trigger build in circleci

Once you can see it in PyPI, you can test

after testing, lower scope of token,
bump version in `setup.py`, and rebuild

at this point, you might find that although your PyPI package name was free
when you did the search, in my case `pyexample`, it might not actually work
because of https://pypi.org/help/#project-name

so have to give it another name (in my case, there was `py-example` already taken)

This is quite annoying as means have to rename lots of things to change

First lets find a name that works by setting a new name in `setup.py`

this time it worked. so time to do the renaming and change the scope of the token

-in github, in repo, go to settings, repository name

locally, remove your current repo `rm -rf pyexample`

clone from gh the renamed repo

`git@github.com:grking8/python-pypi-example.git`

then change the names within the project

do `grep -nrw 'pyexample` to check if anywhere else

(there was one change to do in `setup.py` for the url)

Bump the version

In pypi account settings, you cannot change the name or the scope of the api
token, need to delete and create a new one. can now set the scope correctly
as project already exists. copy new token into circleci `PYPI_PASSWORD`

Rerun build in cirlcleci

Now, do the test:

If you like, do it on another computer or remove `python-pypi-example` from
local file system

`conda create --name test-blah python=3.6`
`conda activate test-blah`

`which pip`
`pip install python-pypi-example`

which installs it in your env, you wont see the downloaded package in your
current working directory. and the commands below should work whereever you
are, as long as you have `test-blah` activated

`which python`
`python`
```python
import python_pypi_example

python_pypi_example.get_pi_digit(3)
```

outputs `4`



- You have to bump the version, otherwise the upload to PyPI fails (because
if there is a package already there with the same name, the only
way you can be allowed to upload is if it has a different version)