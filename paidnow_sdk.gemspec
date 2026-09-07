require File.expand_path('lib/paidnow_sdk/version', __dir__)

Gem::Specification.new do |spec|
  spec.name        = 'paidnow_sdk'
  spec.version     = PaidnowSdk::VERSION
  spec.authors     = ['Ishan-Ravindu']
  spec.summary     = 'Client for the PaidNow invoice funding API'
  spec.description = 'Signs delegate tokens, calls the PaidNow API, verifies webhook ' \
                     'signatures and fetches PaidNow-hosted documents. No web framework, no ORM.'
  spec.homepage    = 'https://github.com/Now-Corp/paidnow_sdk'

  spec.license = 'LicenseRef-Proprietary'

  spec.metadata = {
    'allowed_push_host' => 'https://gem-push-disabled.invalid',
    'source_code_uri' => spec.homepage,
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'changelog_uri' => "#{spec.homepage}/blob/HEAD/CHANGELOG.md"
  }

  spec.required_ruby_version = '>= 2.6.0'

  spec.files = Dir['lib/**/*.rb'] + Dir['spec/**/*.rb'] +
               Dir['README.md', 'LICENSE*', 'CHANGELOG.md', 'Rakefile', '.rspec',
                   'paidnow_sdk.gemspec']
  spec.require_paths = ['lib']

  spec.add_dependency 'http', '>= 4.4', '< 6.0'
  spec.add_dependency 'jwt', '~> 2.5'
end
