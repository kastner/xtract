set :servers, %w|metaatem|
role :web, *servers
role :app, *servers

set :deploy_to,  "/var/www/xtract.metaatem.net"
set :scm,        :git
set :repository, "git://github.com/kastner/xtract.git"
set :branch,     "origin/master"

set(:latest_release)  { fetch(:deploy_to) }
set(:release_path)    { fetch(:deploy_to) }
set(:current_release) { fetch(:deploy_to) }

set(:current_revision)  { capture("cd #{deploy_to}; git rev-parse --short HEAD").strip }
set(:latest_revision)   { capture("cd #{deploy_to}; git rev-parse --short HEAD").strip }
set(:previous_revision) { capture("cd #{deploy_to}; git rev-parse --short HEAD@{1}").strip }

namespace :deploy do
  desc "Deploy the MFer"
  task :default do
    update
    restart
  end

  desc "Setup an all git deployment."
  task :setup, :except => { :no_release => true } do
    run "git clone #{repository} #{deploy_to}"
    run "chmod g+w #{deploy_to}"
  end
  
  task :update do
    transaction do
      update_code
    end
  end

  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do
    run "cd #{deploy_to}; git fetch origin; git reset --hard #{branch}"
    # finalize_update
  end
  
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{deploy_to}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

  namespace :rollback do
    desc "Moves the repo back to the previous version of HEAD"
    task :repo, :except => { :no_release => true } do
      set :branch, "HEAD@{1}"
      deploy.default
    end
    
    desc "Rewrite reflog so HEAD@{1} will continue to point to at the next previous release."
    task :cleanup, :except => { :no_release => true } do
      run "cd #{deploy_to}; git reflog delete --rewrite HEAD@{1}; git reflog delete --rewrite HEAD@{1}"
    end
    
    desc "Rolls back to the previously deployed version."
    task :default do
      rollback.repo
      rollback.cleanup
    end
  end
end
