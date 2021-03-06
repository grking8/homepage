## Summary

Personal website and blog using the [Jekyll theme minima.](https://jekyll.github.io/minima/)

Uses template repository [test-website.](https://github.com/family-guy/test-website)

## Setup on Linux / macOS

-   Install Docker and ensure the Docker daemon is running
-   Clone the repository `git clone https://github.com/family-guy/homepage.git`
-   From the project root, `docker build --tag homepage-dev . --file Dockerfile.dev`
-   With the image built, start a container `docker run --name homepage-dev --publish 4000:4000 --publish 35729:35729 --volume $(pwd):/homepage --rm homepage-dev`

-   Navigate to `http://localhost:4000`, you should see the site running
-   The site should update automatically after updates to source files (the first
    change might require a manual refresh in the browser)
-   To stop the Docker container, `docker container stop homepage-dev`

## Documentation

[Wiki](https://github.com/family-guy/homepage/wiki)

## Contributing Guidelines

This repository is more for personal use, but any comments / pull requests welcome.

## License

[MIT](http://opensource.org/licenses/MIT)
