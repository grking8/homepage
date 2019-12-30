---
layout: post
title: SCSS Local Development with Live Reload
author: familyguy
comments: true
tags: scss live-reload docker local-development
---

{% include post-image.html name="2000px-Sass_Logo_Color.svg.png" width="120" height="100" 
alt="sass logo" %}

If you have SCSS files in your project that you wish to work with during 
local development, a proposed solution follows.

## File structure

Suppose we have a directory `scss-website` with the following structure

```
scss-website
├── assets
│   ├── css
│   └── scss
│       └── styling.scss
└── index.html
```

`index.html`

```html
<!DOCTYPE html>
<html lang="en"> 
    <head>
        <title>My website</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="assets/css/styling.css">
    </head>
    <body>
    	<h1>Welcome user</h1>
    </body>
</html>
```

`assets/scss/styling.scss`

```scss
@import url('https://fonts.googleapis.com/css?family=Source+Serif+Pro');

$primary-font: 'Source Serif Pro', serif;
$primary-bg-colour: yellow;
$primary-colour: blue;

body {
  font-family: $primary-font;
  color: $primary-colour;
  background-color: $primary-bg-colour;
}
```

## Docker

Install Docker and run the Docker daemon.

We are going to add two `Dockerfile`s, one for compiling our SCSS to CSS, and another for running a local development server.

The SCSS `Dockerfile` watches for changes to our SCSS files in `assets/scss` and compiles the results to `assets/css`.

The server `Dockerfile` makes our site available locally and
auto reloads the site in the browser upon detection of changes in source files.

### Dockerfiles

Create a file `Dockerfile.dev-scss` in the project root

```docker
FROM node:latest

ARG PROJECT_DIR="/scss-website"
RUN npm install -g node-sass --unsafe-perm=true
RUN mkdir $PROJECT_DIR
WORKDIR $PROJECT_DIR
ADD . $PROJECT_DIR
CMD ["node-sass", "--watch", "assets/scss/", "--output", "assets/css/"]
```

and a file `Dockerfile.dev-server` in the project root

```docker
FROM node:latest

ARG PROJECT_DIR="/scss-website"
RUN npm install -g live-server
RUN mkdir $PROJECT_DIR
WORKDIR $PROJECT_DIR
ADD . $PROJECT_DIR
EXPOSE 8000
CMD ["live-server", "--port=8000", "--host=0.0.0.0"]
```

then build the Docker files into images

```bash
docker build --tag scss-website-dev-scss . --file Dockerfile.dev-scss
docker build --tag scss-website-dev-server . --file Dockerfile.dev-server
```

## Test local development

- `docker run --name scss-website-dev-scss --volume /path/to/scss-website:/scss-website scss-website-dev-scss`
- Open a new terminal tab / window
- `docker run --name scss-website-dev-server --volume /path/to/scss-website:/scss-website --publish 8000:8000 scss-website-dev-server`
- Navigate to `http://localhost:8000` you should the site running (without any styling)
- `touch /path/to/scss-website/assets/scss/styling.scss`
- Should see site with styling (might need to manually refresh the browser)
- Make a change to `styling.scss`
- Should see site automatically update in browser with change

## Clean up

- `docker container stop scss-website-dev-server`
- `docker containter stop scss-website-dev-scss`
- `docker container prune`
