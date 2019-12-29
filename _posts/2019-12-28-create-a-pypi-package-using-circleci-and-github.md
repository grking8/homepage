---
layout: post
title: Create a PyPI Package Using CircleCI and GitHub
author: familyguy
comments: true
tags: python pypi pypi-package python-library python-package
---

{% include post-image.html name="language-2024210_1280.png" width="100" height="100" 
alt="python logo" %}

The aim of this post is to give an overview of the process rather than a full blow by blow 
account.

As such, there may be some gaps; feel free to ask for clarifications
in the comments section at the bottom!

The post assumes some familiarity with Python, Git, GitHub, and the command line on Linux / macOS, as well
as some knowledge of CircleCI (or similar).

It will try to not assume any knowledge of PyPI.

## What is PyPI?

PyPI is an abbreviation for Python Package Index. PyPI is an online repository for Python code.

All the code on PyPI is publicly available.

A file containing Python code is known as a module; a directory containing modules 
(with one module called `__init__.py`) is known as a package. Typically, such a directory only contains modules.

Thus PyPI is just a place where lots of packages live.

Packages can also be referred to as libraries, tools, apps, plugins, third-party this and that, ...

If you have done any real world programming with Python, you most likely have used a PyPI package in your code.

For example, the PyPI package `requests`, which you might have installed like this

```bash
pip install requests
```

and used in code like this

```python
import requests


r = requests.get('http://bbc.co.uk')
```

Here are some other [popular PyPI packages.](https://hugovk.github.io/top-pypi-packages/)

Usually, the PyPI package you are using was written by someone else.

However, if you have written a package that you would like to make 
public and part of the Python ecosystem, uploading it to PyPI is the standard solution
and you have come to the right place 😉.

## Definitions

A package is a directory of modules, one of which is `__init__.py`.

We define such packages as *Python packages*.

To make a Python package available on PyPI, a file `setup.py` is required which, 
amongst other things, contains metadata about a Python package.

`setup.py` lives in the same directory as a Python package.

Thus for a Python package `<python-package>`, we have the following directory structure

```
└── some-dir
    ├── <python-package>
    └── setup.py
```

`some-dir` often contains other files, in addition to `setup.py`, related to `<python-package>`
, e.g. documentation,
licences, configuration, tests, scripts, ...

We define directories like `some-dir` as *PyPI packages*, i.e.

`PyPI package = Python package + setup.py + other files`

So for a PyPI package `<pypi-package>`, we have 

```
└── <pypi-package>
    ├── <python-package>
    └── setup.py
```

One of the key metadata in `setup.py` is the __name__ that `<pypi-package>` is referred to in PyPI, 
which we will note as `<pypi-distribution>`.

## Naming (skip if in a hurry)

### Python packages

In theory, `<python-package>` follows the same rules as for [naming 
variables in Python](https://realpython.com/python-variables/)

> ...variable names in Python can be any length and can consist of uppercase and lowercase letters (A-Z, a-z), digits (0-9), and the underscore character (_). An additional restriction is that, although a variable name can contain digits, the first character of a variable name cannot be a digit.

However, [according to PEP](https://stackoverflow.com/questions/33712857/are-there-rules-for-naming-single-module-python-packages)

> Modules should have short, all-lowercase names. Underscores can be used in the module name if it improves readability. __Python packages should also
have short, all-lowercase names, although the use of underscores is discouraged.__

In reality, underscores in Python packages is completely fine and conventional.

### PyPI packages

As `<pypi-package>` is a directory, it can be any legal directory name as per the operating system.

However, this directory is also a repository in GitHub so it must be a legal GitHub repository name,
which means, amongst other things, there cannot be a repository with the same name for the user in question.

### PyPI distributions

`<pypi-distribution>` must follow the [rules specified by PyPA (Python Packaging Authority)](https://packaging.python.org/tutorials/packaging-projects/)

> ...name is the distribution name of your package. This can be any name as long as (sic) only contains letters, numbers, _ , and -. It also must not already be taken on pypi.org.

To see if a name is taken on `pypi.org`, [search projects on PyPI.](https://pypi.org)

The convention is [to use hyphens rather than underscores](https://stackoverflow.com/questions/52827722/folder-naming-convention-for-python-projects),
e.g. `flask-cors` rather than `flask_cors`.

### (Opinionated) conclusion

- Choose `<my-name>` using only lowercase letters and numbers; if too unreadable, 
separate words using hyphens, e.g. `my-very-long-pkg-name` rather than `myverylongpkgname`; `<my-name>` __must be available in PyPI and GitHub.__
- Set `<pypi-distribution>` and `<pypi-package>` equal to `<my-name>`
- If `<my-name>` has hyphens, set `<python-package>` equal to `<my-name>` with the hyphens 
replaced with underscores; otherwise set `<python-package>` equal to `<my-name>`

### Effect on end user

```bash
pip install <pypi-distribution>
```

```python
import <python-package>
```

`<pypi-distribution>` and `<python-package>` are not always the same, e.g. 

```bash
pip install beautifulsoup4
```

```python
import bs4
```

## Steps

### Check name is available in GitHub and PyPI

I checked and chose `pyexample` (in the remaining steps, replace `pyexample` and any other values as appropriate).

### Create repository in GitHub

- On local machine, `cd` to path where you would like to create files
- `mkdir pyexample`
- In GitHub, create a repository `pyexample`
- On local machine, `git init` to make `pyexample` a Git repository
- Locally, point `pyexample` to GitHub repository
    - `git remote add origin git@github.com:grking8/pyexample.git` (convention is to call the remote
repository `origin`)
    - `git remote -vv` to check
- Add a file and push up
    - `touch README.md`
    - `git add README.md`
    - `git commit -m 'Add docs'`
    - `git push origin master`
- You should see your repository in GitHub with one file `README.md`.

### Add files to local repository

- Choose a Python version; I chose `3.6`
- `cd /path/to/pyexample`
- `mkdir -p pyexample/utils`
- `touch pyexample/__init__.py`
- `touch pyexample/utils/__init__.py`
- `touch pyexample/utils/pi.py`
- `touch setup.py`

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

```python
# setup.py
from setuptools import find_packages, setup


setup(
    name='pyexample',
    version='0.0.1',
    python_requires='>=3.6,<3.7',
    packages=find_packages(),
    classifiers=[
        'Development Status :: 1 - Planning',

        'Intended Audience :: Developers',

        'Programming Language :: Python :: 3.6',
    ],
    author='Guy King',
    author_email='grking8@gmail.com',
    license='MIT',
    url='https://github.com/grking8/pyexample.git',
)
```

```python
# pyexample/utils/pi.py
import math


def get_pi_digit(n):
    digits = list(str(math.pi))
    digits.remove('.')
    return int(digits[n-1])
```

```python
# pyexample/__init__.py
from .utils.pi import get_pi_digit


__version__ = '0.0.1'
```

### Setup PyPI account

- If not already done, [sign up for a PyPI account](https://pypi.org/account/register/)
- Under `Account Settings`, create an API token with scope `whole account` (as package not yet uploaded; 
change to `project level` scope once uploaded)
- Give the API token a name
- Make a note of the API token `<my-api-token>` (should start with `pypi-`)

### Integrate CircleCI with GitHub

- Authorise CircleCI to connect with GitHub
- In CircleCI, click `Add project`
- Add newly created GitHub repository
- Trigger a build (which will fail)
- Add environment variables in CircleCI
    - Click on a job
    - Click the settings wheel
    - Click `Environment Variables`
    - Add variable; name `PYPI_USERNAME`, value `__token__`
    - Add variable; name `PYPI_PASSWORD`, value `<my-api-token>`

### Create CircleCI workflow

- `mkdir build-scripts`
- `touch build-scripts/upload-project.sh`
- `chmod u+x build-scripts/upload-project.sh`

```bash
# build-scripts/upload-project.sh
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

- `mkdir .circleci`
- `touch .circleci/config.yml`

```yaml
# .circleci/config.yml
defaults: &defaults
  docker:
    - image: continuumio/miniconda3:latest
  working_directory: ~/repo

version: 2
jobs:

  build:
    <<: *defaults
    steps:
      - checkout
      - run:
          name: Install Python
          command: conda install python=3.6
      - run:
          name: Create package distribution
          command: python setup.py sdist
      - persist_to_workspace:
          root: dist
          paths:
            - .

  pypi:
    <<: *defaults
    steps:
      - checkout
      - attach_workspace:
          at: dist
      - run:
          name: Upload package
          command: build-scripts/upload-project.sh

workflows:
  version: 2
  build-pypi:
    jobs:
      - build
      - pypi:
          requires:
            - build
          filters:
            branches:
              only: master

```

- Push up changes to GitHub
- Watch build...

### Debug CircleCI workflow

If the build fails with a message like

```
TTPError: 403 Client Error: The credential associated with user 'kinggu' isn't allowed to upload to project 'PyExample'. See https://pypi.org/help/#project-name for more information. for url: https://upload.pypi.org/legacy/
```

it could be that although `<pypi-distribution>` did not show up in the search, it
is unavailable because it is too similar to an existing distribution.

In my case, `pyexample` failed because there was already a distribution called `py-example`:

- Choose another name, making sure it differs by more than a hyphen or underscore to all existing distributions
- In my case, I chose `python-pypi-example`
- Update `name` in `setup.py`
- Push change up to GitHub
- Watch build...
- If build is successful, you should see a new distribution in your PyPI account.
- Delete `<my-api-token>` and create a new one with project level scope
- Update environment variables in CircleCI
- Update names from `pyexample` to `python-pypi-example`:
     - In GitHub, rename the repository
     - Locally, remove repository `rm -rf pyexample`
     - `git clone git@github.com:grking8/python-pypi-example.git` to clone from GitHub the renamed repository
     - `grep -nrw 'pyexample'` and change where appropriate to `python-pypi-example`
- Bump version to `0.0.2` in `setup.py` and `python_pypi_example/__init__.py`
- Push up changes to GitHub
- Watch build...
- Should see distribution with updated version in PyPI account

### Test new PyPI package

- `rm -rf /path/to/python-pypi-example`
- `conda create --name my-test-env python=3.6`
- `conda activate my-test-env`
- `which pip` to check you are using `pip` in the conda virtual environment
- `pip install python-pypi-example`
- `touch mytest.py`

```python
# mytest.py
from python_pypi_example import __version__, get_pi_digit

print(__version__)
print(get_pi_digit(3))
```

- `python mytest.py`

```
0.0.2
4
```
