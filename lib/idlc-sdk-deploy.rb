require 'aws-sdk-elasticsearchservice'
require 'aws-sigv4'
require 'net/https'
require 'net-telnet'
require 'rspec/core/rake_task'
require 'sshkey'
require 'terraform/binary'
require 'tmpdir'

# Use the packer-binary gem to provide the executable
Terraform::Binary.configure do |config|
  config.version = '0.8.7'
end

require 'idlc-sdk-core'

require 'idlc-sdk-deploy/config'
require 'idlc-sdk-deploy/power'
require 'idlc-sdk-deploy/keypair'
require 'idlc-sdk-deploy/restclient'

Idlc::Deploy::Config.load_tasks
