require 'thor-ssh/remote_file'
require 'thor-ssh/actions/empty_directory'
require 'thor-ssh/actions/create_file'
require 'thor-ssh/actions/create_link'
require 'thor-ssh/actions/file_manipulation'
require 'thor-ssh/actions/inject_into_file'

module ThorSsh
  module Actions
    
    # Returns a connection to the destination server for this thor class.
    def destination_server
      @destination_server
    end
    
    # Sets the destination server connection
    def destination_server=(val)
      @destination_server = val
    end
    
    # Returns a remote file or File object that can used to query
    # or change the state of files.  If there is no destination_server
    # it is assumed to be local and a normal File class is returned
    def destination_files
      if self.destination_server
        return @destination_files ||= RemoteFile.new(self.destination_server)
      else
        return File
      end
    end
    
    def inside(dir='', config={}, &block)
      raise "inside is not implemented in thor-ssh, please use full paths"
    end
    
    def run(command, config={})
      return unless behavior == :invoke

      destination = relative_to_original_destination_root(destination_root, false)
      desc = "#{command} from #{destination.inspect}"

      if config[:with]
        desc = "#{File.basename(config[:with].to_s)} #{desc}"
        command = "#{config[:with]} #{command}"
      end

      say_status :run, desc, config.fetch(:verbose, true)

      unless options[:pretend]
        # config[:capture] ? `#{command}` : system("#{command}")
        return destination_files.run(command)
      end
    end
    
  end
end