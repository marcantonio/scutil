
Gem::Specification.new do |s|
  s.name        = 'scutil'
  s.version     = '0.3.0'
  s.date        = '2011-10-11'
  s.summary     = 'SSH Command UTILity'
  s.description = <<-EOF
    Scutil is a library for conveniently executing commands 
    remotely via SSH.
EOF
  s.author      = 'Marc Soda'
  s.email       = 'marcantoniosr@gmail.com'
  s.license     = 'MIT'
  s.homepage    = 'http://marcantonio.github.com/scutil'
  s.rdoc_options << '--title' << 'SSH Command UTILity' << '--main' << 'README.rdoc'
  s.extra_rdoc_files = ['README.rdoc', 'THANKS', 'CHANGELOG.md']
  s.add_runtime_dependency 'net-ssh', '>= 2.1.0'
  s.files = %w(
lib/scutil.rb
lib/scutil/connection_cache.rb
lib/scutil/error.rb
lib/scutil/exec.rb
lib/scutil/system_connection.rb
scutil.gemspec
README.rdoc
CHANGELOG.md
THANKS
test/test_scutil.rb
)
end
