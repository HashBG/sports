require "bundler/capistrano"
require "rvm/capistrano"
require 'capistrano/sidekiq'

server "188.226.193.114", :web, :app, :db, primary: true

set :application, "hashbg-sports"
set :user, "runner"
set :port, 22
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:HashBG/sports.git"
set :branch, "master"

set :sidekiq_env, 'production'

#set :linked_files, %w{config/database.yml config/couchdb.yml}

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "/etc/init.d/unicorn_#{application} #{command}"
    end
  end

  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}"
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.example.yml"), "#{shared_path}/config/database.yml"
    put File.read("config/couchdb.example.yml"), "#{shared_path}/config/couchdb.yml"
    put File.read("config/apis.example.yml"), "#{shared_path}/config/apis.yml"
    put File.read("config/bitcoin.example.yml"), "#{shared_path}/config/bitcoin.yml"
    puts "Now edit the config files in #{shared_path}."
  end
  after "deploy:setup", "deploy:setup_config"
  
  task :bower_install, roles: :app do
    run("cd #{release_path}; /usr/bin/env rake bower:install RAILS_ENV=#{rails_env}")   
  end
  before 'deploy:assets:precompile', "deploy:bower_install"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/couchdb.yml #{release_path}/config/couchdb.yml"
    run "ln -nfs #{shared_path}/config/apis.yml #{release_path}/config/apis.yml"
    run "ln -nfs #{shared_path}/config/bitcoin.yml #{release_path}/config/bitcoin.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
    end
  end
  before "deploy", "deploy:check_revision"
end
