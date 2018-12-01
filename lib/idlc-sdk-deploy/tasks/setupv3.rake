require 'json'

# desc 'setup environment'
task :setupv3 do
  raise 'missing metadata file' unless File.exist? 'metadata.json'
  ENV_METADATA = JSON.parse(open('metadata.json').read)['deployments'].first if File.exist? 'metadata.json'
end
