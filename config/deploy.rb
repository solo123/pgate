require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :domain, 'rb@a.pooulcloud.cn'
set :deploy_to, '/home/rb/work/pgate'
set :repository, 'git://github.com/solo123/pgate.git'
set :branch, 'deploy'
set :work_path, '/home/rb/work'

# For system-wide RVM install.
#   set :rvm_path, '/usr/local/rvm/bin/rvm'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
#set :shared_paths, ['config/database.yml', 'config/secrets.yml', 'log', 'Gemfile', 'Gemfile.lock']

# Optional settings:
#   set :user, 'foobar'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # For those using RVM, use this to load an RVM version@gemset.
  invoke :'rvm:use[ruby-2.3.1@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :clone => :environment do
  queue  %[echo "-----> git clone"]
  queue! %{cd #{work_path}}
  queue! %{git clone #{repository}}
end

task :pull => :environment do
  queue  %[echo "-----> git pull"]
  queue  %[cd #{deploy_to}]
  queue! %{git checkout deploy}
  queue! %{git reset --hard}
  queue! %{git pull origin deploy}

  queue  %{echo "app_name = 'pgate'" > config/puma.rb && cat ../puma/pgate.rb >> config/puma.rb}
  queue  %{cp ../database.yml config}
  queue  %{cp ../secrets.yml config}

  queue! %{bundle install --without development test}
  queue! %{RAILS_ENV=production rails assets:precompile}

  queue  %[echo "-----> restart puma"]
  queue  %{touch /home/rb/tmp/pids/pgate.state}
  queue! %{pumactl restart}

  queue %{echo "====== test after pull ======"}
  queue! %{curl -X POST -d 'a=1' http://a.pooulcloud.cn:8008/payment}
end


desc "Deploys the current version to the server."
task :deploy => :environment do
  to :before_hook do
    # Put things to run locally before ssh
  end
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do
      queue  %[echo "-----> do launch"]

      queue! "pumactl --state #{deploy_to}/tmp/pids/puma-production.state restart"
      #queue %["mkdir -p #{deploy_to}/#{current_path}/tmp/"]
      #queue 'touch tmp/restart.txt'
      #queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
    end
  end

  #bundle exec puma -e production -C config/puma.rb
  #bundle exec pumactl --state tmp/sockets/puma.state stop
  #bundle exec pumactl --state tmp/sockets/puma.state restart
end
