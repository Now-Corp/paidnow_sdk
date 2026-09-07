source 'https://rubygems.org'

gemspec

gem 'rake', '~> 13.0'
gem 'rspec', '~> 3.9'
gem 'webmock', '~> 3.9'

# RuboCop itself requires Ruby >= 2.7, while this gem supports 2.6. Declaring it
# here, conditionally, keeps `bundle install` resolvable across the whole test
# matrix; the lint job runs on a modern Ruby. Pinned to a minor version so a new
# RuboCop release cannot enable new cops and break CI on an unrelated commit.
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7')
  gem 'rubocop', '~> 1.90.0', require: false
end
