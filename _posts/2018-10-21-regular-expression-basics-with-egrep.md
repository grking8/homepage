---
layout: post
title: Regular Expression Basics With Egrep
author: familyguy
comments: true
---

{% include post-image.html name="download.jpeg" width="170" height="100" alt="regular expressions" %}
 
{% include disclaimer.md %}

## References

[Mastering Regular Expressions, 3rd Edition - Jeffrey Friedl](http://shop
.oreilly.com/product/9780596528126.do) (highly recommended)

<br>
<br>

---

<br>
<br>

In this post we will introduce ourselves to **regular expressions**.

Regular expressions are composed of two kinds of characters:

- Literal characters (normal text characters)
- Special characters (metacharacters)

Regular expressions can contain other regular expressions, i.e. 
subexpressions. Subexpressions can be arbitrarily nested (i.e. also contain 
subexpressions) and complex.

**Metacharacters** can have a different meaning depending on the context.

Further, a character can sometimes be a metacharacter and sometimes be a normal text
character, depending on the context.

To use regular expressions, a **host** is required. The host can be anything 
from a command line utility (like `egrep`) to a full blown programming 
language, e.g. Python.

There are different **flavours of regular expressions**, where the exact meaning
 of the characters, syntax, etc. varies slightly (or not so) between flavours.

## Egrep

`egrep` is a command line utility for searching plain text data sets for 
lines that match a regular expression. All examples in this post will be 
done using `egrep` and will refer to the flavour of regex that `egrep` uses.

The user gives `egrep` a regular expression (regex) and some files to 
search; `egrep` attempts to match the regex to each line of each file, displaying
 only those lines in which a match is found.
 
### First examples
 
Create a file `file.txt` with the following contents
 
 ```
Hello.
How are you?
I'm fine thanks. How are you?
I'm well, thank you.
 ```
 
We are going to search for the lines containing the text `How are you?`

```bash
egrep -no 'How are you\?' file.txt
```

which displays in the shell (usually with some highlighting, depending on 
your configuration)

```
2:How are you?
3:How are you?
```

Alternatively, the same example can be done without creating a file

```bash
TEXT="Hello.\nHow are you?\nI'm fine thanks. How are you?\nI'm well, thank you."
printf "$TEXT" | egrep -no 'How are you\?'
```

Here is another example,

```bash
egrep '^(From|Subject): ' mailbox-file
```

`mailbox-file` is the filename and the single quotes `''` are used to wrap 
around the regex so that the shell knows not to intepret any of the 
characters inside them in a special way, i.e. the text between them
constitutes an argument to the command `egrep`. 

The regex metacharacters in the above example are `^`, `(`, `|`, and `)`.

## Metacharacters

Without metacharacters, regex is not very interesting, e.g. if your regex is
 `abc`, then all you will get as matches are lines where the characters `abc` are found.
 
The utility starts with metacharacters. We already saw in the email 
example the metacharacters `^`, `(`, `|`, and `)`.

We will now take a closer look at metacharacters, but first we will take a quick 
look at character classes.

### Character classes

A character class matches any one of several characters at that point in the
 match.
 
A character class is denoted via squared brackets, e.g. `[ea]` is a character class.

The list of characters available for a match are given between the square brackets.

For example, in the character class `[ea]`, both `e` or `a` can match.

Thus if you wanted to match `grey` or `gray`, you could use the regex `gr[ea]y`.

Character classes have their own metacharacters and should be considered as 
their own language.

### Metacharacters `^` (caret) and `$` (dollar)

- `^` matches the start of a line
- `$` matches the end of a line

`^cat` matches if you have `^` (beginning of line) followed by `c`, followed
 by `a`, followed by `t`, e.g.
 
 ```bash
 printf "cat" | egrep -no '^cat'
 ```
 
matches but

```bash
printf "the cat" | egrep -no '^cat'
```

does not.

`^cat$` matches if the line only contains `cat`, e.g.

```bash
printf "cat" | egrep -no '^cat$'
```

matches but

```bash
printf "cat is fat" | egrep -no '^cat$'
```

does not.

Similarly, `^$` matches only blank lines (lines without any characters) and 
`^` matches every line as every line has a start of line.

`^` and `$` (and other metacharacters) are special because they match a **position** in
a line rather than an actual text character. 

### Metacharacter `-` (dash) 

`-` indicates a range of characters in a character class, e.g. `[0-9]` is 
equivalent to `[0123456789]`. Other common ranges are `[a-z]` and `[A-Z]`.

Ranges can be combined, e.g. `[0-9a-fA-F]` for hexadecimal numbers.

`-` is **not a metacharacter outside of a character class**.

Also, if `-` is the **first character in a character class**, it is **not** a metacharacter.


Thus if you wanted to match `a` or `-`, you could use the character class `[-a]`.
 
 
### Metacharacter `^` (caret) inside a character class

When `^` is the first character inside a character class, it negates the character class, 
i.e. the character class matches all characters **not** listed in the character class.
 
Fore example, [^0-9]` matches any character that is not in `{0,1,2,3,4,5,6,7,8,9}`.
 
Thus `^` is a metacharacter both inside and outside a character class (recall outside of
a character class, it matches the start of a line).

Thus the meaning of `^` as a metacharacter depends on the context.
 
Further, if `^` is in a character class but not the first character, it is a normal text
character.
 
### Metacharacter `.` (dot)

Suppose you wanted a character class that matched every possible character. 

You might start off with something like `[A-Za-z0-9]` which matches 
alphanumeric characters.

You might then add some punctuation characters, e.g.`[A-Za-z0-9,.?;]`.

But what about other symbols like `*`?

Eventually you might end up trying to list all ASCII characters in the character class.

Needless to say, such an exercise is tedious and error-prone.
 
Unsurprisingly, there is a shorthand for this.

`.` is shorthand for a character class that matches all possible characters.

However, `.` is a normal text character inside a character class (which makes sense
as otherwise you would have a character class inside a character class).

Suppose you wanted a regex to match the date 19th March 1976.

The regex `03.19.76` matches `"03/19/76"`, `"03-19-76"`, and `"03.19.76"`.

However, it also matches `"lottery numbers: 19 203319 7639"`.

This sort of problem is typical when using regex to extract information 
from textual data.

### Metacharacter `|` (pipe)

`|` allows you to combine subexpressions into an overall expression. It is known as 
**alternation.**

Its syntax is `subexpr1|subexpr2|...|subexprN` which matches anytime one of the
subexpressions listed matches.

For example, both

```bash
printf "That Bob is a great guy" | egrep -n 'Bob|Robert'
```

and

```bash
printf "That Robert is a great guy" | egrep -n 'Bob|Robert'
```

match with the former outputting `1:That Bob is a great guy` and the latter 
`1:That Robert is a great guy`

### Metacharacters `\<` (backslash-less than) and `\>` (backslash-greater than)

`\<` gets the position at the start of a "word" and `\>` gets the position at the end
of the "word" (these can also be referred to as metasequences as they consist of more
than one character).

`\<` and `\>` are **word boundary** metacharacters.

`egrep` considers a "word" to be an alphanumeric sequence, e.g.

```bash
printf "The cat sat on the mat\nWhat does concatenation mean?" | egrep -n '\<cat\>'
```

outputs

```
1:The cat sat on the mat
```

but

```bash
printf "The cat sat on the mat\nWhat does concatenation mean?" | egrep -n 'cat'
```

outputs

```
1:The cat sat on the mat
2:What does concatenation mean?
```

### Metacharacters `?` (question mark), `+` (plus), `*` (star), and `{min,max}` (curly braces)

These metacharacters are **quantifiers.**

A quantifier attaches itself to the immediately preceding item (which can be anything 
from a single normal text character to an arbitrarily complicated subexpression 
contained in parentheses). 
 
Each quantifier has a **minimum and maximum number**.

For the match to be successful, the preceding item has to be matched at least the 
minimum number of times.
 
Once a match is successful, the regex will attempt to carry on matching the 
preceding item as many times as possible, up until the maximum number (or 
until no more matches are found).
 
The quantifiers' minimum and maximum numbers are

- `?`, $(\min,\max)=(0,1)$
- `+`, $(\min,\max)=(1,+\infty)$
- `*`, $(\min,\max)=(0,+\infty)$
- `{min,max}`, $(\min,\max)=($`min`$,$`max`$)$

For example, if 

```bash
TEXT="color\ncolour\ncolouur\ncolouuuuuuuur"
```

then

```bash
printf "$TEXT" | egrep -n 'colou?r'
```

which is equivalent to

```bash
printf "$TEXT" | egrep -n 'colou{0,1}r'
```

both output

```
1:color
2:colour
```

whereas

```bash
printf "$TEXT" | egrep -n 'colou{1,1}r'
```

outputs

```
2:colour
```

and

```bash
printf "$TEXT" | egrep -n 'colou{1,5}r'
```

outputs

```
2:colour
3:colouur
```

and

```bash
printf "$TEXT" | egrep -n 'colou+r'
```

outputs

```
2:colour
3:colouur
4:colouuuuuuuur
```

and 

```bash
printf "$TEXT" | egrep -n 'colou*r'
```

outputs

```
1:color
2:colour
3:colouur
4:colouuuuuuuur
```

## Backreferencing

Not all versions of `egrep` support backreferencing, but for those that do, 
it allows you to match new text that is the same as other text matched 
earlier in the regex.

This is achieved by wrapping subexpressions in parentheses. If `(subexpr)` 
matches, the matched text can be referred later on in the regex as 
`\1`.

For example, if `subexpr1` and `subexpr3` in `(subexpr1)subexpr2(subexpr3)` both 
match, the text matched by `subexpr1` can be referred to later on as `\1` 
and the text matched by `subexpr3` as `\2`, e.g. `(subexpr1)subexpr2(subexpr3)\1\2`

Basically, pairs of parentheses are numbered by counting opening parentheses
 from the left.
 
This is quite powerful as it allows you to construct regexes dynamically and
 to match generic patterns rather than specific instances of those patterns, 
 e.g. the regex

```regexp
\<([A-Za-z]+) +\1\>
```

matches anytime a word is repeated

```bash
printf "The cat sat on the the mat" | egrep -no '\<([A-Za-z]+) +\1\>'
```

outputs

```
1:the the
```

and likewise

```bash
printf "Whatever the weather weather it rain or shine" | egrep -no '\<([A-Za-z]+) +\1\>'
```

outputs

```
1:weather weather
```

## Escaping

This is generally done using `\` and we saw an example of it earlier

```regexp
How are you\?
```

In the regex `How are you?`, the `?` attaches itself to `u` and acts as a quantifier.

But in the above example the desired behaviour was to match a literal `?` at the end which
is why the `\` was required.
  
## Host features

Some features that have very common usage, e.g. case-insensitive matching, 
are not actually provided out-of-the-box by the regular expression language.

However, usually such features will be supported by the host, e.g. for case insensitive 
matching, `egrep` provides the `i` option

```bash
printf "Whatever the weather WeaTher it rain or shine" | egrep -no '\<([A-Za-z]+) +\1\>'
```

does not match but 

```bash
printf "Whatever the weather WeaTher it rain or shine" | egrep -ino '\<([A-Za-z]+) +\1\>'
```

does

```
1:weather WeaTher
```
