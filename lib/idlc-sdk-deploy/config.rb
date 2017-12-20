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
      end

      def initialize(region)
        @region = region

        Idlc::Utility.check_for_creds

      rescue Idlc::Utility::MissingCredentials => e
        err("ERROR: #{e.message}\n")
        exit 1
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
