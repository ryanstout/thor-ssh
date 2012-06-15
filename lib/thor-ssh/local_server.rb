require 'popen4'

module ThorSsh
  class LocalServer
    attr_reader :base
    
    def initialize(base)
      @base = base
    end
    
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

    def run(command, with_codes=false)
      if with_codes
        return run_with_codes(command)
      else
        stdout, stdin, exit_code, exit_signal = run_with_codes(command)
        return stdout
      end
    end
    
  end
end