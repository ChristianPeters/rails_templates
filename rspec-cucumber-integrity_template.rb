# Bootstrapping app
run "rm -Rf public/index.html public/images/rails.png public/javascripts/* app/views/layouts/* test"

git :init
git :add => '.'
git :commit => '-a -m "first commit"'

gem 'rake', '0.8.7'
gem 'newrelic_rpm'
gem 'haml'
gem 'compass'
# gem 'will_paginate', :git => 'http://github.com/mislav/will_paginate.git', :branch => 'rails3'
gem 'mongrel', '1.2.0.pre2'
gem 'hoptoad_notifier'

# Testing gems
gem "rspec-rails", :group => [:test, :development]
gem "factory_girl_rails", :git => "https://github.com/thoughtbot/factory_girl_rails.git", :group => :test
gem "autotest", :group => :test
gem "autotest-rails-pure", :group => :test
gem "spork", :git => 'git://github.com/Tho85/spork.git', :group => :test
gem "cucumber-rails", :group => :test
gem "capybara", :group => :test
gem "database_cleaner", :group => :test
gem 'faker', :group => :test

# Development gems
gem 'rails-dev-boost', :git => 'git://github.com/thedarkone/rails-dev-boost.git', :require => 'rails_development_boost', :branch => "c9428f87042d9422aad2b119c8c04de97f504148", :group => :development
gem 'capistrano', :group => :development
gem 'capistrano_colors', :group => :development

run "bundle install"

###
# TODO: Test --spork (should add --drb to .rspec)
###
generate "rspec:install --spork"
generate 'cucumber:install --rspec --capybara --spork'

run "bundle exec spork --bootstrap"
run "bundle exec spork cucumber --bootstrap"

file '.rspec', '--colour --drb'

file 'config/database.yml.ci', <<-CODE
test: &test
  adapter: mysql2
  database: #{@app_name}_test
  pool: 5
  username: integrity_db
  password:
  socket: /var/run/mysqld/mysqld.sock

cucumber:
  <<: *test
CODE

rakefile 'ci.rake', %q(
namespace :ci do

  task :copy_yml do
    system("cp #{Rails.root}/config/database.yml.ci #{Rails.root}/config/database.yml")
  end

  task :deploy do  
    cmd = "(cd #{Rails.root} && %s 2>&1)"
  
    # deploy = IO.popen(cmd % "cap experimental deploy:full", "r") { |io| io.read }    
    # abort "Deployment failed: #{deploy}\n" unless $?.success?
  end
  
  desc "Prepare for CI and run entire test suite"
  # We don't add 'spec' and 'cucumber' here as they depend on 'db:test:prepare', which
  # depends on 'db:abort_if_pending_migrations', which doesn't work as we are not executing
  # all migrations from scratch.
  task :build => ['ci:copy_yml', 'db:test:load']
  
end
)

git :add => '.'
git :commit => '-a -m "applied application template"'

puts <<__END
Done.

You may now start spork, autotest and friends:
$ bundle exec spork
$ bundle exec spork cucumber
$ bundle exec autotest
$ bundle exec cucumber
__END
