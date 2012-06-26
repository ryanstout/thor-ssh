require 'popen4'

module ThorSsh
  class LocalServer
    attr_reader :base
    
    def initialize(base)
      @base = base
    end
    
    # TODO: This should inherit from the same thing as RemoteServer and
    # it should have the same run but different run_with_codes
    def run_with_codes(command)
      # pid, stdin, stdout, stderr = Open4::popen4(command)
      # ignored, status = Process::waitpid2 pid
      # exit_code = status.to_i
      exit_signal = nil
      
      stdout_data = ''
      stderr_data = ''
      status = POpen4::popen4(command) do |stdout, stderr, stdin, pid|
        stdin.close
        stdout_data = stdout.read
        stderr_data = stderr.read.strip
      end

      exit_code = status ? status.exitstatus : 0

      return stdout_data, stderr_data, exit_code, exit_signal
    end

    def run(command, options={})
      if options[:with_codes]
        return run_with_codes(command)
      else
        stdout, stdin, exit_code, exit_signal = run_with_codes(command)
        return stdout
      end
    end
    
  end
end