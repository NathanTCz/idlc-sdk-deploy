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

  spec.add_development_dependency 'bundler', '~> 2.0.1'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '0.48.1'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'yard'

  spec.add_runtime_dependency 'idlc-sdk-core'
  spec.add_runtime_dependency 'aws-sdk-elasticsearchservice'
  spec.add_runtime_dependency 'aws-sdk-ec2'
  spec.add_runtime_dependency 'net-telnet'
  spec.add_runtime_dependency 'sshkey', '2.0.0'
  spec.add_runtime_dependency 'terraform-binary'
  spec.add_runtime_dependency 'commander', '4.4.6'
  spec.add_runtime_dependency 'terraform_landscape', '0.2.1'
end
