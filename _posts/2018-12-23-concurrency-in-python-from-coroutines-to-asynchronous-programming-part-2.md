---
layout: post
title: Concurrency In Python - From Coroutines To Asynchronous Programming - Part 2
author: familyguy
comments: true
---

{% include post-image.html name="2416585_0.jpg" width="100" height="100" 
alt="python logo" %}

In the [previous post,](/2018/12/16/concurrency-in-python-from-coroutines-to-asynchronous-programming-part-1.html) we saw an example of asynchronous programming in Python using `yield from`.

In that example, we used our own custom event loop. We also mocked the network I/O 
operations run concurrently.

In this post, we will firstly rewrite the previous post's example using `asyncio`.
This will allow us to avoid writing a custom event loop, and use more standard 
coroutine interaction in an asynchronous program (that prescribed by `asyncio`).

Afterwards, we will adapt our rewritten script to use `aiohttp`, replacing our mocked 
network I/O operations with real HTTP GET requests.

## Replace custom code with asyncio

In the previous post, the code outside of `main()` looked like this

```python   
import time

start = time.time()

def start_network_io():
    pass  # make low level call to OS to start network I/O

def is_network_io_complete(start):
    # mock OS polling checking if network I/O is complete
    # mocked so that network I/O completes after 3 seconds
    return time.time() - start > 3

def get_network_io_response():
    return 200

def network_io_coroutine():
    start = time.time()
    start_network_io()
    while 1:
        if is_network_io_complete(start):
            break
        yield  # hand control back to the event loop
    # network I/O complete, response ready to be returned
    return get_network_io_response()

def coroutine():
    # our "easy" coroutine
    # 1st line is blocking BUT DOES NOT BLOCK EVENT LOOP
    # 1st line unblocks when `network_io_coroutine` returns
    # This blocking then unblocking makes the code easy to write
    response = yield from network_io_coroutine()
    network_io_responses.append(response)

network_io_responses = []
```

To update the above to use `asyncio`, there are two things to change

- The two coroutines `network_io_coroutine()` and `coroutine()` should have the 
`asyncio.coroutine` decorator added to them (see page 543 of [Fluent Python, 1st Edition - Luciano Ramalho](http://shop.oreilly.com/product/9780596528126.do) for more details)
- The way to hand control back to the event loop in `network_io_coroutine()` is to use
`yield from asyncio.sleep()`, not `yield` in an infinite `while` loop. 

The updated code looks like this

```python
import asyncio
import time

start = time.time()

def start_network_io():
    pass

def get_network_io_response():
    return 200

@asyncio.coroutine
def network_io_coroutine():
    start_network_io()
    yield from asyncio.sleep(3)
    return get_network_io_response()

@asyncio.coroutine
def easy_coroutine():  # change name from `coroutine` to `easy_coroutine`
    response = yield from network_io_coroutine()
    network_io_responses.append(response)

network_io_responses = []
```

As a result, `main()` now looks a lot simpler

```python
def main():
    coro1 = easy_coroutine()
    coro2 = easy_coroutine()
    loop = asyncio.get_event_loop()
    # "register" coroutines with event loop
    loop.create_task(coro1)
    loop.create_task(coro2)
    loop.run_forever()
    print('Network I/O responses', network_io_responses)
    print(f'Script took {time.time() - start:.2f}s')
```

Unfortunately, the cost of this extra simplicity is quite prohibitive; the results are 
not displayed as anything after `loop.run_forever()` is never run. 

Nonetheless, we can check the script works as it did before:

`python -i /path/to/above/script.py`,

wait three seconds or more, and hit CTRL+C; you should see a prompt as you are now 
inside a Python shell. 

If you inspect the value of `network_io_responses`, you should
see something like

```
>>> network_io_responses
[200, 200]
```

However, if you wait less than three seconds before hitting CTRL+C,
neither of the two mocked network I/O operations will have returned a value yet

```
>>> network_io_responses
[]
```

Needless to say, there are a much cleaner ways to check our script works.

One solution is to run the event loop using `run_until_complete()` instead of
`run_forever()`.

When using `run_forever()`, we let the event loop know about our two coroutines with

```python
loop.create_task(coro1)
loop.create_task(coro2)
```

`create_task()` returns a `Task` object wrapping around the coroutine given to it as an 
argument.

However, more importantly for us, it gets the event loop to schedule the 
coroutine given to it as an argument for exection.

**When using `run_until_complete()`, we give the event loop one coroutine which it runs**
**until completion.**

But we have two coroutines we want to run in the event loop, `coro1` and `coro2`.

The workaround is to create a third, "parent" coroutine which wraps around `coro1` and 
`coro2`, and give this parent coroutine instead to `run_until_complete()`.

The way to create the parent coroutine is to create an iterable containing `coro1` and
`coro2`, e.g. `(coro1, coro2)`, and give the iterable to `wait()`.

Making these changes, our script looks like

```python
import asyncio
import time

start = time.time()

def start_network_io():
    pass

def get_network_io_response():
    return 200

@asyncio.coroutine
def network_io_coroutine():
    start_network_io()
    yield from asyncio.sleep(3)
    return get_network_io_response()

@asyncio.coroutine
def easy_coroutine():
    response = yield from network_io_coroutine()
    network_io_responses.append(response)

network_io_responses = []

def main():
    coro1 = easy_coroutine()
    coro2 = easy_coroutine()
    parent_coro = asyncio.wait((coro1, coro2))
    loop = asyncio.get_event_loop()
    loop.run_until_complete(parent_coro)
    print('Network I/O responses', network_io_responses)
    print(f'Script took {time.time() - start:.2f}s')

main()
```

```
Network I/O responses [200, 200]
Script took 3.00s
```

Adding a third coroutine is also easier now

```python
def main():
    coro1 = easy_coroutine()
    coro2 = easy_coroutine()
    coro3 = easy_coroutine()
    parent_coro = asyncio.wait((coro1, coro2, coro3))
    loop = asyncio.get_event_loop()
    loop.run_until_complete(parent_coro)
    print('Network I/O responses', network_io_responses)
    print(f'Script took {time.time() - start:.2f}s')

main()
```
```
Network I/O responses [200, 200, 200]
Script took 3.00s
```

## Replace mock I/O operations with HTTP GET requests

We replace `asyncio.sleep()` in `network_io_coroutine()` with `aiohttp.request()`

```python
import asyncio
import time
import aiohttp  # version 0.6.4

start = time.time()

@asyncio.coroutine
def network_io_coroutine():
    r = yield from aiohttp.request('GET', 'https://pokeapi.co/api/v2/pokemon/1/')
    return r.status

@asyncio.coroutine
def easy_coroutine():
    response = yield from network_io_coroutine()
    network_io_responses.append(response)

network_io_responses = []

def main():
    coro1 = easy_coroutine()
    coro2 = easy_coroutine()
    coro3 = easy_coroutine()
    parent_coro = asyncio.wait((coro1, coro2, coro3))
    loop = asyncio.get_event_loop()
    loop.run_until_complete(parent_coro)
    print('Network I/O responses', network_io_responses)
    print("Script took {:.2f}s".format(time.time() - start))  # Python version 3.4.0

main()
```

```
Network I/O responses [200, 200, 200]
Script took 0.39s
```

In theory, if we increase the number of requests, the running time should not change much

```python
import asyncio
import time
import aiohttp

start = time.time()

@asyncio.coroutine
def network_io_coroutine(url):
    r = yield from aiohttp.request('GET', url)
    return r.status

@asyncio.coroutine
def easy_coroutine(url):
    response = yield from network_io_coroutine(url)
    network_io_responses.append(response)

network_io_responses = []

def main():
    base_url = 'https://pokeapi.co/api/v2/pokemon/{}/'
    coros = [easy_coroutine(base_url.format(i)) for i in range(1, 101)]
    parent_coro = asyncio.wait(coros)
    loop = asyncio.get_event_loop()
    loop.run_until_complete(parent_coro)
    expected_responses = [200] * 100
    assert expected_responses == network_io_responses
    print("Script took {:.2f}s".format(time.time() - start))

main()
```

```
Script took 1.43s
```

However, if we make the same number of requests synchronously,

```python
import requests
import time

start = time.time()

network_io_responses = []

def main():
    base_url = 'https://pokeapi.co/api/v2/pokemon/{}/'
    for i in range(1, 101):
        r = requests.get(base_url.format(i))
        network_io_responses.append(r.status_code)
    expected_responses = [200] * 100
    assert expected_responses == network_io_responses
    print("Script took {:.2f}s".format(time.time() - start))

main()
```

```
Script took 41.33s
```

Over 30 times slower!

From the examples in this post, we can see the benefits of concurrency via asynchronous 
programming when performing network I/O operations.

<br>
<br>

---

<br>
<br>

{% include disclaimer.md %}

## References

[Fluent Python, 1st Edition - Luciano Ramalho](http://shop.oreilly.com/product/9780596528126.do)
