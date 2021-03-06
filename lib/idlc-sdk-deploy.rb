require 'aws-sdk-elasticsearchservice'
require 'aws-sdk-ec2'
require 'aws-sigv4'
require 'net/https'
require 'net/http'
require 'net-telnet'
require 'rspec/core/rake_task'
require 'sshkey'
require 'terraform/binary'
require 'tmpdir'

# Use the packer-binary gem to provide the executable
Terraform::Binary.configure do |config|
  config.version = '0.8.7'
end

# Load the core gem, this also has the service deinitions defined in the $services global variable
require 'idlc-sdk-core'

require 'idlc-sdk-deploy/config'
require 'idlc-sdk-deploy/power'
require 'idlc-sdk-deploy/keypair'

Idlc::Deploy::Config.load_tasks
