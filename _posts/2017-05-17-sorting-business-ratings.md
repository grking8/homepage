---
layout: post
title: Sorting Business Ratings
author: familyguy
comments: true
---

{% include post-image.html name="4347962723_ffdd4df93d.jpeg" width="100" height="50" alt="Five stars" %}

You have an array of businesses. Each business has an ID

$$ n \in \left[1..10000\right] $$

and a rating

$$  m \in \left[1..5\right] $$

In JavaScript, something like
                    
{% highlight javascript %}
var businesses = [
  {
      id: 4487,
      rating: 2
  },
  {
      id: 935,
      rating: 5
  },
  {
      id: 4684,
      rating: 1
  },
  {
      id: 9483,
      rating: 1
  },
  {
      id: 8958,
      rating: 1
  },
  {
      id: 9953,
      rating: 4
  },
  {
      id: 6889,
      rating: 3
  },
  {
      id: 72,
      rating: 2
  },
  {
      id: 283,
      rating: 2
  },
  {
      id: 123,
      rating: 4
  }
];
{% endhighlight %}

You want to output the business ids sorted by rating (highest to lowest), with businesses with the same rating respecting the order above.

Something like
      
{% highlight javascript %}
var k = 5,
C = new Array(k + 1).fill(0);
for (business of businesses) {
  var rating = business['rating'];
  C[rating]++;
}
for (var i = 1; i < C.length; i++) {
  C[i] += C[i - 1];
}
var result = new Array(businesses.length).fill(0);
for (business of businesses) {
  var rating = business['rating'],
  id = business['id'];
  result[C[rating] - 1] = id;
  C[rating]--;
}
result.reverse();
console.log(result);
{% endhighlight %}

which runs in in O(n) time and outputs
{% highlight javascript %}
[ 935, 9953, 123, 6889, 4487, 72, 283, 4684, 9483, 8958 ]
{% endhighlight %}
      
