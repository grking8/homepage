---
layout: post
title: Generators In Python - A Quick Example
author: familyguy
comments: true
---

{% include post-image.html name="2416585_0.jpg" width="100" height="100" 
alt="python logo" %}


Suppose you have some URLs and want to find the first one that returns an
error status code

```python
import requests
import time

start = time.time()


def get_status_codes(urls):
    result = {}
    for url in urls:
        print(f'GET {url}')
        result[url] = requests.get(url).status_code
    return result


urls = [
    'https://pokeapi.co/api/v2/pokemon/1/',
    'https://pokeapi.co/api/v2/pokemon/sdfsdf',
    'https://pokeapi.co/api/v2/pokemon/2/',
    'https://pokeapi.co/api/v2/pokemon/3/',
    'https://pokeapi.co/api/v2/pokemon/4/',
    'https://pokeapi.co/api/v2/pokemon/5/',
    'https://pokeapi.co/api/v2/pokemon/6/',
    'https://pokeapi.co/api/v2/pokemon/7/',
    'https://pokeapi.co/api/v2/pokemon/8/',
    'https://pokeapi.co/api/v2/pokemon/9/',
    'https://pokeapi.co/api/v2/pokemon/10/',
    # ... more urls
]
status_codes = get_status_codes(urls)
for url, status_code in status_codes.items():
    if status_code >= 400:
        print(f'First error status code: {status_code}, url: {url}')
        break
else:
    print('All urls successful!')
print(f'{time.time() - start:.2f}s')
```

which outputs

```
GET https://pokeapi.co/api/v2/pokemon/1/
GET https://pokeapi.co/api/v2/pokemon/sdfsdf
GET https://pokeapi.co/api/v2/pokemon/2/
GET https://pokeapi.co/api/v2/pokemon/3/
GET https://pokeapi.co/api/v2/pokemon/4/
GET https://pokeapi.co/api/v2/pokemon/5/
GET https://pokeapi.co/api/v2/pokemon/6/
GET https://pokeapi.co/api/v2/pokemon/7/
GET https://pokeapi.co/api/v2/pokemon/8/
GET https://pokeapi.co/api/v2/pokemon/9/
GET https://pokeapi.co/api/v2/pokemon/10/
First error status code: 404, url: https://pokeapi.co/api/v2/pokemon/sdfsdf
4.52s
```

The problems with this approach is that a request is made to each URL, and 
the status code of each request's response is stored in memory.

This is inefficient as we are only interested in finding the first URL that
returns an error status code.

Both execution time and memory usage can be improved by using a generator
function.  

```python
import requests
import time

start = time.time()


def get_status_codes(urls):
    for url in urls:
        print(f'GET {url}')
        yield {'url': url, 'status_code': requests.get(url).status_code}


urls = [
    'https://pokeapi.co/api/v2/pokemon/1/',
    'https://pokeapi.co/api/v2/pokemon/sdfsdf',
    'https://pokeapi.co/api/v2/pokemon/2/',
    'https://pokeapi.co/api/v2/pokemon/3/',
    'https://pokeapi.co/api/v2/pokemon/4/',
    'https://pokeapi.co/api/v2/pokemon/5/',
    'https://pokeapi.co/api/v2/pokemon/6/',
    'https://pokeapi.co/api/v2/pokemon/7/',
    'https://pokeapi.co/api/v2/pokemon/8/',
    'https://pokeapi.co/api/v2/pokemon/9/',
    'https://pokeapi.co/api/v2/pokemon/10/',
    # ... more urls
]

generator = get_status_codes(urls)
for i in range(len(urls)):
    result = next(generator)
    status_code, url = result['status_code'], result['url']
    if status_code >= 400:
        print(f'First error status code: {status_code}, url: {url}')
        break
else:
    print('All urls successful!')
print(f'{time.time() - start:.2f}s')
```

which outputs

```
GET https://pokeapi.co/api/v2/pokemon/1/
GET https://pokeapi.co/api/v2/pokemon/sdfsdf
First error status code: 404, url: https://pokeapi.co/api/v2/pokemon/sdfsdf
0.85s
```

The same performance gain can be achieved without using a generator, e.g.

```python
for url in urls:
    status_code = requests.get(url).status_code
    if status_code >= 400:
        print(f'First error status code: {status_code}, url: {url}')
        break
else:
    print('All urls successful!')
```

However, using a generator and `next` can be more concise, e.g. if the requests are not made
in a `for` loop.
