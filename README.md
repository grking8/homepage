## Summary

Personal homepage / blog using the [Jekyll theme minima.](https://jekyll.github.io/minima/)

Uses template repository [test-website.](https://github.com/family-guy/test-website)

## Installation

### Linux

- Clone the repository `git clone https://github.com/family-guy/homepage.git`
- Install Jekyll, e.g. on Ubuntu (as superuser)
    * `apt-get update`
    * `apt-get upgrade`
    * `apt-get install ruby-full`
    * `gem install jekyll`. Check `jekyll --version`. If error:
    * `gem install bundler`
    * `apt-get install zlib1g-dev`
    * `gem install nokogiri -v '1.8.1'`
    * `bundle install`
    * `jekyll --version`
- `cd /path/to/homepage`
- `jekyll serve --livereload`
- Navigate to `http://localhost:4000` in the browser, you should see the landing page

### macOS

- Clone the repository `git clone https://github.com/family-guy/homepage.git`
- Install system command line tools `xcode-select --install`
- Check `ruby --version` is at least `2.2.5`
- `gem install bundler jekyll`
- `bundle install`
- Check `jekyll version` works
- `cd /path/to/homepage`
- `jekyll serve`
- Navigate to `http://localhost:4000` in a browser, you should see the landing page

## Documentation

[Wiki](https://github.com/family-guy/homepage/wiki)

## Contributing Guidelines

This repository is more for personal use, but any comments / pull requests welcome.

## License

[MIT](http://opensource.org/licenses/MIT)
