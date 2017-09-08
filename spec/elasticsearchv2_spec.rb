require 'spec_helper'

module Idlc
  module Deploy
    describe ElasticsearchV2 do

      it 'requires credentials, region, and endpoint' do
        expect { ElasticsearchV2.new(nil) }.to raise_error ArgumentError
      end

    end
  end
end
