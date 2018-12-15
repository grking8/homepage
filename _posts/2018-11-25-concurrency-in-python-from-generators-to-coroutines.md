---
layout: post
title: Concurrency In Python - From Generators To Coroutines
author: familyguy
comments: true
---

{% include post-image.html name="2416585_0.jpg" width="100" height="100" 
alt="python logo" %}

In the [previous post](/2018/11/04/generators-in-python-a-quick-example.html) we saw an example usage of generators in Python.

In this post, we will take another look at generators, in particular some of the 
background behind them, namely **iterables and iterators.**

We will then introduce **coroutines,** syntactically identical to 
generators apart from some additional features.

These extra features can be used to achieve **single-threaded concurrency,** 
the subject of the last section.

## Iterables and iterators 

We mentioned before how generators are sort of virtual, on-demand 
sequences, in contrast to physically stored sequences such as lists, tuples, and
strings. 

Both kinds of sequences, however, are members of a more general group, iterable objects.

An **iterable object** is any object with an `__iter__()` method returning an **iterator** 
when called.

An iterator, by definition, has a `__next__()` method. The first time it is called,
the first item is returned, the second time it is called, the second item, etc.; 
if no items are left, a `StopIteration` exception is raised. It also
has an `__iter__()` method that returns itself, i.e. every iterator is iterable.

NB: Python provides a couple of builtin shorthands, `next()` for
`__next__()` and `iter()` for `__iter__()` .

### Examples

#### Physical (real) sequences

Because physical sequences are stored in memory, they must be finite. Lists, 
tuples, strings are common examples.

You can call `iter()` on any of the above, e.g.

```python
x = [1, 2, 3]
it = iter(x)  # list_iterator
# consume the iterator
while True:
    try:
        next(it)
    except StopIteration:
        print('No more items left')
        break
```

Consuming the iterator in this way is actually what happens under the hood when you
use a `for` loop, i.e. it is equivalent to

```python
for item in x:
    item
```

You can also use a `for` loop on the iterator directly

```python
it = iter(x)  # once an iterator is exhausted, need to recreate it
for item in it:
    item
```

You can replace `x = [1, 2, 3]` with `x = (1, 2, 3)` or `x = '123'`, the code
works in the same way.

#### Virtual (on-demand) sequences

This group basically contains any iterable that is not a physical sequence.

Because such sequences return items in the sequence one at a time when 
requested, and do not store all the items in memory, they can be infinite.

There are various builtin iterables that are not physical sequences. Common 
examples are

- File, `enumerate`, and `range` objects
- Dictionaries
- Sets

File and `enumerate` objects are iterators as well as iterables

```python
x = enumerate(('a', 'b'))  # enumerate object (not a physical sequence)
it = iter(x)
it is x  # True
y = open('myfile.py')  # file object (not a physical sequence)
next(y)  # `y` is an iterator; gets first line of file
```

Of course, this works because both `enumerate` and file objects have order.

Dictionaries and sets, on the other hand, **do not have order.** It is not surprising
then that they are not iterators.

```python
d = {'a': 1, 'b': 2}
next(d)  # TypeError: 'dict' object is not an iterator
s = {1, 2, 3}
next(s)  # TypeError: 'set' object is not an iterator
```

But if they do not have order, how can they be iterable?

An arbitrary order is used, which is whatever Python decides (thus the order 
might be different each time the program is run). 

```python
s = {1, 2, 3}
it = iter(s)  # set_iterator
next(it)  # no guarantee to be same value next time script is run
d = {'a': 1, 'b': 2}
it1 = iter(d)  # dict_keyiterator
list(it1)  # no guarantee to be same value next time script is run
it2 = iter(d.keys())  # dict_keyiterator
list(it2)  # no guarantee to be same value next time script is run
```

`d.values()` and `d.items()` are also iterable.

However, just because an iterable object has a predfined, fixed order does 
not mean it is an iterator, e.g. a list is not an iterator 

```python
x = [1, 2]
next(x)  # TypeError: 'list' object is not an iterator
```

This is because you might want to create multiple iterators from the same 
iterable and iterate through them independently, e.g. in  a nested `for` loop

```python
x = enumerate('a', 'b', 'c')  # x is an iterator
for i, _ in x:
    for j, _ in x:
        print(i, j)
# 0 1
# 0 2
x = [0, 1, 2]  # x is not an iterator
it = iter(x)
it is x  # False
for i in x:
    for j in x:
        print(i, j)
# 0 0
# 0 1
# 0 2
# 1 0
# 1 1
# 1 2
# 2 0
# 2 1
# 2 2
```

Remember, the sequences in this section are not physical - their values are not stored in 
memory like the values of a string, list, tuple, etc. are.

## Generators

Generators are iterables. They are also iterators, which is why they are sometimes
referred to as generator iterators.

They are like the virtual sequences discussed above except they are
not builtins that come with the Python language, but iterables
created by the user.

For example, we can use a generator to create an infinite sequence, e.g. Fibonacci

```python
# generator function
def fib():
    a, b = 0, 1
    while 1:
      yield a + b
      tmp = b
      b = a + b
      a = tmp
      
gen = fib()  # generator object
it = iter(gen)
it is gen  # True
next(gen)  # 1
next(gen)  # 2
next(gen)  # 3
next(gen)  # 5
next(gen)  # 8
next(gen)  # 13
# infinite for loop!
for x in gen:
    x
```

or a finite sequence

```python
# generator function
def g():
    for i in range(10):
        yield i ** 2
        
gen = g()  # generator object
while 1:
    try:
        next(gen)
    except StopIteration:
        print('No more values')
        break
```

Generator objects are created from generator functions (like in the above
two examples) or generator expressions.

In generator functions, `yield` is used to produce the values sent when `next()`
is called on the generator iterator.

## Coroutines

In Python, from a language point of view, coroutines are basically the same 
thing as generators. Any distinction between the two is typically somewhat 
arbitrary and user defined. 

However, we cannot begin to discuss coroutines and start understanding 
them until some new syntax is introduced.

But before doing so, let's remind ourselves that coroutines are not specific 
to Python. They are a general concept in computer science: 

> "Coroutines are computer program components that generalize subroutines for 
nonpreemptive multitasking, by allowing multiple entry points for suspending 
and resuming execution at certain locations". That's a rather technical way of 
saying, "coroutines are functions whose execution you can pause" 
[Tall, Snarky Canadian](https://snarky.ca/how-the-heck-does-async-await-work-in-python-3-5/)

This pausing of a function's execution is something we have already seen. It's
what happens when a `yield` is reached and is how a generator produces values
on demand.

So far, we have only seen values *pulled* from a generator using `next()`. 

One of the extra features we need to consider in order to better understand 
coroutines is *pushing* values.

The other main extra features are *closing the generator, getting the generator 
to return a value, and exception handling.*

Typically, whenever one or more of these extra features is present, we no longer
refer to the object as a generator but as a coroutine. 

### Examples

#### Pushing values, closing the coroutine

```python
# compute running average
def averager():
    total = 0.0
    count = 0
    average = None
    while True:
        term = yield average  # assigning an expression containing `yield`
        total += term
        count += 1
        average = total / count
        
coro = averager()  # generator object, just like before
next(coro)  # None
coro.send(10)  # 10
coro.send(20)  # 15
coro.send(6)  # 12
import inspect
inspect.getgeneratorstate(coro)  # 'GEN_SUSPENDED'
coro.close()
inspect.getgeneratorstate(coro)  # 'GEN_CLOSED 
```

The way to understand `next(coro)` is to ignore the 
assignment and only consider the expression to the right of the equal sign, i.e.

```python
total = 0.0
count = 0
average = None
while True:
    yield average  # ignore everything to the left of `yield`
```

Thus `next(coro)` returns `None` and the coroutine is paused at `yield`.

`averager()` computes a running average. As we haven't given it
any values yet, no average can be computed thus `next(coro)` returning 
`None` is coherent.

The way to pass a value `x` to `averager()` is `coro.send(x)`.

So why bother with `next(coro)` at all, and not `coro.send(10)` straight away?

A coroutine can only accept values when it is *suspended*. `next(coro)` 
*primes* the coroutine and puts it in a suspended state meaning it is ready to
start receiving values (another way to prime it is `coro.send(None)`).

Once the coroutine is primed, `coro.send(10)` resumes the coroutine where it 
was paused at `yield average`. Before, when `yield` was at the start of the 
line, we just moved to the next line in the body of the function definition.

Now, there is an assignment to take care of. What Python does is to take the value
sent in, here `10`, and assign it to `term` (you can think of `10` as replacing
`yield average`). 

`average` now evaluates correctly to `10`, and because we are in a `while` loop,
we `yield average` just like we did before when calling `next(coro)`, which is 
what `coro.send(10)` returns.

The process is repeated when `coro.send(20)` is run. The average is updated to
take into account the new value of `20`, and the updated average is returned by 
`coro.send(20)`.

Thus we can keep sending values into the coroutine with `coro.send()`, and get
back each time the updated average.

Once we have sent in our last value, we could just carry on with the rest of
our program. However, this will leave our coroutine paused. The correct thing to 
do is to close the coroutine once the last value has been sent in.

This is done using `coro.close()`

#### Returning a value

```python
def coro():
    yield 5
    return 10
    
c = coro(c)
next(c)  # 5
next(c)  # fall off the end of the function body (no more `yield`)
# Raise `StopIteration` exception just like before
# However, 10 is available in the exception
c = coro(c)  # coroutine is exhausted it, make new instance of it
while 1:
    try:
        next(c)  # 5
    except StopIteration as e:
        print(f'Value returned by coroutine is {e.value}')  # 'Value returned by coroutine is 10'
        break
```

We can now update our running average example to return a value (we won't bother
yielding the updated the average as we go along)

```python
def averager2():
    total = 0.0
    count = 0
    average = None
    while True:
        term = yield
        if term is None:
            break  # in order to return a value, a coroutine must terminate 
            # normally, i.e. cannot be stuck in an infinite loop
        total += term
        count += 1
        average = total / count
    return {'count': count, 'average': average}
    
coro = averager2()
next(averager2)  # prime the coroutine
coro.send(3)
coro.send(10)
coro.send(34)
coro.send(3)
try:
    coro.send(None)
except StopIteration as e:
      print(e.value)  # {'count': 4, 'average': 12.5}
```

#### Exception handling

```python
class DemoException(Exception):
    pass
  
def demo_exc_handling():
    while 1:
        try:
            x = yield  # equivalent to `x = yield None`
        except DemoException:
            print('Demo exception handled. Continuing...')
        else:
            print(f'Coroutine received value of {x}')
            
coro = demo_exc_handling()
next(coro)  # None
coro.send(34) # 'Coroutine received value of 34'
coro.send(343444) # 'Coroutine received value of 343444'
coro.throw(DemoException)
# 'Demo exception handled. Continuing...'
coro.send('hi') # 'Coroutine received value of hi'
```

## Concurrency and coroutines

Concurrency means doing multiple tasks at once, i.e. given a unit of time, 
multiple tasks make progress.

Concurrency can be single or multithreaded. Here, we will be looking at single
threaded concurrency.

NB: When running tasks on multiple threads, and those threads are on different 
CPUs, this is parallelism. In Python, although multithreading is supported, 
because of the Global Interpreter Lock (GIL), multithreading always happens on 
one CPU, thus parallelism is not possible. Only concurrency is possible in 
Python.

Let's suppose we have two functions, `func1` and `func2`.

`func1` takes two seconds to run. `func2` takes three seconds to run, on condition
that `func1` has finished running. If `func1` has not finished running, `func2`
cannot finish.

The obvious solution is to call `func1` first and then `func2`, leading to a 
total running time of five seconds.

If we called `func2` first, `func1` would never finish and our script would 
hang forever.

However, with concurrency, execution of both `func1` and `func2` can make 
progress at the same time.

With concurrency enabled, we could start `func1` and immediately after start  
`func2`.
 
`func1` would finish first after two seconds. About one second later, `func2` would
also finish (it has been running for three seconds and `func1` has finished
running). This gives a total running time of about three seconds.

We could achieve the above by running `func1` and `func2` in separate threads.

Alternatively, we could use a single thread and coroutines:

```python
import time

def coroutine1():
    start = time.time()
    while time.time() - start < 2:
        yield 'Running...'
    yield 'Done'

def coroutine2():
    start = time.time()
    coro1_done = False
    while not (time.time() - start >= 3 and coro1_done):
        coro1_done = yield 'Running...'
    yield 'Done'

def run_loop():
    print('Starting event loop...')
    start = time.time()
    coro1 = coroutine1()
    coro2 = coroutine2()
    next(coro2)  # prime `coro2`
    coro1_done, coro2_done = False, False
    current_coro = 'coro1'
    while not (coro1_done and coro2_done):
        time.sleep(0.25)  # check progress every 0.25 seconds
        if current_coro == 'coro1' and not coro1_done:
            status = next(coro1)
            print(f'coroutine1 status: {status}')
            if status == 'Done':
                coro1_done = True
            if not coro2_done:
                current_coro = 'coro2'
        elif current_coro == 'coro2' and not coro2_done:
            status = coro2.send(coro1_done)
            print(f'coroutine2 status: {status}')
            if status == 'Done':
                coro2_done = True
            if not coro1_done:
                current_coro = 'coro1'
    print(f'Event loop finished in {time.time() - start:.2f}s')
```

```
Starting event loop...
coroutine1 status: Running...
coroutine2 status: Running...
coroutine1 status: Running...
coroutine2 status: Running...
coroutine1 status: Running...
coroutine2 status: Running...
coroutine1 status: Running...
coroutine2 status: Running...
coroutine1 status: Done
coroutine2 status: Running...
coroutine2 status: Running...
coroutine2 status: Done
Event loop finished in 3.02s
```

<br>
<br>

---

<br>
<br>

{% include disclaimer.md %}

## References

- [Fluent Python, 1st Edition - Luciano Ramalho](http://shop.oreilly.com/product/9780596528126.do)
- [Learning Python, 5th Edition - Mark Lutz](http://shop.oreilly.com/product/0636920028154.do)
- [Tall, Snarky Canadian](https://snarky.ca/how-the-heck-does-async-await-work-in-python-3-5/)
