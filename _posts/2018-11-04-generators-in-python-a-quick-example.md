---
layout: post
title: Generators In Python - A Quick Example
author: familyguy
comments: true
---

{% include post-image.html name="2416585_0.jpg" width="100" height="100" 
alt="python logo" %}

Suppose you have some data in a list, and a function to process each element
in that list. 

Further, suppose you were interested in finding the first element in the list
which, after processing, satisfied a certain condition.

```python
import time

start = time.time()


def process(n):
    return n > 5
    
    

DATA_SIZE = 10 ** 8
data = [i for i in range(DATA_SIZE)]
for d in data:
    if process(d):
        print('*' * 50)
        break
time_taken = time.time() - start
print(f'Task completed! Time taken: {time_taken:.2f}s')
print(f'Element found {d}')
```

The above code might take a while to run, depending on the amount of data 
stored in the list and the hardware on which it is run.

However, this performance penalty is not necessary as each element in the list
is processed in isolation - there is no need to load the whole list into
memory.

As such, a more efficient way to achieve the same outcome is to use a generator

```python
import time

start = time.time()


def process(n):
    return n > 5


def my_generator():  # generator function
    for i in range(DATA_SIZE):
        yield i


DATA_SIZE = 10 ** 8
data = my_generator()  # calling generator fn returns generator object
while True:
    d = next(data)
    if process(d):
        print('*' * 50)
        break
time_taken = time.time() - start
print(f'Task completed! Time taken: {time_taken:.2f}s')
print(f'Element found {d}')
```

which avoids loading all the data into memory.

Instead, Python uses lazy loading to only return one element each time `next` is called.

The above can be shortened to 

```python
import time

start = time.time()


def process(n):
    return n > 5


DATA_SIZE = 10 ** 8
d = next(i for i in range(DATA_SIZE) if process(i))
print('*' * 50)
time_taken = time.time() - start
print(f'Task completed! Time taken: {time_taken:.2f}s')
print(f'Element found {d}')
```
