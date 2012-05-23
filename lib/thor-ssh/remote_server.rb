require 'net/ssh'
require 'net/sftp'

module ThorSsh
  class RemoteServer
    attr_reader :connection
    
    def initialize(connection)
      @connection = connection
    end
    
    def run_with_codes
      stdout_data = ""
      stderr_data = ""
      exit_code = nil
      exit_signal = nil
      connection.open_channel do |channel|
        channel.exec(command) do |ch, success|
          unless success
            abort "FAILED: couldn't execute command (connection.channel.exec)"
          end
          channel.on_data do |ch,data|
            puts data
            stdout_data += data
          end

          channel.on_extended_data do |ch,type,data|
            stderr_data += data
          end

          channel.on_request("exit-status") do |ch,data|
            exit_code = data.read_long
          end

          channel.on_request("exit-signal") do |ch, data|
            exit_signal = data.read_long
          end
        end
        channel.wait
      end      
      # connection.loop

      return stdout_data, stderr_data, exit_code, exit_signal
    end

    def run(command)
      return connection.exec!(command)
    end
    
  end
end