require 'net/ssh'
require 'net/sftp'

module ThorSsh
  class RemoteServer
    attr_reader :connection
    attr_reader :base
    
    def initialize(base, connection)
      @base = base
      @connection = connection
    end
    
    def run_with_codes(command)
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
        # channel.wait
      end
      connection.loop

      return stdout_data, stderr_data, exit_code, exit_signal
    end
    
    def running_as_current_user?
      base.run_as_user && connection.options[:user] != base.run_as_user
    end

    def run(command, with_codes=false)
      if running_as_current_user?
        # We need to change to a different user
        if base.run_as_user == 'root'
         # We need to go up to root
         command = "sudo #{command}"
       else
         # We need to go up to root, then down to this user
         # This involves running sudo (to go up to root), then running
         # sudo again as the new user, then running the command
         command = "sudo sudo -u #{base.run_as_user} #{command}"
        end
      end
      results = run_with_codes(command)
      if with_codes
        return results
      else
        return results.first
      end
    end
    
  end
end