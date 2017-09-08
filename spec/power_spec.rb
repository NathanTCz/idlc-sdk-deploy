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
        expect {
          Power.wait_for_response('https://example.com/', 'thisdoesntexist', 0, 0)
        }.to raise_error Power::ConnectionError
      end

      it 'raises if no host is supplied' do
        expect { Power.wait_for_tcp_connection }.to raise_error ArgumentError
      end

      it 'connects successfully' do
        expect(Power.wait_for_tcp_connection('4.2.2.2', 53)).to be true
      end

      it 'times out if no success' do
        expect {
          Power.wait_for_tcp_connection('4.2.2.2', 55, 0.1, 0, 0)
        }.to raise_error Power::ConnectionError
      end

      it 'skips instances marked keep_alive on power off' do
        expect {
          Tag = Struct.new(:key, :value)

          # Mimic Aws::EC2::Instance
          class TestInstance
            attr_reader :tags
            def initialize
              @tags = [Tag.new(
                'keep_alive',
                'true'
              )]
            end
          end

          instance = TestInstance.new

          # This should throw the exception due to keep_alive = 'true'
          Power.stop_instance(instance)
        }.to raise_error Power::InstanceKeepAlive
      end

    end
  end
end
