---
layout: post
title: SCSS Local Development with Webpack and Live Reload
author: familyguy
comments: true
tags: webpack live-reload docker local-development
---

{% include post-image.html name="2000px-Sass_Logo_Color.svg.png" width="120" height="100" 
alt="sass logo" %}

If you have SCSS files in your project that you wish to work with during 
local development, a proposed solution using Webpack follows.

## File structure

Suppose we have a directory `scss-website`

```
scss-website/
├── Dockerfile.bootstrap
├── Dockerfile.dev
├── assets
│   ├── js
│   │   └── index.js
│   └── scss
│       └── styling.scss
├── index.html
└── webpack.config.js
```

`index.html`

```html
<!DOCTYPE html>
<html lang="en"> 
    <head>
        <title>My website</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="assets/main.css">
    </head>
    <body>
    	<h1>Welcome user</h1>
        <script src="assets/main.js"></script>
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

- Install Docker and run the Docker daemon.
- `cd /path/to/scss-website`

### Bootstrap the repository

`Dockerfile.bootstrap`

```docker
FROM node:alpine

ARG PROJECT_DIR="/scss-website"
RUN npm install adddep -g
RUN mkdir $PROJECT_DIR
WORKDIR $PROJECT_DIR
CMD ["sh", \
     "-c", \
     "npm init --yes && adddep \
     webpack \
     webpack-bundle-tracker \
     babel-cli \
     babel-loader \
     webpack-cli \
     css-loader \
     sass-loader \
     style-loader \
     node-sass \
     webpack-dev-server \
     mini-css-extract-plugin"]
```

We will create a `package.json` with the dependencies 
required to run Webpack __without downloading any of them.__

First, build the Docker image

```bash
docker build --tag scss-website-dev-bootstrap . --file Dockerfile.bootstrap
```

then run it

```bash
docker run --name scss-website-dev-bootstrap --volume $(pwd):/scss-website --rm scss-website-dev-bootstrap
```

There should now be a `package.json` in the project root with the required dependencies as  
specified in `Dockerfile.bootstrap`.

### Webpack configuration

`webpack.config.js`

```javascript
const path = require('path');
const BundleTracker = require('webpack-bundle-tracker');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = {
  context: __dirname,
  devServer: {
    host: '0.0.0.0',
    port: 8000,
  },
  entry: {
      main: './assets/js/index.js',
  },
  resolveLoader: {
    modules: [path.resolve(__dirname, '..', 'package', 'node_modules')]
  },
  output: {
    path: path.resolve('./assets/bundles/'),
    publicPath: '/assets/',
    filename: '[name].js',
  },
  plugins: [
    new BundleTracker({filename: './webpack-stats.json'}),
    new MiniCssExtractPlugin({
      filename: '[name].css',
      chunkFilename: '[id]-[hash].css',
    }),
  ],
  module: {
    rules: [
      {
        test: /\.scss$/,
        use: [
          MiniCssExtractPlugin.loader,
          'css-loader',
          'sass-loader',
        ],
      },
    ],
  },
}
```

`assets/js/index.js`

```javascript
import '../scss/styling.scss';
```

### Build the Webpack Docker image

`Dockerfile.dev`

```docker
FROM node:alpine

ARG PROJECT_DIR="/scss-website"
ARG PACKAGE_DIR="/package"
ENV NODE_PATH /package/node_modules
ENV PATH="${PACKAGE_DIR}/node_modules/.bin:${PATH}"
RUN mkdir $PACKAGE_DIR
RUN mkdir $PROJECT_DIR
ADD package.json $PACKAGE_DIR
WORKDIR $PACKAGE_DIR
RUN npm install
WORKDIR $PROJECT_DIR
ADD . $PROJECT_DIR
EXPOSE 8000

CMD ["webpack-dev-server", "--mode development", "--color"]
```

Ensure in `package.json` there is no `/usr/local/bin/node` dependency. Then

```bash
docker build --tag scss-website-dev . --file Dockerfile.dev
```

## Test local development

- `docker run --name scss-website-dev --volume $(pwd):/scss-website --publish 8000:8000 --rm scss-website-dev`
- Navigate to `http://localhost:8000/` in a browser, you should see the contents of `index.html`
- Make a styling change in `assets/scss/styling.scss`
- Styling change should show up automatically in the browser (initial change might require a manual refresh)
