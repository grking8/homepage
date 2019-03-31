---
layout: post
title: Python Imports 101
author: familyguy
comments: true
---

{% include post-image.html name="2416585_0.jpg" width="100" height="100" 
alt="python logo" %}

Python is well known for being one of the more beginner friendly programming
languages.

However, certain aspects can seem a bit mysterious and have a tendency to 
frustrate those lacking experience:

- Multitude of files imported (standard library, third-party, preinstalled vs 
user installed, user created)
- Multitude of import methods (file vs. package imports, 
absolute package imports vs. relative package imports)
- Multiple interpreters (preinstalled vs user installed, different 
versions, e.g. Python 2.7 vs Python 3.6)
- Installation of third-party libraries (different package managers 
and cloud repositories)
- Virtual environments
- Creation of your own libraries and making them accessible to others

Further, these aspects can vary across platforms 
(Linux, macOS, Windows,...) and sometimes even experienced 
developers coming to Python from other languages can find themselves in
sticky situations, e.g. "I think I did something 
to my system Python" or are left scratching their heads.

In this post we are going to take a first pass at the first two points 
and provide an introduction to imports in Python, trying a "first 
principles" approach.

The examples in the post were run on Ubuntu 16.04. Whilst details will 
vary, the general concepts should be platform agnostic (although Windows
users may have a harder time following).

## Python interpreters

Before getting on to imports, a few words on interpreters
as without an interpreter we won't be importing anything!

On Linux / macOS, usually at least one Python interpreter comes preinstalled.

In reality, any preinstalled Python interpreter should not be used 
for development work.

However, in this post we will do so to 
avoid the extra step of installing and using our own 
interpreter in a virtual envrionment.

On a clean Ubuntu OS, there is a Python 2 interpreter, e.g.

`/usr/bin/python2.7`

and a Python 3 interpreter, e.g.

`/usr/bin/python3.5`

preinstalled (from hereon examples will 
refer to Python 3) as well as Python libraries:

- Standard library in `/usr/lib/python3.5`
- Third-party libraries in `/usr/lib/python3/dist-packages`

but your mileage may vary, e.g. you might have only files and
directories from the standard library preinstalled or only one 
interpreter.

In my case, I had directories like 
`requests`, `bs4` in `/usr/lib/python3/dist-packages`.

In your 
standard library directory, you should see files like `random.py` that
are part of the standard library.

At a minimum, you should have an interpreter and 
the standard library preinstalled.

## Out-of-the-box imports

If you write in a Python script or Python shell
(assuming you have a `requests` directory in 
`/usr/lib/python3/dist-packages`)

```python
import random
import requests

requests.get('http://bbc.co.uk')
random.randint(0,10)
```
just works - you have successfully imported and used two 
libraries.

A couple of points:

- The imported library might be a file, e.g. `random.py` or a 
directory, e.g. `requests`.
- The `import` statements make no reference to any directory paths; how does
Python know where to find the relevant files?

The answer is the **Module Search Path (MSP).** 

The MSP is a variable set at the start of each script / 
Python shell session.

The MSP is a list of directory paths. 

If you write `import johnny-cache`, 
Python will take the first directory path in the MSP and see if 
there is a file or directory called `johnny-cache` in that 
directory. 

If it so, it 
will do the import. If not, it will move on to the second path
in the list, etc.

What paths are in the MSP?

- "Home" - if you are running a script, this is the directory of
the script; if you are in a Python shell, it is the current
working directory
- `PYTHONPATH` environment variable
- Directory containing the standard library
- Directory containing user installed third-party libraries
- Directory containing preinstalled third-party libraries

To see for yourself,

```bash
$ /usr/bin/python3.5 -m site  # working directory /home/jim
```

```python
sys.path = [
    '/home/jim',  # "home"
    '/usr/lib/python3.5',  # standard libraries
    '/usr/local/lib/python3.5/dist-packages',  # user installed third party libraries
    '/usr/lib/python3/dist-packages',  # preinstalled third-party libraries
]
```

(there maybe others too, but above are usually of most 
interest).

The MSP is important. If it is empty, you won't be able to
import anything...

```python
import sys

sys.path = []
import random  # ImportError: No module named 'random'
import requests  # ImportError: No module named 'requests'
```

## Importing your own code

Let's first take a look at file imports.

### File imports

Suppose you have the following directory structure

```
import_examples/
└── dir0
    ├── a.py
    ├── b.py
    └── dir1
        └── c.py
```

with Python files

```python
# a.py
import b

print(b.x)
```

```python
# b.py
x = 'hello'
```

```python
# c.py
y = 'bye'
```

If we do 

```bash
$ cd /path/to/import_examples
$ /usr/bin/python3.5 dir0/a.py  # hello
```

We can see in `a.py`,

`import b` 

is successful as the first path in the MSP is "home", the 
directory containing `a.py`, i.e.

`/path/to/import_examples/dir0`

Thus when the interpreter runs `import b`
the first file it looks for is

`/path/to/import_examples/dir0/b.py`

which exists so its contents are imported! The interpreter then
moves on to the next line in `a.py`.

So far, so good.

Now, say we modify `a.py`

```python
# a.py
import b
import c  # extra import

print(b.x)
print(c.y)
```

Then

```bash
$ /usr/bin/python3.5 dir0/a.py
``` 

gives an error

```
Traceback (most recent call last):
  File "import_examples/dir0/a.py", line 2, in <module>
    import c
ImportError: No module named 'c'
```

Why? Because for `import c`, the interpreter goes through the MSP as
before. It first looks for a file `/path/to/import_examples/dir0/c.py`.

As no such file exists, it looks for the next path in the MSP

`/usr/lib/python3.5/c.py`

which also does not exist. Then

`/usr/local/lib/python3.5/dist-packages/c.py`

`/usr/lib/python3/dist-packages/c.py`

neither of which exist. Having gone through all the paths in the MSP, 
the interpreter throws an `ImportError`.

To get around this, we could add the path of the directory containing 
`c.py` 

`/path/to/import_examples/dir0/dir1`

to `sys.path`

 ```python
 # a.py
import b

import sys
sys.path.append('/path/to/import_examples/dir0/dir1')

import c
```

or `PYTHONPATH`.

However, it's easy to imagine how this could quickly get tedious. 
A better way is to use package imports instead.

### Package imports

Just as a file containing Python code is known as a module, a directory
containing modules is known as a **package**.

#### Absolute package imports

Let's add `__init__.py` to `dir1`

```
import_examples/
└── dir0
    ├── a.py
    ├── b.py
    └── dir1
        ├── __init__.py
        └── c.py
```

and modify `a.py`

```python
import b
import dir1.c  # absolute package import

print(b.x)
print(dir1.c.y)
```

Now

```bash
$ /usr/bin/python3.5 dir0/a.py
# hello
# bye
``` 

works because Python has something called **absolute
package imports** which start with `import` followed
by dot notation, e.g.

`import dir1.dir2.dir3.dir4.file5`
where
`dir1`, `dir2`, `dir3`, `dir4` each contain an `__init__.py`
file (this lets Python know the directory is a package).

The interpreter processes an absolute package import the
same way as before, replacing the dots with path separators, e.g. the first
file

`import dir1.c`

it goes through the paths in the MSP in the same way as before, 
replacing the dots with path separators.

#### Relative package imports

To see these in action, let's update our directory tree to

```
import_examples/
└── dir0
    ├── a.py
    ├── b.py
    └── dir1
        ├── __init__.py
        ├── c.py
        └── dir2
            └── d.py
```

with files

```python
# a.py
import b
import dir1.c  # absolute package import

print(b.x)
print(dir1.c.d.z)
```

```python
# b.py
x = 'hello'
```

```python
# c.py
y = 'bye'

from .dir2 import d  # relative package import
```

```python
# d.py
from .. import c  # relative package import

print(f'c.y in d.py: {c.y}')
z = 'ciao'
```

The output from `/usr/bin/python3.5 dir0/a.py` is

```
c.y in d.py: bye
hello
ciao
```

Great, but what is going on here?

**Relative package imports** are denoted by imports starting with 
`from` followed by dot syntax and are relative to the file in which
they appear, e.g. the line

```python
# c.py
from .dir2 import d  # relative package import
```

means

> Go to a directory called `dir2` located in the same
directory as `c.py`, then look in `dir2` for a file called `d.py`

and similarly

```python
# d.py
from .. import c  # relative package import
```

means

> Go to the parent directory of the directory in which `d.py` is 
located, then look for a file called `c.py`

In relative package imports, the MSP plays no role!

Suppose in `d.py` we also wanted to import `b.py` using a relative 
package import, i.e. adding

```python
# d.py
from ... import b  # relative package import
```

Uh-oh, this does not work

```
ValueError: attempted relative import beyond top-level package
```

as recall the only way Python knows a directory is a package is via 
the presence of `__init__.py`.

From the directory tree, we can see there is only one package with a
package root of `/path/to/import_examples/dir0/dir1`.

Thus it is not possible to access `b.py` this way as it is 
in `/path/to/import_examples/dir0`, i.e. above the package root.

What if we added an `__init__.py` to `dir0`? This would mean we would 
have two packages, one with root 

`/path/to/import_examples/dir0`

and one with root

`/path/to/import_examples/dir0/dir1`.

But the second package root overrides the first one so in `d.py` we 
still cannot import `b.py` using a relative package import, `b.py`
is still above the package root.

What if we got rid of the second package root, i.e. removed 
`/path/to/import_examples/dir0/dir1/__init__.py`?

```python
# d.py
from ... import b  # relative package import
```

now works, but the absolute package import in `a.py`

```python
# a.py
import dir1.c  # absolute package import
```

doesn't as recall in an absolute package import, every directory 
needs to have an `__init__.py`. 

What if we used a relative package import instead, 
i.e. replaced the above with

```python
# a.py
from .dir1 import c  # relative package import
```

This in theory should work, except that `a.py` is the top level 
script, and [Python does not let you do relative package imports
in top level scripts](https://stackoverflow.com/questions/33837717/systemerror-parent-module-not-loaded-cannot-perform-relative-import.)

**Upshot:** We cannot run `/path/to/import_examples/a.py` and import 
`b.py` in `d.py` using a relative package import.

We have to instead use an absolute package import

```python
# d.py
import b  # absolute package import
from .. import c  # relative package import

print(f'c.y in d.py: {c.y}')
z = 'ciao'
```

## Conclusion

As the last example shows, package imports in Python can get 
quite involved even when starting from very simple use cases.

However, despite this, my view is that package imports are
still much more preferable to using `PYTHONPATH` or modifying 
`sys.path`.

Further, package imports are in widespread use, so even if you don't 
use them yourself you will need knowledge of them to understand 
others' code.
