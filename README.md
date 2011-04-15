Gems Summary
============

The RubyGems feed and Twitter stream do not distinguish between new gems and updated gems, and announce each new version of a gem.

It was hard for me to follow. That's why I created [Gems Summary](http://gems-summary.heroku.com). It generates everyday a feed post listing separately the new gems released on RubyGems and the updated gems. If a gem is updated several times during a single day, it is mentioned only once in the post.

It's a Sinatra application getting the notifications of new gem versions through a [RubyGems webhook](https://rubygems.org/pages/api_docs#webhook). It runs with Ruby 1.9.2.

In case you want to contribute to the application or customize it to create your own feed, here is how to install and run it locally: 

1. clone the repository
2. run `bundle install`
3. create a `gems-summary-development` PostgreSQL database (yes, it's hardcoded, my bad...)
4. start the server with `shotgun config.ru`
5. create data by hand or by POSTing JSON data to `/version`. Example with [Resty](https://github.com/micha/resty): `resty POST /version '{"name": "rails", "version": "3.1", :project_uri: "https://rubygems.org/gems/rails"}'`

You can run the tests with `bundle exec spec/`.

Error handling is basic: every failed save operations raises an exception. In production it is catched by HopToad.


