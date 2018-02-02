## Ground to Sky: A Flight Search Tool

### Installation
If you do not have bundler installed in your system, run:
```
gem install bundler
```

Then, install all the required dependencies by running:
```
bundler install
```

within the project directory.

Once all the required gems and Ruby with the correct version has been installed, run:
```
bundle exec rackup
```

This will start an instance of the application locally. To access the application, navigate to `localhost:9292` (default) in your web browser. You should be redirected to the landing page.

### PostgreSQL integration
When running the application locally, there is no action required to initialize a PostgreSQL database as this is done automatically.

