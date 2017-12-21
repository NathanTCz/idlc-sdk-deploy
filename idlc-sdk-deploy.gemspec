# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'idlc-sdk-deploy/version'

Gem::Specification.new do |spec|
  spec.name          = 'idlc-sdk-deploy'
  spec.version       = Idlc::Deploy::VERSION
  spec.authors       = ['Nathan Cazell']
  spec.email         = ['nathan.cazell@imageapi.com']

  spec.summary       = 'IDLC SDK for AWS resources - Deploy'
  spec.description   = 'Provides deploy libraries for idlc-sdk. This gem is part of the IDLC SDK'
  spec.homepage      = 'https://github.com/nathantcz/idlc-sdk'
  spec.license       = 'MIT'

  spec.metadata = {
    'source_code_uri' => 'https://github.com/nathantcz/idlc-sdk-deploy'
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '0.48.1'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'yard'

  spec.add_runtime_dependency 'idlc-sdk-core'
  spec.add_runtime_dependency 'aws-sdk-elasticsearchservice'
  spec.add_runtime_dependency 'aws-sdk-lambda'
  spec.add_runtime_dependency 'aws-sigv4'
  spec.add_runtime_dependency 'net-telnet'
  spec.add_runtime_dependency 'sshkey'
  spec.add_runtime_dependency 'terraform-binary'
  spec.add_runtime_dependency 'terraform_landscape'
end
