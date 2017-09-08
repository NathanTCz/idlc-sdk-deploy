require 'spec_helper'

module Idlc
  module Deploy
    describe Keypair do

      it 'requires output dirctory' do
        expect { Idlc::Deploy::Keypair.generate(nil) }.to raise_error ArgumentError
      end

    end
  end
end
