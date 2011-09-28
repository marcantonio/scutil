Gem::Specification.new do |s|
  s.name        = 'scutil'
  s.version     = '0.2.3'
  s.date        = '2011-09-27'
  s.summary     = 'SSH Command UTILity'
  s.description = <<-EOF
    Scutil is a library for conveniently executing commands 
    remotely via SSH.
EOF
  s.author      = 'Marc Soda'
  s.email       = 'marcantoniosr@gmail.com'
  s.license     = 'MIT'
  s.homepage    = 'http://marcantonio.github.com/scutil'
  s.rdoc_options << '--title' << 'SSH Command UTILity' << '--main' << 'README'
  s.extra_rdoc_files = ['README', 'THANKS', 'CHANGELOG']
  s.add_runtime_dependency 'net-ssh', '>= 2.1.0'
  s.files = %w(
lib/scutil.rb
lib/scutil/connection_cache.rb
lib/scutil/error.rb
lib/scutil/exec.rb
lib/scutil/system_connection.rb
scutil.gemspec
README
CHANGELOG
THANKS
test/test_scutil.rb
)
end
