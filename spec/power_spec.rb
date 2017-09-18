require 'spec_helper'

module Idlc
  module Deploy
    describe Power do
      # Define Public interface
      it { should respond_to(:start_instance) }
      it { should respond_to(:stop_instance) }
      it { should respond_to(:update_instance_type) }
      it { should respond_to(:wait_for_response) }
      it { should respond_to(:wait_for_tcp_connection) }

      it 'raises if no endpoint is supplied' do
        expect { Power.wait_for_response }.to raise_error ArgumentError
      end

      it 'finds success text' do
        expect(Power.wait_for_response('https://example.com/', 'Example')).to be true
      end

      it 'times out if no success' do
        expect do
          Power.wait_for_response('https://example.com/', 'thisdoesntexist', 0, 0)
        end.to raise_error Power::ConnectionError
      end

      it 'raises if no host is supplied' do
        expect { Power.wait_for_tcp_connection }.to raise_error ArgumentError
      end

      it 'connects successfully' do
        expect(Power.wait_for_tcp_connection('4.2.2.2', 53)).to be true
      end

      it 'times out if no success' do
        expect do
          Power.wait_for_tcp_connection('4.2.2.2', 55, 0.1, 0, 0)
        end.to raise_error Power::ConnectionError
      end

      context 'checks for keep_alive tag' do

        Tag = Struct.new(:key, :value)

        # Mimic Aws::EC2::Instance
        class TestInstance
          attr_reader :tags
          def initialize(keep_alive)
            @tags = [Tag.new(
              'keep_alive',
              keep_alive
            )]
          end
        end

        it 'skips instances marked keep_alive on power off' do
          expect do
            instance = TestInstance.new(keep_alive="true-#{Time.now.to_i - (2 * 24 * 3600)}")
            # This should throw the exception InstanceKeepAlive due to keep_alive = 'true-01234567'
            # where the timestamp is not yet 7 days old
            Power.stop_instance(instance)
          end.to raise_error Power::InstanceKeepAlive
        end

        it 'turns off instance when not marked keep_alive' do
          expect do
            instance = TestInstance.new(keep_alive='false')
            # This should throw the exception NoMethodError because we are trying
            # run .stop() (from the AWS SDK) on our TestInstance class because keep_alive
            # is set to 'false'
            Power.stop_instance(instance)
          end.to raise_error NoMethodError
        end
      end
    end
  end
end
