---
layout: post
title: A minimal React with Redux example
author: familyguy
comments: true
tags: react redux javascript
---

{% include post-image.html name="download.png" width="200" height="150" alt="" %}

In React, one of the ways to manage application state is via Redux.

Redux is not tied to React, it can also be used with other popular JavaScript
frameworks, e.g. Vue.

Consider the simple UI below (our minimal example):

![Alt Text](/assets/gifs/posts/2020-11-21-a-minimal-react-with-redux-example/demo.gif)

which lets you select a particular dish (starter, main or dessert).

The course selected in the first dropdown determines the dishes in the second
dropdown, e.g. if the user selects `Main` in the first dropdown, the choices in
the second dropdown are main dishes:

`Fillet steak served with a mushroom sauce served with Dauphinoise Potatoes`

`Pan fried Sea Bass with crispy pancetta Served on a bed of sweet potato`

`Vegetable Nut Roast with Apricot & Goats Cheese`

`Pumpkin and Red Onion Tagine`

## Design

This is a very simple UI, but let's take a moment's reflection from a high level
perspective.

### Components

A natural way to write this UI is to have a root `<App />` component with two
child components, `<Courses />` and `<Dishes />`.

`<Courses />` and `<Dishes />` each consist of a single dropdown.

### State

#### Recap

In React, a component can have its own local state.

This state is accessible only to the component itself.

However, it is easily passed down to child components via props.

This passing down can be repeated (prop drilling) to pass the state to any
descendant component. Possibly tedious, but straightforward.

What if we want to pass the state to a non-descendant component, e.g. a sibling?

We can lift the state up to the parent component, then pass it down to the
sibling. Not difficult, but less straightforward than any of the above.

This doesn't always scale well in a large app, e.g.

- Two components' only common ancestor is the root component; state is passed
  all the way up from the first component to the root component, then down to
  the second component.
- One component contains state all other components need to know about; state is
  passed all the way up to the root component, then down to every other
  component!

Such issues are part of the motivation behind application state managers like
Redux, Mobx, Flux, etc. and React's own Context API.

#### Our example

There are only two values for state to care about:

- Course selected
- Dish selected

Only the `<Dishes />` component needs to know about the dish selected (if dish
selected was the only value state cared about, the question of how to manage
application state becomes irrelevant; all state is local, there is no
application state).

The `<Courses />` component **and** the `<Dishes />` component need to know
about the course selected. `<Courses />` because that's the value selected via
its dropdown, and `<Dishes />` because if the course selected is `Starter`, it
needs to display starters in its dropdown, if the course selected is `Main`, it
needs to display mains in its dropdown, etc.

_Course selected is thus application state._

In the next section, we will see an implementation where the course selected in
the `<Courses />` component is lifted up to the parent component and passed down
to the `<Dishes />` and `<Courses />` components, i.e. without Redux.

In the section after that, we will see an implementation where the course
selected is managed by Redux [(Take me straight there).](#with-redux)

[Both implementations are available on GitLab](https://gitlab.com/web-experiments/react-redux-example)
(`master` and `without-redux` branches).

## Implementation

### Without Redux

#### File structure

```
react-redux-example/
├── index.html
└── src
    ├── components
    │   ├── App.js
    │   ├── Courses.js
    │   └── Dishes.js
    └── index.js
```

#### Boilerplate

`index.html`

```html
<!DOCTYPE html>
<html>
  <head>
    <title>React Redux example</title>
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
    src="./src/components/Dishes.js"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/components/Courses.js"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/components/App.js"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/index.js"
    data-plugins="transform-modules-umd"
  ></script>
</html>
```

Load React, Babel (latter transpiles JSX to JavaScript understood by a browser),
and our modules (order of modules is important; `index.js` is at the "top" of
the app, so is loaded last)

Container `<div>` for the React app.

`src/index.js`

```jsx
import { App } from "./components/App";

ReactDOM.render(<App />, document.getElementById("root"));
```

Mount the root component to the correct part of the DOM.

#### Components

`src/components/App.js`

```jsx
import { Courses } from "./Courses";
import { Dishes } from "./Dishes";

export const App = () => {
  const [course, setCourse] = React.useState("starter");
  const onSelectCourse = (event) => {
    setCourse(event.target.value);
  };
  return (
    <>
      <Courses course={course} onSelectCourse={onSelectCourse} />
      <Dishes course={course} />
    </>
  );
};
```

Course selected state `course` lifted up to the root component via
`onSelectCourse` callback.

Course selected state passed down to `<Courses />` and `<Dishes />` components.

`src/components/Courses.js`

```jsx
export const Courses = ({ course, onSelectCourse }) => {
  return (
    <>
      <label forlabel="courses">Choose a course:</label>
      <div>
        <select
          value={course}
          onChange={onSelectCourse}
          name="courses"
          id="courses"
        >
          <option value="starter">Starter</option>
          <option value="main">Main</option>
          <option value="dessert">Dessert</option>
        </select>
      </div>
    </>
  );
};
```

`src/components/Dishes.js`

```jsx
const STARTERS = [
  "Choice Duck & Liver Parfait with Red Onion Jam",
  "Prawn & Avocado Cocktail",
  "Smoked Salmon served with horseradish crème Fraiche & Mixed Leaves",
  "Creamy Garlic Mushrooms on Ciabatta",
  "Smoked Salmon Crayfish & Dill Mousse",
  "Goats Cheese & Onion Filo Tart",
];
const MAINS = [
  "Fillet steak served with a mushroom sauce served with Dauphinoise Potatoes",
  "Pan fried Sea Bass with crispy pancetta Served on a bed of sweet potato",
  "Vegetable Nut Roast with Apricot & Goats Cheese",
  "Pumpkin and Red Onion Tagine",
];
const DESSERTS = [
  "Individual Chocolate & Lime Cheese cake",
  "Crème Brulee",
  "Rhubarb & Apple Crumble",
];

export const Dishes = ({ course }) => {
  const dishes = {
    starter: STARTERS.map((dish, index) => ({ value: index, text: dish })),
    main: MAINS.map((dish, index) => ({ value: index, text: dish })),
    dessert: DESSERTS.map((dish, index) => ({ value: index, text: dish })),
  };
  const [dish, setDish] = React.useState();

  React.useEffect(() => {
    setDish(dishes[course][0].value.toString());
  }, [course]);

  const onChange = (event) => {
    setDish(event.target.value);
  };
  return (
    <>
      <label forlabel="dishes">Choose a dish:</label>
      <div>
        <select value={dish} onChange={onChange} name="dishes" id="dishes">
          {dishes[course].map((dish) => {
            return (
              <option key={dish.value} value={dish.value}>
                {dish.text}
              </option>
            );
          })}
        </select>
      </div>
    </>
  );
};
```

### With Redux

#### File structure

```
react-redux-example/
├── index.html
└── src
    ├── actions.js
    ├── components
    │   ├── App.js
    │   ├── Courses.js
    │   └── Dishes.js
    └── index.js
```

#### Boilerplate

`index.html`

```html
<!DOCTYPE html>
<html>
  <head>
    <title>React Redux example</title>
  </head>
  <body>
    <div id="root"></div>
  </body>
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/react/15.7.0/react-with-addons.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/redux/3.5.2/redux.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/react-redux/4.4.5/react-redux.js"></script>
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
    src="./src/actions.js"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/components/Dishes.js"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/components/Courses.js"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/components/App.js"
    data-plugins="transform-modules-umd"
  ></script>
  <script
    type="text/babel"
    src="./src/index.js"
    data-plugins="transform-modules-umd"
  ></script>
</html>
```

Load extra dependencies for Redux.

`src/index.js`

```jsx
import { App } from "./components/App";

const initialState = { course: "starter" };
const appReducer = (state = initialState, action) => {
  if (action.type === "courseSelected") {
    return {
      ...state,
      course: action.payload,
    };
  }
  return state;
};
const store = Redux.createStore(appReducer);
ReactDOM.render(
  <ReactRedux.Provider store={store}>
    <App />
  </ReactRedux.Provider>,
  document.getElementById("root")
);
```

Wrap the root component `<App />` in a Redux provider so the app knows about
Redux.

In the Redux provider, specify the Redux store.

The Redux state tree is just an object. Its initial value is specified by the
Redux store, in this case `{ course: "starter" }`.

The store reducer `appReducer` updates the state tree according to the action it
receives. This is the only way to update the state tree.

#### Actions

`src/actions.js`

```jsx
export const selectCourse = (payload) => {
  return { type: "courseSelected", payload };
};
```

A Redux action is an object with a `type` property. Usually there is a payload
containing values to update the state tree with.

`selectCourse` is an action creator, it returns an action.

#### Components

`src/components/App.js`

```jsx
import Courses from "./Courses";
import Dishes from "./Dishes";

export const App = () => {
  return (
    <>
      <Courses />
      <Dishes />
    </>
  );
};
```

To me, this is Redux shining. All the application state management is elsewhere!

Note the default imports as supposed to named imports.

`src/components/Courses.js`

```jsx
import { selectCourse } from "../actions";

const Courses = ({ course, onSelectCourse }) => {
  const onChange = (event) => {
    onSelectCourse(event.target.value);
  };
  return (
    <>
      <label forlabel="courses">Choose a course:</label>
      <div>
        <select value={course} onChange={onChange} name="courses" id="courses">
          <option value="starter">Starter</option>
          <option value="main">Main</option>
          <option value="dessert">Dessert</option>
        </select>
      </div>
    </>
  );
};
const mapDispatchToProps = (dispatch) => {
  return {
    onSelectCourse: (course) => dispatch(selectCourse(course)),
  };
};
const mapStateToProps = (state) => {
  return {
    course: state.course,
  };
};
export default ReactRedux.connect(mapStateToProps, mapDispatchToProps)(Courses);
```

The nuts and bolts of Redux:

- Connect our `<Courses />` component to the Redux store via the Redux `connect`
  function
- We must export this connected version of our component, not the original
  component (it must also be a default export)
- `course` prop supplied by Redux via `mapStateToProps` (`state.course`
  corresponds to the `course` property mentioned in `initialState` and
  `appReducer` in `index.js`)
- `onSelectCourse` callback also supplied by Redux via `mapDispatchToProps`
- `onSelectCourse` is fired when a course is selected in the dropdown
  - It passes the course selected to the action creator `selectCourse`
  - Action returned by `selectCourse` contains the course selected in its
    payload
  - Action is dispatched to the Redux store via Redux's `dispatch` function
  - Action dispatched is received via the `action` parameter in `appReducer` in
    `index.js`

`src/components/Dishes.js`

```jsx
const STARTERS = [
  "Choice Duck & Liver Parfait with Red Onion Jam",
  "Prawn & Avocado Cocktail",
  "Smoked Salmon served with horseradish crème Fraiche & Mixed Leaves",
  "Creamy Garlic Mushrooms on Ciabatta",
  "Smoked Salmon Crayfish & Dill Mousse",
  "Goats Cheese & Onion Filo Tart",
];
const MAINS = [
  "Fillet steak served with a mushroom sauce served with Dauphinoise Potatoes",
  "Pan fried Sea Bass with crispy pancetta Served on a bed of sweet potato",
  "Vegetable Nut Roast with Apricot & Goats Cheese",
  "Pumpkin and Red Onion Tagine",
];
const DESSERTS = [
  "Individual Chocolate & Lime Cheese cake",
  "Crème Brulee",
  "Rhubarb & Apple Crumble",
];

const Dishes = ({ course }) => {
  const dishes = {
    starter: STARTERS.map((dish, index) => ({ value: index, text: dish })),
    main: MAINS.map((dish, index) => ({ value: index, text: dish })),
    dessert: DESSERTS.map((dish, index) => ({ value: index, text: dish })),
  };

  const [dish, setDish] = React.useState();

  React.useEffect(() => {
    setDish(dishes[course][0].value.toString());
  }, [course]);

  const onChange = (event) => {
    setDish(event.target.value);
  };
  return (
    <>
      <label forlabel="dishes">Choose a dish:</label>
      <div>
        <select value={dish} onChange={onChange} name="dishes" id="dishes">
          {dishes[course].map((dish) => {
            return (
              <option key={dish.value} value={dish.value}>
                {dish.text}
              </option>
            );
          })}
        </select>
      </div>
    </>
  );
};
const mapStateToProps = (state) => {
  return {
    course: state.course,
  };
};
export default ReactRedux.connect(mapStateToProps)(Dishes);
```

The only interaction with Redux is via the `course` prop.

If the previous component made sense, so should this one!
