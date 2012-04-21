
require './lib/lizard/version'
base=Lizard::VERSION
Version=base+"."+`git rev-list HEAD '^release_#{base.split(".").join("_")}'|wc -l`

Gem::Specification.new do |s|
  s.name    = 'lizard'
  s.version = Version
  s.date    = Date.today.to_s
  
  s.summary = "Process/service monitor for Ruby developers on Unix"
  s.description = "A process/service monitor designed for starting, stopping, restarting, and tracking the state of services on Unixoid systems. It is primarily designed for \"application\" services (web apps, queue runners, RPC services, etc) and is not intended as a general-purpose init replacement"
  
  s.authors  = ['Daniel Barlow']
  s.email    = 'dan@telent.net'
  s.homepage = 'http://github.com/telent/lizard'
  
  s.require_paths = ["lib"]

  # ensure the gem is built out of versioned files	
  s.files = Dir['Rakefile', '{bin,lib,man,test,spec}/**/*',
                  'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  ["eventmachine"].each do |gem|
    s.add_runtime_dependency gem
  end
  ["rake", "pry"].each do |gem|
    s.add_development_dependency gem
  end


end

