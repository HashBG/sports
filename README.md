== README

A small sample app with Rails, AngularJS and CouchDB

To start, setup CouchDB, adopt couchdb.yml respectively, create secret_token and 
add your fixtures to /db/fixtures/OddsFeed.json

=== Sidekiq

bundle exec sidekiq --daemon --logfile log/sidekiq.log 


