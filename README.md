== README

A small sample app with Rails, AngularJS and CouchDB

Setup CouchDB, adopt couchdb.yml respectively, create secret_token and 
add your fixtures to /db/fixtures/OddsFeed.json.
After bundle, bower and migrations you should be ready.

=== Sidekiq

bundle exec sidekiq --daemon --logfile log/sidekiq.log 

