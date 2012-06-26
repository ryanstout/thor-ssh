require 'net/ssh'
# require 'net/sftp'

module ThorSsh
  class RemoteServer
    attr_reader :connection
    attr_reader :base
    
    def initialize(base, connection)
      @base = base
      @connection = connection
    end
    
    def run_with_codes(command, options)
      stdout_data = ""
      stderr_data = ""
      exit_code = nil
      exit_signal = nil
      channel = connection.open_channel do |cha|
        # TODO: Lets do more research on request_pty
        # It fixes the bug with "stdin: is not a tty"
        channel.request_pty unless options[:no_pty]
        cha.exec(command) do |ch, success|
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
          
          # channel.on_close do |ch|
          #   puts "Channel is Closing! #{connection.closed?}"
          #   channel.close
          # end
        end
        # puts "Done Loop"
        # channel.close
      end
      connection.loop
      
      return stdout_data, stderr_data, exit_code, exit_signal
    end
    
    def running_as_current_user?
      base.run_as_user && connection.options[:user] == base.run_as_user
    end

    def run(command, options={})
      options[:with_codes] ||= false
      options[:log_stderr] = true unless options.has_key?(:log_stderr)
      # Runs the command with the correct sudo's to get it to the current
      # user.  You can also do as_user(nil) do ... to get to the login
      # user.
      
      # A few notes on running commands as a different user
      # 1) we use -i to get it as if you had logged in directly
      #    as the other user
      # 2) we use bash -c to run it all in bash so things like rediects
      #    and multiple commands work
      if !running_as_current_user? && base.run_as_user != nil
        # We need to change to a different user
        if base.run_as_user == 'root'
         # We need to go up to root
         # TODO: We don't need to run in bash if its not going to pipe
         command = "sudo -i bash -c #{command.inspect}"
       else
         # We need to go up to root, then down to this user
         # This involves running sudo (to go up to root), then running
         # sudo again as the new user, then running the command
         command = "sudo sudo -u #{base.run_as_user} -i bash -c #{command.inspect}"
        end
      end
      stdout_data, stderr_data, exit_code, exit_signal = run_with_codes(command, options)
      
      # if stderr_data.strip != ''
      if exit_code != 0
        base.say "#{exit_code}>> #{command}", :red
        base.say stderr_data, :red
      end
      
      unless options[:keep_colors]
        stdout_data = stdout_data.gsub(/\e\[(\d+)m/, '')
        stderr_data = stderr_data.gsub(/\e\[(\d+)m/, '')
      end
      
      # Remove \r's
      stdout_data = stdout_data.gsub(/\r\n/, "\n").gsub(/\n\r/, "\n").gsub(/\r/, "\n") if stdout_data
      stderr_data = stderr_data.gsub(/\r\n/, "\n").gsub(/\n\r/, "\n").gsub(/\r/, "\n") if stderr_data
      
      if options[:with_codes]
        return stdout_data, stderr_data, exit_code, exit_signal
      else
        return stdout_data
      end
    end
    
  end
end