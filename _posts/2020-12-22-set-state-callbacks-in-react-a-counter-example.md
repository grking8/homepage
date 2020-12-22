---
layout: post
title: Set state callbacks in React, a counter example
author: familyguy
comments: true
tags: react javascript
---

{% include post-image.html name="download.png" width="200" height="150" alt="" %}

In React, we can set state in a functional component, e.g.

```js
const [myState, setMyState] = useState("");
setMyState("myValue");
```

`useState` is a React hook that returns a pair of values: the current state
`myState` and a function `setMyState` that when called updates the current state
`myState`.

In the snippet above, we pass the string `"myValue"` to `setMyState` which
updates the value of `myState` from `""` to `"myValue"`.

We passed in a string and could have equally passed in an integer, object,
array, etc.

However, we can also pass into `setMyState` a function.

This function accepts one argument, the current value of the state we are about
to update, and it returns the new value of the state.

## Why pass in a callback?

At first glance, this seems an unnecessary complication, replacing

```js
setMyState("myValue");
```

with

```js
setMyState((prevMyState) => "myValue");
```

What if the new state depends on the current state? E.g.

```js
setMyState((prevMyState) => prevMyState + "myValue");
```

Well, in that case

```js
setMyState(myState + "myValue");
```

However, the reason for this seemingly unnecessary complication is **React
updates state asynchronously.**

If we call `setMyState` and then call it again, strictly speaking there is no
guarantee when you call `setMyState` the second time that the first update has
completed.

In reality, usually this is not a problem and passing in a value rather than a
callback behaves as expected.

However, as we will see in the example below, this is not always the case.

## A counter example

Suppose we have a button and a counter displayed to the user. Each time the
button is clicked, the counter increases, e.g.

```jsx
export const App = () => {
  const initialCounter = 0;
  const [counter, setCounter] = React.useState(initialCounter);
  const handleAdd = () => {
    setCounter(counter + 1);
  };
  const handleReset = () => {
    setCounter(initialCounter);
  };
  const style = {
    padding: 16,
  };
  return (
    <>
      <div style={style}>Counter: {counter}</div>
      <div style={style}>
        <button onClick={handleAdd}>Add</button>
      </div>
      <div style={style}>
        <button onClick={handleReset}>Reset</button>
      </div>
    </>
  );
};
```

The above works as expected: if we click the button twice, `2` is displayed; if
we click the button three times, `3` is displayed, etc.

However, let's add a delay to `handleAdd`, i.e.

```js
const handleAdd = () => {
  setTimeout(() => setCounter(counter + 1), 2000);
};
```

![Alt Text](/assets/gifs/posts/2020-12-22-set-state-callbacks-in-react-a-counter-example/demo1.gif)

Now, the counter displays `1` instead of `2` even though the button is clicked
twice.

## What went wrong?

Because the state is updated asynchronously, the first call of `setCounter` sees
the value of `counter` at the time of the first click, and the second call of
`setCounter` sees the value of `counter` at the time of the second click.

At both the time of the first click and the second click, `counter` has a value
of zero. Thus each call of `setCounter` increases the value of `counter` from
zero to one which is why we see `1` displayed.

## The fix

Pass in a callback to `setCounter` instead of a value, i.e.

```js
const handleAdd = () => {
  setTimeout(() => setCounter((prevCounter) => prevCounter + 1), 2000);
};
```

![Alt Text](/assets/gifs/posts/2020-12-22-set-state-callbacks-in-react-a-counter-example/demo2.gif)

The button is clicked seven times, and the correct value of `7` is displayed!

## Class based components

For completeness, below is the equivalent code using class based components.

### Version with bug

```jsx
export class App extends React.Component {
  constructor(props) {
    super(props);
    this.initialCounter = 0;
    this.state = { counter: this.initialCounter };
  }
  render() {
    const handleAdd = () => {
      const newCounter = this.state.counter + 1;
      setTimeout(() => this.setState({ counter: newCounter }), 2000);
    };
    const handleReset = () => {
      this.setState({ counter: this.initialCounter });
    };
    const style = {
      padding: 16,
    };
    return (
      <>
        <div style={style}>Counter: {this.state.counter}</div>
        <div style={style}>
          <button onClick={handleAdd}>Add</button>
        </div>
        <div style={style}>
          <button onClick={handleReset}>Reset</button>
        </div>
      </>
    );
  }
}
```

### Version without bug

```jsx
export class App extends React.Component {
  constructor(props) {
    super(props);
    this.initialCounter = 0;
    this.state = { counter: this.initialCounter };
  }
  render() {
    const handleAdd = () => {
      setTimeout(
        () =>
          this.setState((prevState) => {
            return {
              counter: prevState.counter + 1,
            };
          }),
        2000
      );
    };
    const handleReset = () => {
      this.setState({ counter: this.initialCounter });
    };
    const style = {
      padding: 16,
    };
    return (
      <>
        <div style={style}>Counter: {this.state.counter}</div>
        <div style={style}>
          <button onClick={handleAdd}>Add</button>
        </div>
        <div style={style}>
          <button onClick={handleReset}>Reset</button>
        </div>
      </>
    );
  }
}
```
