V="0.0"

Gem::Specification.new do |gem|
  gem.name    = 'lizard'
  gem.version = V+`git rev-list HEAD '^release_#{V}'`
  gem.date    = Date.today.to_s
  
  gem.summary = "Process/service monitor for Ruby developers on Unix"
  gem.description = "A process/service monitor designed for starting, stopping, restarting, and tracking the state of services on Unixoid systems. It is primarily designed for "application" services (web apps, queue runners, RPC services, etc) and is not intended as a general-purpose init replacement"
  
  gem.authors  = ['Daniel Barlow']
  gem.email    = 'dan@telent.net'
  gem.homepage = 'http://github.com/telent/lizard'
  
  # ensure the gem is built out of versioned files
  gem.files = Dir['Rakefile', '{bin,lib,man,test,spec}/**/*',
                  'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
end

