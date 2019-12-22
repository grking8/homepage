---
layout: post
title: Divisibility by 3
author: familyguy
comments: true
tags: maths number-theory divisibility
---

{% include post-image.html name="Lattice_of_the_divisibility_of_60_(bn).svg.png" width="100" height="100" 
alt="lattice of divisibility" %}

A common rule for checking whether an integer is divisible by `3` is to consider
the sum of its digits.

For example, `12345` is divisible by `3` because `1 + 2 + 3 + 4 + 5 = 15`,
and `15` is divisible by `3`.

Similarly, `123456` is divisible by `3` and `1234567` is not.

Above, we are saying if the sum of an integer's digits is divisible 
by `3`, then the integer is divisible by `3`.

What about the reverse implication, i.e. if an integer is divisible by `3`, 
then the sum of its digits is divisible by `3`?

`3 x 12345 = 37035` is divisible by 3 thus the sum of its digits must also be
divisible by `3`. Checking this, we have `3 + 7 + 0 + 3 + 5 = 18` which is 
indeed divisible by `3`.

Similary, `3 x 234829042390482 = 704487127171446` is divisible by `3` and 
`7 + 0 + 4 + 4 + 8 + 7 + 1 + 2 + 7 + 1 + 7 + 1 + 4 + 4 + 6 = 63` is divisible
by 3.

If both implications are true, this means the set of integers that are divisble
by `3` is **exactly the same set of integers** whose sum of digits is divisible 
by `3`.

In other words, 
it is impossible to find an integer that is divisible by `3` whose sum of
its digits is not divisible by `3` or vice versa.

To "approximately" check if this is true in Python,

```python
def get_sum_of_digits(n):
    return sum(int(i) for i in list(str(n)))


i = 0
while True:
    sum_of_digits = get_sum_of_digits(i)
    if ((i % 3 == 0 and sum_of_digits % 3 != 0) or
            (i % 3 != 0 and sum_of_digits % 3 == 0)):
        print(f'The double implication (equivalence) is false for {i}!')
        break
    else:
        print(i)
    i += 1
```

Which for me ran until `i = 6624839` before I quit the script.

Unfortunately, whilst we can check our double implication
is true for an arbitrarily large number of integers,
we cannot check it in its full form.

As the set of integers
is infinite, it would take us an infinity to check 
using the method above!

However, we can achieve the above using mathematical logic:

$Let\;n\;\in\;\mathbb{N}.$

$We\;define\;\varphi(n)\;as\;the\;
sum\;of\;the\;digits\;of\;n\;and\;d(n)\;as\;the\;number\;of\;digits$

$of\;n. \; For\;example,\;\varphi(123)=6\;and\;d(n)=3$

$Show \; that:$

$$
\forall n \in \mathbb{N},\;n\mod p = 0
\iff
\varphi(n) \mod p = 0 \; (*)
$$

$where \; p=3$

<br>

------------------------------------------

<br>

We proceed by induction.

We note 

$$\mathcal{P}(n): 
\;n\mod 3 = 0
\iff
\varphi(n) \mod 3 = 0
$$

and use the notation $n=a_{1}\cdots a_{k}$

E.g. for $n=231$, $a_1=2$,
$a_2=3$, $a_3=1$.

Let's verify $\mathcal{P}(0)$,

$$0 \mod 3 = 0 \iff \varphi(0) \mod 3 = 0
$$

which is true as $\varphi(0)=0$.

Let $n \in \mathbb{N}$.

Suppose $\mathcal{P}(k)$, $k \in [0..n]$.

We want to show $\mathcal{P}(n+1)$,

$$\mathcal{P}(n+1): 
n+1\mod 3 = 0
\iff
\varphi(n+1) \mod 3 = 0
$$

If $n+1 \lt 10$, then $\varphi(n+1)=n+1 \implies \mathcal{P}(n+1)$.


If $n+1 \geq 10$, we have the following cases:

- $n+1=a_1\cdots a_{k-1}9, \; k \geq 2$; it follows that 
$(n+1)-9 = a_1\cdots a_{k-1}0$.

Thus 

$$\begin{aligned}
n+1\mod 3 = 0
&\iff
(n+1) -9\mod 3 = 0\\
&\iff
\varphi((n+1) -9)\mod 3 = 0\\
&\iff
\varphi((n+1) -9)+9\mod 3 = 0\\
&\iff
\varphi(n+1)\mod 3 = 0
\end{aligned}
$$

- $n+1=a_1\cdots a_{k}, \; a_k \neq 9$

Suppose $d(n+1)=d((n+1)-9)$. Then 

$$a_k \in [0..8] \implies a_{k-1} \gt 0$$

If we write $(n+1)-9=b_{1}\cdots b_{k}$, we have $b_{k-1}=a_{k-1}-1$, 
$b_{k}=a_{k}+1$ and $a_i=b_i, \; i \in [1..k-2]$

Therefore 

$$\begin{aligned}
\varphi(n+1)&=\sum_{i=1}^{k}a_i\\
&=\sum_{i=1}^{k-2}b_i+b_{k-1}+1+b_{k}-1\\
&=\sum_{i=1}^{k}b_i\\
&=\varphi((n+1)-9)
\end{aligned}$$

Thus

$$\begin{aligned}
\varphi(n+1) \mod 3 = 0
&\iff
\varphi((n+1)-9) \mod 3 = 0\\
&\iff
(n+1) - 9 \mod 3 = 0\\
&\iff
n+1 \mod 3 =0
\end{aligned}$$

Otherwise, $d(n+1)\neq d((n+1)-9) \implies d(n+1) = d((n+1)-9) +1$

Thus

$$
n+1=a_1\cdots a_k; \; a_1=1,a_2=\ldots =a_{k-1}=0,a_k \in [0..8] \\
$$

and 

$$
(n+1)-9=b_1\cdots b_{k-1}; \; b_1=\ldots =b_{k-2}=9, b_{k-1}=a_{k}+1
$$

so

$$\begin{aligned}
\varphi(n+1)-\varphi((n+1)-9)&=\sum_{i=1}^{k}a_i - \sum_{i=1}^{k-1}b_i\\
&=1+a_{k}-9-\ldots -9 - a_{k}-1\\
&=9q, \; q\in\mathbb{Z}
\end{aligned}$$

which gives

$$\begin{aligned}
\varphi(n+1)\mod 3=0
&\iff
\varphi((n+1)-9) \mod 3 =0\\
&\iff
(n+1)-9 \mod 3 =0 \\
&\iff
n+1 \mod 3 =0\\
\end{aligned}$$

Conclusion:

$\mathcal{P}(0)$ true, and for all $n \in \mathbb{N}$,

$$
\mathcal{P}(k), \; k \in [0..n] \implies \mathcal{P}(n+1) 
$$

thus by induction, $\mathcal{P}(n)$, $n \in \mathbb{N}$, QED.

We have showed $(*)$ is true for $p=3$.

Is $(*)$ true for all $p$?

No, for $p=2$ and $n=10$, we have $10 \mod 2 =0$ but $\varphi(10) \mod 2 =1$.

Are there any other $p$ for which $(*)$ is true? 

How would changing the base from ten affect any results?
