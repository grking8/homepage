---
layout: post
title: Concurrency In Python - From Generators To Coroutines
author: familyguy
comments: true
---

{% include post-image.html name="2416585_0.jpg" width="100" height="100" 
alt="python logo" %}

Add disclaimer and references (fluent python and mark lutz learning python)

In the previous post we saw an example of when generators in Python can be
useful.

In this post, we will look at generators at a bit more detail before introducing
coroutines, which basically take the basic syntax we have seen so far for 
a generator and adds features to do more things.

One of these things, is to enable concurrency.

To look at generators in a bit more detail, let's first take a look at iterators
and iterables.

We said in the previous post that generators are sort of virtual, on-demand 
sequences. Well, what about actual physically stored sequences?

Iterables are any object that supports having `.__iter__` called on it, and the
object returned is an iterator.

The shorthand is `iter()`.

The concept of iterator relies on just two things: you can call next to get the
next element, and if there is no next, raise a StopIteration exception.

Thus the only real constraint is this idea of next. So this is why the set of 
iterable objects is the set of sequences.

Sequences can be real and physically stored, so they must also be finite.

Or sequences can be virtual, not stored in memory, producing values on demand,
meaning they can be infinite.

Some examples

Physical, real sequences - usual suspects - lists, strings, tuples,..

You can convince yourself these are all iterables by calling `iter` on each
of them.

```python
x = [1, 2, 3]
for i in x:
    print(i)
    
it = iter(x)  # returns an iterator
for i in it:
    print(i)
    
for i in x:
    print(i)  # works
    
for i in it:
    print(i)  # does not work as the iterator is exhausted
```

Bascially the `for` loop when you loop over the elements in a list is

```python
x = [1, 2, 3]
for i in x:
    print(i)
    
# under the hood...
# in the for loop, create an iterator
it = iter(x)
while True:
    try:
        print(next(i))
    except StopIteration:
        break
```

You can do the same with a string, tuple.

Virtual sequences, some examples are dicts, file objects, 

```python
In [40]: iter(d)
Out[40]: <dict_keyiterator at 0x7fa1337df278>

In [41]: iter(d.keys())
Out[41]: <dict_keyiterator at 0x7fa1337902c8>

In [42]: iter(d.values())
Out[42]: <dict_valueiterator at 0x7fa1337908b8>

In [43]: iter(d.items())
Out[43]: <dict_itemiterator at 0x7fa1337903b8>

```

`enumerate` is also a virtual sequence

```python
In [44]: x=enumerate(('a','b'))

In [45]: x
Out[45]: <enumerate at 0x7fa138039798>

In [46]: it = iter(x)

In [47]: it
Out[47]: <enumerate at 0x7fa138039798>

In [48]: it is x
Out[48]: True

In [49]: next(it)
Out[49]: (0, 'a')

In [50]: next(x)
Out[50]: (1, 'b')
```

Notice how the iterable and the iterator are the same object in memory. Which is
why when you call next on one you pick up from the point of the last call on 
the other.


So the set of iterators or iterable objects is the set of all sequences, real 
or virtual.

Where do generators fit in this? We have seen in-built virtual sequences that are
iterables like file objects, enumerate, dicts, range

Generators are the same but user defined, so basically they are a language
construct so that the programmer as well as using built-in virtual sequences,
can also create their own.

Example of what `for` does under the hood when looping through a range

```python
r = range(0, 10)
it = iter(r)
In [60]: while True:
    ...:     try:
    ...:         print(next(it))
    ...:     except StopIteration:
    ...:         break
    ...: 
```

This is why a generator object is also sometimes called a generator iterator.

We can, for example, create an infinite sequence

```python
def fib():
    a, b = 0, 1
    while True:
      yield a + b
      tmp = b
      b = a + b
      a = tmp
      
gen = fib()
next(gen)
next(gen)
next(gen)
next(gen)
next(gen)
next(gen)
# infinite for loop!
for x in gen:
    print(x)
```

Here is an example of a finite virtual user created sequence

```python
def g():
    for i in range(10):
        yield i ** 2
        
gen = g()
while True:
    try:
        print(next(gen))
    except StopIteration:
        print('No more values')
        break
```

Coroutines are basically the same thing as generators. However, what distinguishes
them is that they are generators (which only use `yield` syntax in the way we 
have seen up until now) with extra syntax.

What are coroutines? In simple terms, just means to 

, "Coroutines are computer program components that generalize subroutines for 
nonpreemptive multitasking, by allowing multiple entry points for suspending 
and resuming execution at certain locations". That's a rather technical way of 
saying, "coroutines are functions whose execution you can pause"

https://snarky.ca/how-the-heck-does-async-await-work-in-python-3-5/

So whilst the `yield` syntax we have seen so far, does let you pause exection
of a function and to receive values from it, it does lack some things like
sending values to that function, getting that function to return a value, error
handling, closing the function, etc.

So far, we have only seen the syntax `yield <value>` and the `next` method.

Basically, this is all we can do with the generator. Once we have a generator
iterator, all we can do is pull values from it, calling `next` until it is 
exhausted.

The first change is to allow a push kind of usage, where the caller sends values
to the coroutine, and the values produced by the coroutine depend on the 
values sent in.

An example of this is running average

```python
def averager():
    total = 0.0
    count = 0
    average = None
    while True:
        term = yield average
        total += term
        count += 1
        average = total / count
        
coro = averager()
next(coro)  # priming the coroutine - cant send a value to a coroutine unless 
# it is suspended; the yield average on the right hand side of the equal 
# gets run first - ignore everything else on the line. so we yield None
# which is what is returned when next is called. then, as usual, the function 
# is paused
coro.send(10)  # pick up where we left off, just like before, at yield, only
# now yield takes the value of 10, the argument in send, and is assigned to term
# the average is calculated, and is yielded, the coroutines is paused, so the 
# return value of coro.send(10) is the current average
coro.send(20)  # average gets updated and gets returned again
import inspect
inspect.getgeneratorstate(coro)  # 'GEN_SUSPENDED'
coro.close()
inspect.getgeneratorstate(coro)  # 'GEN_CLOSED 
```

This works but have to close the coroutine which is where `close` comes into 
play.

The next thing to look at is how a coroutine can return a value

```python
def coro():
    yield 5
    return 10
    
c = coro(c)
next(c)  # returns 5
next(c)  # fall off the function body and raise StopIteration exception just
# like before only know the value of return is in the exception

c = coro(c)
while True:
    try:
        print(next(c))
    except StopIteration as e:
        print(f'Value returned by coroutine is {e.value}')
        break
# 5
# value returned by coroutine is 10
```

For our average example, this looks like this

```python
def averager2():
    total = 0.0
    count = 0
    average = None
    while True:
        term = yield
        if term is None:
            break  # in order to return a value, a coroutine must terminate normally
        total += term
        count += 1
        average = total / count
    return {'count': count, 'average': average}
    
coro = averager2()
next(averager2)  # prime the coroutine, can also be done using `coro.send(None)`
coro.send(3)
coro.send(10)
coro.send(34)
coro.send(3)
try:
    coro.send(None)
except StopIteration as e:
      print(e.value)  # {'count': 4, 'average': 12.5}
```

Exception handling using `throw`

```python
class DemoException(Exception):
    pass
  
def demo_exc_handling():
    print('started')
    while True:
        try:
            x = yield
        except DemoException:
            print('demo exception handled. continuing ...')
        else:
            print(f'coroutine recevied value of {x}')
            
coro = demo_exc_handling()
next(coro)  # returns None, prints 'started'
coro.send(34)
# coroutine recevied value of 34
coro.send(343444)
# 'coroutine recevied value of 343444'
coro.throw(DemoException)
# 'demo exception handled. continuing ...'
coro.send('hi')
# 'coroutine recevied value of hi'
```

Now we have seen what coroutines are and them in action, let's look at concurrency
Concurrency does not  equal parallelism, concurrency just means doing multiple tasks
at once, e.g. running two functions at the same time. Concurrency is writing 
code to execute independently of other parts, even if it all happens in a single
thread. concurrency means given a unit of time, multiple tasks make progress.

```python
impor time


def sleep(secs, coro_number):
    start = time.time()
    while True:
        if time.time() - start > secs:
            print(f'Coroutine {coro_number} finished sleeping')
            return f'Done in {time.time() - start:.2f}s'
        msg = yield 'Not finished sleeping'
        print(f'Coroutine {coro_number} received message: {msg}')
        
        
def run_loop():
    print('Starting main loop...')
    start = time.time()
    coro1 = sleep(2, 1)
    coro2 = sleep(3, 2)
    # prime coroutines
    next(coro1)
    next(coro2)
    current_coro = 'coro1'
    finished_coros = []
    results = []
    while True:
        if current_coro == 'coro1' and current_coro not in finished_coros:
            try:
                response = coro1.send('Are you awake coro1?')
                print(response)
            except StopIteration as e:
                finished_coros.append('coro1')
                results.append(e.value)
            if 'coro2' not in finished_coros:
                current_coro = 'coro2'
        elif current_coro == 'coro2' and current_coro not in finished_coros:
            try:
                response = coro2.send('Are you awake coro2?')
                print(response)
            except StopIteration as e:
                finished_coros.append('coro2')
                results.append(e.value)
            if 'coro1' not in finished_coros:
                current_coro = 'coro1'
        if 'coro1' in finished_coros and 'coro2' in finished_coros:
            print('Completed.')
            break
    print(f'Main loop finished in {time.time() - start:.2f}s')
    print('results', results)
    
    
run_loop()
```

Next post - more on coroutines, extending them via `yield from`

