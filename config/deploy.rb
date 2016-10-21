require 'mina/rails'
require 'mina/git'
# require 'mina/rbenv'  # for rbenv support. (https://rbenv.org)
require 'mina/rvm'    # for rvm support. (https://rvm.io)
require 'securerandom'

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :domain, 'rb@a.pooulcloud.cn'
set :deploy_to, '/home/rb/work/pgate'
set :repository, 'https://github.com/solo123/pgate.git'
set :branch, 'deploy'

# Optional settings:
#   set :user, 'foobar'          # Username in the server to SSH to.
#   set :port, '30000'           # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# They will be linked in the 'deploy:link_shared_paths' step.
# set :shared_dirs, fetch(:shared_dirs, []).push('config')
set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml')

# This task is the environment that is loaded all remote run commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  invoke :'rvm:use', 'ruby-2.3.1@rails5.0'
end

# Put any custom commands you need to run at setup
# All paths in `shared_dirs` and `shared_paths` will be created on their own.
task :setup do
  # command %{rbenv install 2.3.0}
  in_path './work' do
    command %{pwd}
    command %{cp -R pgate_shared/config #{fetch(:deploy_to)}/shared}
    command %{sed -i '1 a \\ \\ secret_key_base: #{SecureRandom.hex(64)}' #{fetch(:deploy_to)}/shared/config/secrets.yml}
    command %{sed -i '1 a app_name="pgate"' #{fetch(:deploy_to)}/shared/config/puma.rb}
  end
end

desc "Deploys the current version to the server."
task :deploy do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  # invoke :'git:ensure_pushed'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :clean_shared_files
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    #invoke :'rails:db_migrate'
    #invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      in_path(fetch(:current_path)) do
        command %{pumactl --state /home/rb/tmp/pids/puma-pgate.state restart}
      end
    end
  end


  # you can use `run :local` to run tasks on local machine before of after the deploy scripts
  # run :local { say 'done' }
end
task :clean_shared_files do
  command %{rm config/database.yml config/puma.rb config/secrets.yml}
end

task :test do
  run :local do
    comment "test pgate!"
    command %{curl -X POST -d 'a=1' http://a.pooulcloud.cn:8008/payment}
  end
end
# For help in making your deploy script, see the Mina documentation:
#
#  - https://github.com/mina-deploy/mina/docs
