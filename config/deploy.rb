set :application, "webistrano"
set :repository,  "git@github.com:abatish/webistrano.git"

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :use_sudo, false

set :scm_passphrase, ""

after "deploy:update_code", "deploy:symlink_database_yml"
after "deploy:update_code", "deploy:symlink_email_yml"
after "deploy:symlink", "deploy:symlink_private_directory"

# passenger mods
namespace :deploy do
  # our default deploy is a little different than cap default deploy:
  # We want to:
  #  - run migrations on the deploy.
  #  - actually call stop and start, not just restart.  While this makes no
  #    difference to passenger, it will make a difference if we tie pre- and
  #    post-event hooks restarting things like memcached
  #  - want to display the disabled/enabled page if migrations take any
  #    noticable time.
  task :default do
    update_code
    web:disable
    stop
    symlink
    migrate
    start
    web:enable
  end

  #standard mods for passenger
  task :start do
    restart_passenger
  end

  task :stop do; end

  task :restart do; end

  task :restart_passenger, :roles => :app do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :symlink_database_yml do
    puts "creating database.yml file"
    run "ln -s #{deploy_to}/shared/database.yml #{release_path}/config/database.yml"
  end

  task :symlink_email_yml do
    puts "creating email.yml file"
    run "ln -s #{deploy_to}/shared/email.yml #{release_path}/config/email.yml"
  end

  task :symlink_private_directory do
    puts "symlinking private directory"
    run "ln -s #{deploy_to}/shared/private #{release_path}/private"
  end

end

#Production
role :web, "dcps-node1.codesherpas.com"                          # Your HTTP server, Apache/etc
role :app, "dcps-node1.codesherpas.com"                          # This may be the same as your `Web` server
role :db,  "dcps-node1.codesherpas.com", :primary => true # This is where Rails migrations will run

set :deploy_to, "/var/www/applications/webistrano.blackmanjones.com"
set :keep_releases, 5
set :rails_env, "production"

default_run_options[:pty] = true
set :user, "deploymeister"
ssh_options[:forward_agent] = true
