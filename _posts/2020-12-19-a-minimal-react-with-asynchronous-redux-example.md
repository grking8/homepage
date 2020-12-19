---
layout: post
title: A minimal React with asynchronous Redux example
author: familyguy
comments: true
tags: react redux javascript asynchronous
---

{% include post-image.html name="download.png" width="200" height="150" alt="" %}

In the
[previous post](https://www.guyrking.com/2020/11/21/a-minimal-react-with-redux-example.html),
we used a simple example to show how application state in React can be managed
with Redux.

In this post, we use the example below to show how application state in React
can be managed asynchronously with Redux.

![Alt Text](/assets/gifs/posts/2020-12-19-a-minimal-react-with-asynchronous-redux-example/demo.gif)

## What do we mean by asynchronous?

In the previous post's example, a user selects a course and afterwards we
immediately update the Redux store with their choice.

Because we update the Redux store immediately, we can use regular JavaScript
running synchronously.

In this post's example, we update the Redux store with data (UTC time) fetched
from an external API, i.e. we have to **wait** for the API's response before we
can update the Redux store.

For JavaScript in a browser, this waiting means your code runs
**asynchronously** (otherwise the browser would freeze whilst waiting for the
network request to complete).

Because the code runs asynchronously, we have to update the Redux store in a
different (and more complicated) way to how we did in the previous post.

## Design

When the user clicks "Show time", the UTC time is fetched from an external API
every second and the three times are displayed.

When the user clicks "Hide time", the above polling stops and the times are not
displayed.

The UTC time is used to calculate the time in Japan and Barbados.

### Components

A natural way to write this UI is to have a root `<App />` component with three
child components, `<BarbadosTime />`, `<JapanTime />`, and `<UTC />`.

`<BarbadosTime />`, `<JapanTime />`, and `<UTC />` each display the relevant
time.

`<App />` has a button acting as a toggle to show or hide the times.

`<UTC />` is responsible for polling the external API to get the UTC time.

### State

There are only two values for state to care about:

- Whether to display the times or not
- UTC time

Only `<App />` needs to know whether to display the times or not, it is local
state.

`<UTC />` needs to know the UTC time because it displays it. `<BarbadosTime />`
and `<JapanTime />` need to know the UTC time because the times they display are
calculated from it (by adding or subtracting the correct number of hours).

_UTC time is thus application state._

In the next section, we will see an implementation where UTC time in `<UTC />`
is lifted up to the parent component `<App />` and passed down to `<UTC />`,
`<BarbadosTime />` and `<JapanTime />`, i.e. without Redux.

In the section after that, we will see an implementation where UTC time is
managed by Redux [(Take me straight there).](#with-redux)

[Both implementations are available on GitLab](https://gitlab.com/web-experiments/react-redux-async-example)
(`master` and `without-redux` branches).

## Implementation

### Without Redux

#### File structure

```
react-redux-async-example/
├── index.html
└── src
    ├── components
    │   ├── App.jsx
    │   ├── BarbadosTime.jsx
    │   ├── JapanTime.jsx
    │   └── UTC.jsx
    └── index.jsx
```

#### Boilerplate

`index.html`

```html
<!DOCTYPE html>
<html>
  <head>
    <title>React Redux async example</title>
  </head>
  <body>
    <div id="root"></div>
  </body>
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
  <script
    crossorigin
    src="https://unpkg.com/react@17/umd/react.development.js"
  ></script>
  <script
    crossorigin
    src="https://unpkg.com/react-dom@17/umd/react-dom.development.js"
  ></script>
  <script
    type="text/babel"
    src="./src/components/BarbadosTime.jsx"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/components/JapanTime.jsx"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/components/UTC.jsx"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/components/App.jsx"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/index.jsx"
    data-plugins="transform-modules-umd"
  ></script>
</html>
```

Load React, Babel, and our modules.

Container `<div>` for the React app.

`src/index.jsx`

```jsx
import { App } from "./components/App";

ReactDOM.render(<App />, document.getElementById("root"));
```

Mount the root component to the correct part of the DOM.

#### Components

`src/components/App.jsx`

```jsx
import { BarbadosTime } from "./BarbadosTime";
import { JapanTime } from "./JapanTime";
import { UTC } from "./UTC";

export const App = () => {
  const [showTime, setShowTime] = React.useState(false);
  const [utcDateTime, setUtcDateTime] = React.useState(null);
  const handleTick = async () => {
    const url = "http://worldclockapi.com/api/json/utc/now";
    const response = await fetch(url);
    const responseData = await response.json();
    setUtcDateTime(
      new Date(responseData.currentFileTime / 10000 - 11644473600000)
    );
  };
  const Welcome = () => <h1>Welcome</h1>;
  if (showTime) {
    return (
      <>
        <Welcome />
        <button onClick={() => setShowTime(false)}>Hide time</button>
        <UTC onTick={handleTick} utcDateTime={utcDateTime} />
        <JapanTime utcDateTime={utcDateTime} />
        <BarbadosTime utcDateTime={utcDateTime} />
      </>
    );
  }
  return (
    <>
      <Welcome />
      <button onClick={() => setShowTime(true)}>Show time</button>
    </>
  );
};
```

UTC time state `utcDateTime` lifted up to the root component via `handleTick`
callback.

UTC time state passed down to `<UTC />`, `<BarbadosTime />`, and `<JapanTime />`
components.

`src/components/UTC.jsx`

```jsx
export const UTC = ({ onTick, utcDateTime }) => {
  let timerId;
  React.useEffect(() => {
    timerId = setInterval(onTick, 1000);
    return () => {
      clearInterval(timerId);
    };
  }, []);
  let utcTime = utcDateTime?.toLocaleTimeString();
  utcTime = utcTime ?? "...";
  return <h3>UTC time is {utcTime}</h3>;
};
```

When the component is mounted, set the timer so `onTick` is called every second.

When the component is unmounted, clear the timer.

`src/components/BarbadosTime.jsx`

```jsx
export const BarbadosTime = ({ utcDateTime }) => {
  const diff = -4;
  const country = "Barbados";
  const barbadosDateTime = new Date(utcDateTime?.getTime());
  barbadosDateTime?.setHours(barbadosDateTime?.getHours() + diff);
  const barbadosTime = barbadosDateTime?.toLocaleTimeString();
  return (
    <h3>
      The time in {country} is{" "}
      {barbadosTime === "Invalid Date" ? "..." : barbadosTime}
    </h3>
  );
};
```

`src/components/JapanTime.jsx`

```jsx
export const JapanTime = ({ utcDateTime }) => {
  const diff = 9;
  const country = "Japan";
  const japanDateTime = new Date(utcDateTime?.getTime());
  japanDateTime?.setHours(japanDateTime?.getHours() + diff);
  const japanTime = japanDateTime?.toLocaleTimeString();
  return (
    <h3>
      The time in {country} is{" "}
      {japanTime === "Invalid Date" ? "..." : japanTime}
    </h3>
  );
};
```

### With Redux

#### File structure

```
react-redux-async-example/
├── index.html
└── src
    ├── components
    │   ├── App.jsx
    │   ├── BarbadosTime.jsx
    │   ├── JapanTime.jsx
    │   └── UTC.jsx
    ├── index.jsx
    └── slice.js
```

#### Boilerplate

`index.html`

```html
<!DOCTYPE html>
<html>
  <head>
    <title>React Redux async example</title>
  </head>
  <body>
    <div id="root"></div>
  </body>
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/react/15.7.0/react-with-addons.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/redux/3.5.2/redux.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/react-redux/4.4.5/react-redux.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/redux-thunk/2.3.0/redux-thunk.min.js"></script>
  <script
    crossorigin
    src="https://unpkg.com/react@17/umd/react.development.js"
  ></script>
  <script
    crossorigin
    src="https://unpkg.com/react-dom@17/umd/react-dom.development.js"
  ></script>
  <script
    type="text/babel"
    src="./src/slice.js"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/components/BarbadosTime.jsx"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/components/JapanTime.jsx"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/components/UTC.jsx"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/components/App.jsx"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/index.jsx"
    data-plugins="transform-modules-umd"
  ></script>
</html>
```

Load extra dependencies for Redux.

Because we are updating Redux asynchronously, we need Redux Thunk also.

`src/index.jsx`

```jsx
import { App } from "./components/App";

const initialState = { utcDateTime: null };
const appReducer = (state = initialState, action) => {
  if (action.type === "utcDateTimeFetched") {
    return {
      ...state,
      utcDateTime: action.payload,
    };
  }
  return state;
};
const store = Redux.createStore(
  appReducer,
  Redux.applyMiddleware(ReduxThunk.default)
);
ReactDOM.render(
  <ReactRedux.Provider store={store}>
    <App />
  </ReactRedux.Provider>,
  document.getElementById("root")
);
```

Same as for the synchronous case before except now we configure the store with
Redux Thunk middleware.

#### Slice

`src/slice.js`

```jsx
const actions = {
  fetchUtcDateTime: (payload) => {
    return { type: "utcDateTimeFetched", payload };
  },
};
export const fetchUtcDateTime = () => {
  return async (dispatch) => {
    const url = "http://worldclockapi.com/api/json/utc/now";
    const response = await fetch(url);
    const responseData = await response.json();
    const utcDateTime = new Date(
      responseData.currentFileTime / 10000 - 11644473600000
    );
    dispatch(actions.fetchUtcDateTime(utcDateTime));
  };
};
```

Before, we had an action creator `selectCourse` in `src/actions.js`. This has
been replaced by a thunk action creator `fetchUtcDateTime` which returns a thunk
function.

`src/slice.js` replaces `src/actions.js`.

A thunk function takes at most two arguments `(dispatch, getState)` and
typically dispatches an action.

Here, the action returned by `actions.fetchUtcDateTime` is dispatched.

#### Components

`src/components/App.jsx`

```jsx
import BarbadosTime from "./BarbadosTime";
import JapanTime from "./JapanTime";
import UTC from "./UTC";

export const App = () => {
  const [showTime, setShowTime] = React.useState(false);
  const Welcome = () => <h1>Welcome</h1>;
  if (showTime) {
    return (
      <>
        <Welcome />
        <button onClick={() => setShowTime(false)}>Hide time</button>
        <UTC />
        <JapanTime />
        <BarbadosTime />
      </>
    );
  }
  return (
    <>
      <Welcome />
      <button onClick={() => setShowTime(true)}>Show time</button>
    </>
  );
};
```

As before, all the application state is elsewhere.

`src/components/UTC.jsx`

```jsx
import { fetchUtcDateTime } from "../slice";

const UTC = ({ onTick, utcDateTime }) => {
  let timerId;
  React.useEffect(() => {
    timerId = setInterval(onTick, 1000);
    return () => {
      clearInterval(timerId);
    };
  }, []);
  let utcTime = utcDateTime?.toLocaleTimeString();
  utcTime = utcTime ?? "...";
  return <h3>UTC time is {utcTime}</h3>;
};
const mapDispatchToProps = (dispatch) => {
  return {
    onTick: () => dispatch(fetchUtcDateTime()),
  };
};
const mapStateToProps = (state) => {
  return {
    utcDateTime: state.utcDateTime,
  };
};
export default ReactRedux.connect(mapStateToProps, mapDispatchToProps)(UTC);
```

The main point of interest is

```js
dispatch(fetchUtcDateTime());
```

Before, in `mapDispatchToProps` we dispatched a plain action (an object) created
by the `selectCourse` action creator.

Now, we dispatch a thunk function, i.e. a function that dispatches a plain
action created by an action creator.

In other words, we have moved the original dispatch into a thunk, and dispatch
the thunk.

The thunk is created by the thunk action creator `fetchUtcDatetime`.

We could dispatch the thunk directly, i.e. without using a thunk action creator.
However, using the latter means:

- We follow the same pattern as before (we used an action creator rather than
  dispatching the action directly)
- We can make extra arguments available to the thunk and thus pass data in the
  component to it

`src/components/BarbadosTime.jsx`

```jsx
const BarbadosTime = ({ utcDateTime }) => {
  const diff = -4;
  const country = "Barbados";
  const barbadosDateTime = new Date(utcDateTime?.getTime());
  barbadosDateTime?.setHours(barbadosDateTime?.getHours() + diff);
  const barbadosTime = barbadosDateTime?.toLocaleTimeString();
  return (
    <h3>
      The time in {country} is{" "}
      {barbadosTime === "Invalid Date" ? "..." : barbadosTime}
    </h3>
  );
};
const mapStateToProps = (state) => {
  return {
    utcDateTime: state.utcDateTime,
  };
};
export default ReactRedux.connect(mapStateToProps)(BarbadosTime);
```

`src/components/JapanTime.jsx`

```jsx
const JapanTime = ({ utcDateTime }) => {
  const diff = 9;
  const country = "Japan";
  const japanDateTime = new Date(utcDateTime?.getTime());
  japanDateTime?.setHours(japanDateTime?.getHours() + diff);
  const japanTime = japanDateTime?.toLocaleTimeString();
  return (
    <h3>
      The time in {country} is{" "}
      {japanTime === "Invalid Date" ? "..." : japanTime}
    </h3>
  );
};
const mapStateToProps = (state) => {
  return {
    utcDateTime: state.utcDateTime,
  };
};
export default ReactRedux.connect(mapStateToProps)(JapanTime);
```
