---
layout: post
title: React without Node, Webpack and Babel
author: familyguy
comments: true
tags: react javascript dom
---

{% include post-image.html name="download.png" width="200" height="150" alt="" %}

Suppose your website consisted of a single page

```
my-website/
├── index.html
└── styles.css
```

`index.html` 

```html
<!DOCTYPE html>
<html>
    <head>
        <link rel="stylesheet" href="styles.css">
        <title>Minimal React Page</title>
    </head>
    <body>
        <h1>A React page without Node, Webpack and Babel</h1>
        <p>This is a paragraph.</p>
    </body>
</html>
```

`styles.css`

```css
body {
    background-color: rgb(40, 222, 255)
}
```

Assuming Python 3 is installed, we can view the page as follows:

- `cd /path/to/my-website`
- `python -m http.server`
- Navigate in a browser to `http://localhost:8000`

Say you wanted to create the same page using React without 
any dependencies or build steps, i.e. without Node, Webpack and Babel.

By not using Node, Webpack and Babel, we can see that, at its core,
React is a JavaScript library for creating HTML elements.

Consider how the page above might be written using pure JavaScript


```
my-website/
├── index.html
├── app.js
└── styles.css
```

`index.html`

```html
<!DOCTYPE html>
<html>
    <head>
        <link rel="stylesheet" href="styles.css">
        <title>Minimal React Page</title>
    </head>
    <body>
        <div id="root">
        </div>
    </body>
    <script src="app.js"></script>
</html>
```

`app.js`

```javascript
let body = document.getElementById('root');
let title = document.createElement('h1');
let titleText = document.createTextNode('A React page without Node, Webpack and Babel');
title.appendChild(titleText);
let paragraph = document.createElement('p');
let paragraphText = document.createTextNode('This is a paragraph.')
paragraph.appendChild(paragraphText);
body.appendChild(title);
body.appendChild(paragraph);
```

In React, the equivalent would be

`app.js`

```javascript
const title = React.createElement(
    'h1',
    null,
    'A React page without Node, Webpack and Babel',
);
const paragraph = React.createElement(
    'p',
    null,
    'This is a paragraph.'
);
const div = React.createElement(
    'div',
    null,
    title,
    paragraph
);
ReactDOM.render(
    div,
    document.getElementById('root')
);
```

`index.html`

```html
<!DOCTYPE html>
<html>
    <head>
        <link rel="stylesheet" href="styles.css">
        <title>Minimal React Page</title>
    </head>
    <body>
        <div id="root">
            Loading...
        </div>
    </body>
    <script crossorigin src="https://unpkg.com/react@16/umd/react.development.js"></script>
    <script crossorigin src="https://unpkg.com/react-dom@16/umd/react-dom.development.js"></script>
    <script src="app.js"></script>
</html>
```

We can see we replace our calls to manipulate the 
Document Object Model (DOM) directly using
`document.createElement()`, `document.createTetxtNode()`, etc. with 
`React.createElement()`.

We then use `ReactDOM.render()` to actually add our elements to the DOM (which 
is known in React as mounting).

We can see that, in this simple example, React is a library for manipulating 
the DOM in a more user-friendly way.
