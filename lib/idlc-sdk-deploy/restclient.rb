require 'aws-sigv4'
require 'json'
require 'net/http'
require 'aws-sdk-lambda'

# Service Definitions
$services = {
  'config' => {
    'endpoint' => 'un0t03st4m.execute-api.us-east-1.amazonaws.com',
    'stage' => 'dev'
  },
  'deploy' => {
    'endpoint' => 'dwervfhpxe.execute-api.us-east-1.amazonaws.com',
    'stage' => 'dev'
  }
}

module Idlc
  module Deploy
    class AWSLambdaProxy
      def fetch(request)
        client = Aws::Lambda::Client.new()

        request[:function] = "#{request[:service]}-" + $services[request[:service]]['stage'] + "-#{request[:lambda]}"
        request[:httpMethod] = request[:method]

        resp = client.invoke({
          function_name: "service-lambda-proxy",
          invocation_type: "RequestResponse",
          log_type: "None",
          payload: request.to_json,
        })

        JSON.parse(JSON.parse(JSON.parse(resp.payload.string)['Payload'])['body'])
      end
    end
    class AWSRestClient
      def initialize(credentials=  {
            access_key_id: ENV['AWS_ACCESS_KEY_ID'],
            secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
          },
          region=ENV['AWS_REGION']
        )
        @service_name = 'execute-api'
        @credentials = credentials
        @region = region
      end

      def fetch(request)
        request = JSON.parse(request)

        endpoint = 'https://' + $config["#{request['service']}_svc"]['endpoint'] + $config["#{request['service']}"]['stage']

        body = ''
        body = request['body'].to_json if request['body']

        resp = send_signed_request(
          request['method'],
          "#{endpoint.strip}#{request['path']}",
          body
        )

        # if request has 'outfile' param, write response to file
        to_file(resp, request['outfile']) if request['outfile']

        # return response obj
        resp
      end

      def to_file(obj, filename)
        File.open(filename, 'w') do |f|
          f.write(obj.to_json)
        end
      end

      private

      def send_signed_request(method, url, payload)
        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        signature = sigv4_signature(method, url, payload)
        request = http_request(method, uri.path, signature, payload)

        response = https.request(request)
        JSON.parse(response.body)
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
        when 'post'
          request = Net::HTTP::Post.new(path)
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
