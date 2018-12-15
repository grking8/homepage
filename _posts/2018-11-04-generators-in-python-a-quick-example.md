---
layout: post
title: Generators In Python - A Quick Example
author: familyguy
comments: true
---

{% include post-image.html name="2416585_0.jpg" width="100" height="100" 
alt="python logo" %}

Suppose you have a function that returns some URLs in the following way 
(this example is somewhat contrived, but we'll use it for demonstration purposes) 

```python
def get_page_urls(base_url, no_pages):
    result = []
    for i in range(1, no_pages + 1):
        result.append(f'{base_url}/{str(i)}')
    return result
```

or its list comprehension equivalent

```python
def get_page_urls(base_url, no_pages):
    result = [f'{base_url}/{str(i)}' for i in range(1, no_pages + 1)]
    return result
```

If `no_pages` is very large, calling `get_page_urls` will be costly in 
terms of memory usage (in fact, if it is sufficiently large, you will max out 
your RAM).

This is because all the URLs in `result` are stored in memory.

In Python, **generators** provide a solution to this problem.

Instead of storing an entire sequence in memory, a generator allows you to 
create a sort of virtual, on-demand sequence where at most one value is in 
memory at any time (when that value is demanded by the user).

Generator here means **generator object** (also referred to sometimes 
as generator iterator).

A generator object is created either via a *generator function* or 
a *generator expression*.

A generator function is just a normal function with the keyword `yield` in the 
body.

```python
def get_page_urls(base_url, no_pages):
    for i in range(1, no_pages + 1):
        yield f'{base_url}/{str(i)}'
```

It can be used as follows

```python
base_url = 'https://pokeapi.co/api/v2/pokemon'
no_pages = 10
g = get_page_urls(base_url, no_pages)  # does not run any code in the body of the function
type(g)  # `g` is of type `generator`
next(g)  # returns 'https://pokeapi.co/api/v2/pokemon/1'
next(g)  # returns 'https://pokeapi.co/api/v2/pokemon/2'
```

The equivalent code using a generator expression is

```python
base_url = 'https://pokeapi.co/api/v2/pokemon'
no_pages = 10
g = (f'{base_url}/{str(i)}' for i in range(1, no_pages + 1))
type(g)  # `g` is of type `generator`
next(g)  # returns 'https://pokeapi.co/api/v2/pokemon/1'
next(g)  # returns 'https://pokeapi.co/api/v2/pokemon/2'
```

Using a generator allows you to "pay as you go", i.e. pay for the memory
for the values you need as you go along, rather than paying for the total 
upfront.

In programming parlance, this is known as **lazy evaluation** (as supposed to 
eager evaluation).

Now, let's suppose `get_page_urls` does a bit more work. Rather than just returning
the URLs, it now returns the response status codes from making an HTTP GET 
request to each of those URLs, e.g.

```python
import time
import requests

start = time.time()

def get_status_codes(base_url, no_pages):
    result = []
    for i in range(1, no_pages + 1):
        url = f'{base_url}/{str(i)}'
        r = requests.get(url)
        status_code = r.status_code
        print(f'url: {url}, status code: {status_code}')
        result.append(status_code)
    return result
    
base_url = 'https://pokeapi.co/api/v2/pokemon'
no_pages = 10
status_codes = get_status_codes(base_url, no_pages)
print(f'{time.time() - start:.2f}s')
```

```
url: https://pokeapi.co/api/v2/pokemon/1, status code: 200
url: https://pokeapi.co/api/v2/pokemon/2, status code: 200
url: https://pokeapi.co/api/v2/pokemon/3, status code: 200
url: https://pokeapi.co/api/v2/pokemon/4, status code: 200
url: https://pokeapi.co/api/v2/pokemon/5, status code: 200
url: https://pokeapi.co/api/v2/pokemon/6, status code: 200
url: https://pokeapi.co/api/v2/pokemon/7, status code: 200
url: https://pokeapi.co/api/v2/pokemon/8, status code: 200
url: https://pokeapi.co/api/v2/pokemon/9, status code: 200
url: https://pokeapi.co/api/v2/pokemon/10, status code: 200
8.31s
```
 
Because in each iteration of the `for` loop we make an HTTP GET request 
(network I/O), this introduces latency as data is transferred across a network.

The problem now, even when `no_pages` is small, is not memory but running time.

In the above example, 10 requests with `no_pages = 10` had a running time of 
over 8 seconds. For `no_pages = 1000000` (one million requests) this would be 
a running time of over 9 days...

Clearly, this is not scaleable.

Generators to the rescue again?

Unfortunately, generators as we have seen so far cannot be used to solve 
this problem (generators in Python are syntactically very similar to **coroutines**, 
used extensively in the standard library module `asyncio` to enable 
asynchronous programming, which *can* solve the issue).

However, a generator does split up the running time, making it
easier to write code in between each request.

It also means if we have a stopping condition, we only incur running time
until the condition is met.

```python
import time
import requests

def get_status_codes(base_url, no_pages):
    for i in range(1, no_pages + 1):
        url = f'{base_url}/{str(i)}'
        r = requests.get(url)
        status_code = r.status_code
        print(f'url: {url}, status code: {status_code}')
        yield status_code

base_url = 'https://pokeapi.co/api/v2/pokemon'
no_pages = 10
g = get_status_codes(base_url, no_pages)  # does not run any code in the body of the function
start = time.time()
next(g) >= 400  # `next(g)` returns 200, continue
print(f'{time.time() - start:.2f}s')  # 0.89s
# do other stuff...
# finished doing other stuff, let's get the next status code
start = time.time()
next(g) >= 400 # `next(g)` returns 503, we are done
print(f'{time.time() - start:.2f}s')  # 0.88s
```
