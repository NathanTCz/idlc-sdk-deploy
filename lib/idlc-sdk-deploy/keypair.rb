module Idlc
  module Deploy
    module Keypair
      class << self
        def generate(outdir)
          raise ArgumentError, 'Must specify output directory' if outdir.nil?

          FileUtils.mkdir_p outdir unless File.directory? outdir

          private_key_file = "#{outdir}/private_key.pem"
          public_key_file = "#{outdir}/public_key.pem"

          return if File.exist? private_key_file

          rsa_key = SSHKey.generate
          private_key = rsa_key.private_key
          public_key = rsa_key.ssh_public_key

          File.open(private_key_file, 'w') { |file| file.write(private_key) }
          File.open(public_key_file, 'w') { |file| file.write(public_key) }
        end
      end
    end
  end
end
