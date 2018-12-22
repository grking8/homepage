---
layout: post
title: Concurrency In Python - From Coroutines To Asynchronous Programming - Part 1
author: familyguy
comments: true
---

{% include post-image.html name="2416585_0.jpg" width="100" height="100" 
alt="python logo" %}

In the [previous post,](/2018/11/25/concurrency-in-python-from-generators-to-coroutines.html) we saw how coroutines in Python can be used to achieve single
threaded concurrency. 

After reading that post, you might be asking 

- Retrieving the value returned by a coroutine by catching a `StopIteration` exception
 and accessing the `value` attribute seems a bit hacky, is there a cleaner way?
- Whilst the example at the end worked, it was
    - Pretty contrived and unrealistic as use cases go
    - Quite verbose / complicated for a simple task

In this post, we will introduce `yield from` which will go some way in  
addressing the points above.

## yield from

First, let's see how the `yield from` syntax works.

Like `yield`, `yield from` is only valid inside the definition of a function body and 
turns a function into a generator / coroutine.

Unlike `yield`, `yield from` *must be followed by an iterable.*

`yield from` converts the iterable into an iterator and exhausts it, yielding each value
along the way, e.g.

```python
def coroutine(iterable)
    yield from iterable
    
coro = coroutine('hello')
next(coro)  # 'h'
next(coro)  # 'e'
```

which is equivalent to

```python
def coroutine(iterable):
    for item in iterable:
        yield item

coro = coroutine('hello')
next(coro)  # 'h'
next(coro)  # 'e'
```

As `yield from` can be followed by any iterable, it can be followed by a generator 
(recall generators are iterables and iterators).

```python
def coroutine(generator):  # `generator` is a generator function
    yield from generator()
        
def generator():
    yield 'h'
    yield 'e'
    
coro = coroutine(generator)
next(coro)  # 'h'
next(coro)  # 'e'
```

The above means coroutines can call other generators / coroutines in the same 
way a function can call other functions, i.e the above is analogous to 

```python
def func1():
    return 1
    
def func2():
    return func1()
    
func2()  # 1
```

Without `yield from`, we have to introduce another variable

```python
def coroutine(generator):
    yield generator()
    
def generator():
    yield 'h'
    yield 'e'
    
coro = coroutine(generator)
g = next(coro)
next(g)  # 'h'
next(g)  # 'e'
```

which looks even worse if another "intermediary" generator is introduced

```python
def coroutine(generator):
    yield generator()
    
def generator1():
    yield generator2()
    
def generator2():
    yield 'h'
    yield 'e'
    
coro = coroutine(generator1)
g = next(next(coro))
next(g)  # 'h'
next(g)  # 'e'
```

Each time we add an intermediary generator, we have to make an extra `next()` call.

For $n$ generators, we'd have `next(next(...))` $n$ times.

However, with `yield from`:

```python
def coroutine1(coroutine):
    yield from coroutine()
    
def coroutine2():
    yield from generator()
    
def generator():
    yield 'h'
    yield 'e'
    
coro = coroutine1(coroutine2)
next(coro)  # 'h'
next(coro)  # 'e'
```

the same code works regardless of the number of coroutines separating the outer and inner
most objects.

This might seem like a trivial saving, but according to [PEP 380,](https://www.python.org/dev/peps/pep-0380/) 
it often amounts to something substantial.

Now that we have seen how `yield from` works, let's see how it addresses the points raised
at the beginning of the post.

### Accessing a coroutine's `return` value

`yield from` allows a cleaner  way of accessing a coroutine's `return` value:

```python
results = []

def coroutine1():
    yield "I'm not done, hitting pause"
    return 1
    
def coroutine2():
    result = yield from coroutine1()
    results.append(result)
    
coro = coroutine2()
while 1:
    try:
        next(coro)  # "I'm not done, hitting pause"
    except StopIteration:
        break
print(results)  # [1]
```

### More realistic, simpler concurrency example

We introduced concurrency in the previous post where it was defined as 
"to make progress on multiple tasks at the same time".

We saw it applied to a particular situation and reduce the running time of a 
script.

More generally though, why do we care about concurrency when programming in Python?

In Python (and other languages), functions that perform I/O (moving data from 
A to B) can take a long time to run and introduce latency.

Data might be moved across a network, e.g. when making a HTTP request, from an external 
hard drive to local disk, from a local database to the local file system, etc.

In Python, programs are by default run **synchronously**, i.e. lines of code are executed
in order, one after the other. If there are two lines of code, the second line of code can
only be run once the first line has completed.

If the first line performs I/O, this blocks the running of the entire program. 
Only once the first line's I/O has completed can the program continue and 
run the second line.

This is wasteful as each time the program waits for I/O to complete, the CPU is sitting
idle.

This wastefulness can be seen in the running time of the program increasing linearly with
the number of I/O operations performed, i.e. it is $O(n)$.

For example, a program performing $n$ I/O operations each taking two seconds has
the following running times:

| I/O operations | Running time |
|:------:|:-----------:|
| 1,000 | ~30 mins  |
| 10,000 | ~5 hours  |
| 1,000,000 | ~23 days  |
| 1,000,000,000 | ~63 years |
{:.mbtablestyle}

<br>

To put this into perspective, there are billions of webpages. Google crawls all these 
pages regularly and seems to update its search results every couple of days or so.

One suspects Google is not doing this synchronously!

The solution is to use concurrency to write programs that run **asynchronously.**

Now, when our program encounters a line of code that performs I/O, this line does not 
block the rest of the program (this is why asynchronous is synonymous with non 
blocking). Instead, the next line of the program is run.

The drawback of this approach is that it makes your program more difficult to reason about, 
e.g. how do I know when the I/O performed by the first line has completed, and how do I
process the result? What if there was an error during that I/O?

The advantage is that the program in our previous example now takes two seconds to run, 
rather than $2n$. This means our program's running time is scaleable, as it is 
completely independent of the number of I/O operations.

This was because we assumed each I/O operation took two seconds to run. In general,
each I/O operation will vary in the amount of time it takes to run, and the program's
running time is $\max(r_1,\ldots,r_n)$. Although this is not completely independent of 
$n$, the dependence is fairly benign in that as n increases we are taking the max of 
a larger set of numbers, but if we assume there is some upper bound on the time of 
an I/O operation, this is not a problem.

In any case, it is much better than the linear situation we had earlier.

That all sounds great, what's that got to do with yield from?

We want to 
- flag our parts of the code that introduce latency
- make those parts of the code non blocking and run concurrently


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
    # 1st line is blocking BUT DOES NOT BLOCK EVENT LOOP
    # 1st line unblocks when `network_io_coroutine` returns
    response = yield from network_io_coroutine()
    network_io_responses.append(response)

network_io_responses = []

def main():
    # "register" coroutines with event loop
    coro1 = coroutine()
    coro2 = coroutine()
    coro_results = {'coro1': None, 'coro2': None}
    current_coro = None
    # start event loop
    while coro_results['coro1'] is None or coro_results['coro2'] is None:
        try:
            if coro_results['coro1'] is None:
                current_coro = 'coro1'
                next(coro1)  # start / resume 1st network I/O
            if coro_results['coro2'] is None:
                current_coro = 'coro2'
                next(coro2)  # start / resume 2nd network I/O
        except StopIteration:
            if current_coro == 'coro1':  # 1st network I/O complete
                coro_results['coro1'] = network_io_responses[-1]
            if current_coro == 'coro2':  # 2nd network I/O complete
                coro_results['coro2'] = network_io_responses[-1]
    print('Network I/O responses', network_io_responses)
    print('Coroutine results', coro_results)
    print(f'Script took {time.time() - start:.2f}s')
    
main()
```

```
Network I/O responses [200, 200]
Coroutine results {'coro1': 200, 'coro2': 200}
Script took 3.00s
```

And to prove this works, if we add a third coroutine, the running time will be the same.

The code is the same except now `main` looks like

```python
def main():
    # "register" coroutines with event loop
    coro1 = coroutine()
    coro2 = coroutine()
    coro3 = coroutine()
    coro_results = {'coro1': None, 'coro2': None, 'coro3': None}
    current_coro = None
    # start event loop
    while (coro_results['coro1'] is None or coro_results['coro2'] is None
            or coro_results['coro3'] is None):
        try:
            if coro_results['coro1'] is None:
                current_coro = 'coro1'
                next(coro1)  # start / resume 1st network I/O
            if coro_results['coro2'] is None:
                current_coro = 'coro2'
                next(coro2)  # start / resume 2nd network I/O
            if coro_results['coro3'] is None:
                current_coro = 'coro3'
                next(coro3)  # start / resume 3rd network I/O
        except StopIteration:
            if current_coro == 'coro1':  # 1st network I/O complete
                coro_results['coro1'] = network_io_responses[-1]
            if current_coro == 'coro2':  # 2nd network I/O complete
                coro_results['coro2'] = network_io_responses[-1]
            if current_coro == 'coro3':  # 3rd network I/O complete
                coro_results['coro3'] = network_io_responses[-1]
    print('Network I/O responses', network_io_responses)
    print('Coroutine results', coro_results)
    print(f'Script took {time.time() - start:.2f}s')
```

```
Network I/O responses [200, 200, 200]
Coroutine results {'coro1': 200, 'coro2': 200, 'coro3': 200}
Script took 3.00s
```

In part 2, we will look at how the above is incorporated in `asyncio`. As although it 
works, there is no need to create your asynchronous event framework. As the above is sort
of the beginning of an async framework.

<br>
<br>

---

<br>
<br>

{% include disclaimer.md %}

## References

[Fluent Python, 1st Edition - Luciano Ramalho](http://shop.oreilly.com/product/9780596528126.do)
