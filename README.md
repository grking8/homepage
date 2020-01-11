## Summary

Personal homepage / blog using the [Jekyll theme minima.](https://jekyll.github.io/minima/)

Uses template repository [test-website.](https://github.com/family-guy/test-website)

## Local development

### Linux / macOS

- Install Docker and ensure the Docker daemon is running
- Clone the repository `git clone https://github.com/family-guy/homepage.git`
- From the project root, `docker build --tag homepage-dev . --file Dockerfile.dev`
- With the image built, start a container 

```docker
docker run --name homepage-dev --publish 4000:4000 --publish 35729:35729 \
--volume /path/to/homepage:/homepage --rm homepage-dev
```

- Navigate to `http://localhost:4000`, you should see the site running
- The site should update automatically after updates to source files (the first
  change might require a manual refresh in the browser)

## Documentation

[Wiki](https://github.com/family-guy/homepage/wiki)

## Contributing Guidelines

This repository is more for personal use, but any comments / pull requests welcome.

## License

[MIT](http://opensource.org/licenses/MIT)
