require 'spec_helper'

module Idlc
  module Deploy
    describe Config do

      context 'no credentials' do

        before do
          ENV['AWS_ACCESS_KEY_ID'] = nil
          ENV['AWS_SECRET_ACCESS_KEY'] = nil
        end

        it 'exits if no credentials are supplied' do
          expect { Config.new(nil) }.to raise_error SystemExit
        end

        it 'raises if the supplied config file does not exist' do
          expect { Config.new.parse('nil') }.to raise_error ArgumentError
        end

      end

      context 'credentials are set' do

        before do
          ENV['AWS_ACCESS_KEY_ID'] = ''
          ENV['AWS_SECRET_ACCESS_KEY'] = ''
          ENV['VERSION_FILE'] = 'spec/test/version'
        end

        describe '#parse' do

          it 'parses YAML config file' do
            Config.new('nil').parse('spec/test/test.config.yml')
            expect(ENV.include?('TF_VAR_env')).to eq true
            expect(ENV['TF_VAR_env']).to eq 'unittest'
          end

          it 'excludes dynamics section of config file' do
            Config.new('nil').parse('spec/test/test.config.yml')
            expect(ENV.include?('TF_VAR_dontparse_dynamic')).to eq false
          end

          it 'excludes *_overrides sections of config file' do
            Config.new('nil').parse('spec/test/test.config.yml')
            expect(ENV.include?('TF_VAR_dontparse_override')).to eq false
          end

        end

      end

      it 'adds TF_VARs to environment' do
        Config.add_deployment_var('key', 'value')
        expect(ENV.include?('TF_VAR_key')).to eq true
        expect(ENV['TF_VAR_key']).to eq 'value'
      end

    end
  end
end
