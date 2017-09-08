module Idlc
  module Deploy
    class ElasticsearchV2
      include Idlc::Helpers

      def initialize(credentials, region, endpoint)
        @service_name = 'es'
        @credentials = credentials
        @region = region
        @endpoint = endpoint.strip
        @index_migrations = []
        @tmp_dir = Dir.mktmpdir('es-temp')
        @full_release_path = ''

        # Instantiate an S3 Client
        @s3 = Aws::S3::Client.new(
          region: @region,
          access_key_id: @credentials[:access_key_id],
          secret_access_key: @credentials[:secret_access_key]
        )
      end

      def create_index(app_release, bucket, prefix)
        mapping = es_mapping(bucket, prefix, app_release)
        parts = parse_request(mapping)

        send_signed_request(
          parts[:method],
          "#{@endpoint}#{parts[:path]}",
          parts[:body]
        )
      end

      def delete_index(index)
        send_signed_request('DELETE', "#{@endpoint}/#{index}", '{}')
      end

      def run_migrations(app_release, bucket, prefix)
        migrations = es_migrations(bucket, prefix, app_release)

        migrations.each do |migration|
          parts = parse_request(migration)

          send_signed_request(
            parts[:method],
            "#{@endpoint}#{parts[:path]}",
            parts[:body]
          )
        end
      end

      def cleanup
        debug("keeping directory: #{@tmp_dir} for dubugging")
        return if ENV['DEBUG']

        FileUtils.rm_rf(@tmp_dir)
      end

      private

      def major_minor_patch(version)
        # Strip build number from version number. The migration scripts only include
        # major.minor.patch
        version.split('.')[0..2].join('.')
      end

      def es_mapping(bucket, prefix, app_release)
        get_release(bucket, prefix, app_release)

        # Read Mapping JSON into string
        file = File.open("#{@full_release_path}/es/axiompro_mapping.txt", 'rb')
        mapping = file.read
        file.close

        mapping
      end

      def es_migrations(bucket, prefix, app_release)
        get_release(bucket, prefix, app_release)
        migrations = []

        Dir.glob("#{@full_release_path}/es/Migrations/*.txt").each do |f|
          msg(f)
          file = File.open(f, 'rb')
          migrations.push(file.read)
          file.close
        end

        migrations
      end

      def get_release(src_bucket, app, version)
        @full_release_path = "#{@tmp_dir}/#{app}-#{version}"
        release_archive = "#{@full_release_path}.zip"

        return if File.exist? @full_release_path

        @s3.get_object(
          response_target: release_archive,
          bucket: src_bucket,
          key: "#{app}/#{major_minor_patch(version)}/AxiomPro.#{version}.deploy.zip"
        )

        unzip(release_archive, @full_release_path)
      end

      def unzip(file, destination)
        Zip::ZipFile.open(file) do |zip_file|
          zip_file.each do |f|
            f_path = File.join(destination, f.name)
            FileUtils.mkdir_p(File.dirname(f_path))
            f.extract(f_path)
          end
        end
      end

      def send_signed_request(method, url, payload)
        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        signature = sigv4_signature(method, url, payload)
        request = http_request(method, uri.path, signature, payload)

        response = https.request(request)
        msg("#{response.code} #{response.message} #{response.body}")
      end

      def parse_request(document)
        method = document.lines[0].strip
        path = document.lines[1].strip
        body = document.lines[2..-1].join

        { method: method, path: path, body: body }
      end

      def set_headers(request, signature)
        request.add_field 'host', signature.headers['host']
        request.add_field 'content-type', 'application/json'
        request.add_field 'x-amz-content-sha256', signature.headers['x-amz-content-sha256']
        request.add_field 'x-amz-date', signature.headers['x-amz-date']
        request.add_field 'authorization', signature.headers['authorization']
      end

      def http_request(method, path, signature, payload)
        case method.downcase
        when 'put'
          request = Net::HTTP::Put.new(path)
        when 'get'
          request = Net::HTTP::Get.new(path)
        when 'delete'
          request = Net::HTTP::Delete.new(path)
        else
          request = Net::HTTP::Put.new(path)
        end

        set_headers(request, signature)
        request.body = payload

        request
      end

      def signer
        Aws::Sigv4::Signer.new(
          service: @service_name,
          region: @region,
          access_key_id: @credentials[:access_key_id],
          secret_access_key: @credentials[:secret_access_key]
        )
      end

      def sigv4_signature(method, url, payload)
        signer.sign_request(
          http_method: method,
          url: url,
          headers: {
            'content-type' => 'application/json'
          },
          body: payload
        )
      end
    end
  end
end
