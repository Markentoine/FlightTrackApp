## Ground to Sky: A Flight Search Tool

### Installation

#### Bundler
If you do not have bundler installed in your system, run the following command in your terminal:
```
gem install bundler
```

Within your terminal, navigate to the root directory of this project and install all the required dependencies by running:
```
bundler install
```

*If an error says that an incorrect Ruby version is used, you may have to install the specified Ruby version by running `rvm install 2.4.0` (or other version number specified). Then, specify your local system to run the correct Ruby version by running `rvm use 2.4.0`.*

#### PostgreSQL installation
Once all dependecies have been resolved, install PostgreSQL into your system if you don't already have one.

Follow the instructions through this blog:
- For Mac OS X: https://launchschool.com/blog/how-to-install-postgresql-on-a-mac
- For Linux: https://launchschool.com/blog/how-to-install-postgres-for-linux

*Make sure that you also create a superuser by following all the insructions provided. You can ignore the 'Set up Postgres to work with a Rails app' section.*

#### Initializing the application
```
bundle exec rackup
```

This will start an instance of the application as a local server. To access the application, navigate to `localhost:9292` (default) in your web browser. You should be redirected to the landing page.

