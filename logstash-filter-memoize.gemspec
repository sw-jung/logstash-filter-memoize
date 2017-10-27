Gem::Specification.new do |s|
  s.name          = 'logstash-filter-memoize'
  s.version       = '1.0.0'
  s.licenses      = ['Apache License (2.0)']
  s.summary       = 'This filter-plugin provides memoization to any filter you want.'
  s.description   = 'This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program'
  s.homepage      = 'https://github.com/sw-jung/logstash-filter-memoize'
  s.authors       = ['sw.jung']
  s.email         = 'kjss10@gmail.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_runtime_dependency 'lru_redux'
  s.add_development_dependency 'logstash-devutils'
  s.add_development_dependency 'logstash-filter-ruby'
  s.add_development_dependency 'logstash-filter-sleep'
end
