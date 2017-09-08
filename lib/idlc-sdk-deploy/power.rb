module Idlc
  module Deploy
    module Power
      class ConnectionError < StandardError; end
      class InstanceKeepAlive < StandardError; end

      class << self
        include Idlc::Helpers

        def start_instance(instance)
          msg('Starting Instance...')
          instance.start(
            dry_run: false
          )
          obj = instance.wait_until_running
          msg('Started Instance: ' + get_name(obj.tags))
        end

        def stop_instance(instance)
          raise InstanceKeepAlive if keep_alive?(instance.tags)

          msg('Stopping Instance...')
          instance.stop(
            dry_run: false
          )
          obj = instance.wait_until_stopped
          msg('Stopped Instance: ' + get_name(obj.tags))
        end

        def enable_keep_alive(instance)
          instance.create_tags(
            dry_run: false,
            tags: [ # required
              {
                key: 'keep_alive',
                value: 'true'
              }
            ]
          )
        end

        def disable_keep_alive(instance)
          instance.create_tags(
            dry_run: false,
            tags: [ # required
              {
                key: 'keep_alive',
                value: 'false'
              }
            ]
          )
        end

        def update_instance_type(instance, type)
          unless instance.instance_type == type
            name = get_name(instance.tags)
            msg "Changing #{name}: #{instance.instance_type} => #{type}"

            instance.modify_attribute(
              dry_run: false,
              attribute: 'instanceType',
              value: type
            )
          end
        end

        def wait_for_tcp_connection(host, port, connection_timeout = 5, wait_timeout = 1500, sleep_time = 10)
          connected = false
          start_time = Time.now

          until connected
            begin
              Net::Telnet.new(
                'Host' => host,
                'Port' => port,
                'Telnetmode' => false,
                'Timeout' => connection_timeout
              )

              connected = true
            rescue ConnectionError, Net::OpenTimeout, Errno::ECONNREFUSED
              check_timeout(start_time, wait_timeout)
              debug("waiting for #{host}:#{port} ... (#{(Time.now - start_time)}s elapsed)")
              sleep sleep_time
            end
          end

          msg "recieved response from #{host}:#{port} !"
          true
        end

        def wait_for_response(endpoint, success_text = nil, wait_timeout = 1500, sleep_time = 10)
          connected = false
          start_time = Time.now

          until connected
            begin
              if success_text.nil? || success_text == ''
                response = http_request("#{endpoint}/diagnostics/ping")
                connected = success(response.body)
              else
                response = http_request(endpoint)
                connected = simple_success(response.body, success_text)
              end
            rescue ConnectionError, Net::OpenTimeout, JSON::ParserError, Errno::ECONNREFUSED
              check_timeout(start_time, wait_timeout)
              sleep sleep_time
            end
          end

          msg "recieved response from #{endpoint} !"
          true
        end

        private

        def keep_alive?(tags)
          k = 'false'

          tags.each do |t|
            k = t.value if t.key == 'keep_alive'
          end

          true?(k)
        end

        def true?(string)
          string.to_s == 'true'
        end

        def get_name(tags)
          name = ''

          tags.each do |t|
            name = t.value if t.key == 'Name'
          end

          # Return
          name
        end

        def http_request(endpoint)
          uri = URI.parse endpoint
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE

          request = Net::HTTP::Get.new(uri.path)
          http.request(request)
        end

        def success(body)
          pong = JSON.parse(body)['data']['pong']
          raise ConnectionError unless pong == true

          true
        end

        def simple_success(body, search_text)
          raise ConnectionError if (body =~ /#{search_text}/).nil?

          true
        end

        def check_timeout(start_time, timeout)
          elapsed_time = Time.now - start_time
          raise ConnectionError, 'Exceeded Timeout for Completion..' if elapsed_time.to_i >= timeout
        end
      end
    end
  end
end
