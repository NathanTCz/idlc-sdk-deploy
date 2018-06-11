module Idlc
  module Deploy
    class Config
      include Idlc::Helpers

      class << self
        def load_tasks
          Dir.glob("#{__dir__}/tasks/*.rake").each do |task_file|
            load task_file
          end
        end

        def add_deployment_var(key, value)
          ENV["TF_VAR_#{key}"] = value
        end

        def get_deployment_var(key)
          ENV["TF_VAR_#{key}"]
        end

        def get_deployment_output(key)
          `#{Terraform::Binary::Command.binary} output #{key}`.strip!
        end

        def whoami
          # This method is meant to be run on an instance inside of a chef run to
          # provision instance and environment metadata.

          ENV['AWS_REGION'] = 'us-east-1' if ENV['AWS_REGION'].nil?

          # Get the current instance id from the instance metadata.
          instance = get_instance

          # return environment metadata
          metadata = get_env_metadata(instance['tags']['environment_key'])
          metadata['hostname'] = set_hostname(instance)

          metadata
        end

        def get_env_metadata(env_key)
          client = Idlc::AWSLambdaProxy.new()

          request = {
            service: 'deploy',
            method: 'GET',
            lambda: 'metadata',
            pathParameters: {
              jobName: env_key
            }
          }
          metadata = client.fetch(request)['deployments'].first

          request = {
            service: 'config',
            method: 'GET',
            lambda: "accounts",
            pathParameters: {
              accountName: metadata['environment']['account_alias']
            }
          }
          account = client.fetch(request)

          metadata['account'] = account['accounts'].first

          request = {
            service: 'config',
            method: 'GET',
            lambda: "applications",
            pathParameters: {
              appName: metadata['environment']['application_name'].downcase
            }
          }
          application = client.fetch(request)

          metadata['application'] = application['applications'].first

          # find db instance
          metadata['instances'].each do |instance|
            if (instance['hostname'].start_with? 'db' || instance['hostname'].start_with? 'rds')
              metadata['db_instance'] = instance
              break
            end
          end

          metadata
        end

        def get_instance
          # Get the current instance id from the instance metadata.
          metadata_endpoint = 'http://169.254.169.254/latest/meta-data/'
          instance_id = Net::HTTP.get( URI.parse( metadata_endpoint + 'instance-id' ) )

          # Create instance object with instance id.
          instance = Aws::EC2::Instance.new( id: instance_id, region: ENV['AWS_REGION'] )

          # save some instance info
          i = {}
          i['instance_id'] = instance_id

          # save tags
          i['tags'] = {}
          instance.tags.each do |tag|
            # Grab all of the tags as node attributes
            i['tags'][tag.key] = tag.value
          end

          i
        end

        def set_hostname (instance)
          hostname = instance['tags']['Name']

          unless (instance['tags']['Name'].start_with? 'db')
            # Use instance id for unique hostname
            hostname = instance['tags']['Name'][0..4] + '-' + instance['instance_id'][2..10]
          end

          ec2_instance = Aws::EC2::Instance.new( id: instance['instance_id'], region: ENV['AWS_REGION'] )
          ec2_instance.create_tags(
            dry_run: false,
            tags: [ # required
              {
                key: 'hostname',
                value: hostname
              }
            ]
          )

          #return
          hostname
        end
      end

      def initialize(region)
        @region = region

        Idlc::Utility.check_for_creds

      rescue Idlc::Utility::MissingCredentials => e
        msg("WARN: #{e.message}\nFalling back to implicit authentication.")
      end

      def configure_state(bucket, sub_bucket, working_directory)
        validate_environment

        tf_version = Terraform::Binary::config.version.split('.')

        configure_tfstatev8(bucket, sub_bucket, working_directory) if tf_version[0].to_i == 0 && tf_version[1].to_i <= 8
        configure_tfstatev9(bucket, sub_bucket, working_directory) if tf_version[0].to_i >= 0 && tf_version[1].to_i > 8
      end

      def parse(config_file)
        raise ArgumentError, "#{config_file} does not exist" unless File.exist? config_file
        Config.add_deployment_var('inf_config_file', config_file)

        # Parse the config file
        YAML.load_file(config_file)['configuration'].each do |section, body|
          next if section == 'dynamics' # skip the dynamics sections
          next unless (section =~ /overrides/).nil? # skip the app overrides sections
          next if body.nil?
          body.each do |key, value|
            debug("#{section}: #{key} = #{value}")
            Config.add_deployment_var(key, value)
          end
        end
      end

      private

      def configure_tfstatev8(bucket, sub_bucket, working_directory)
        args = []
        args << '-backend=s3'
        args << '-backend-config="acl=private"'
        args << "-backend-config=\"bucket=#{bucket}\""
        args << '-backend-config="encrypt=true"'
        args << "-backend-config=\"key=#{sub_bucket}/terraform.tfstate\""
        args << "-backend-config=\"region=#{@region}\""

        Terraform::Binary.remote("config #{args.join(' ')}")
        Terraform::Binary.get("-update #{working_directory}")
      end

      def configure_tfstatev9(bucket, sub_bucket, working_directory)
        args = []
        args << "-backend-config=\"bucket=#{bucket}\""
        args << "-backend-config=\"key=#{sub_bucket}/terraform.tfstate\""
        args << "-backend-config=\"region=#{@region}\""
        args << "-force-copy"

        Terraform::Binary.init("#{args.join(' ')} #{working_directory}")
      end

      def validate_environment
        %w[
          TF_VAR_tfstate_bucket
          TF_VAR_job_code
          TF_VAR_env
          TF_VAR_domain
        ].each do |var|
          raise "missing #{var} in environment" unless ENV.include? var
        end
      end
    end
  end
end
