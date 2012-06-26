require 'thor-ssh/local_file'
require 'thor-ssh/local_server'
require 'thor-ssh/remote_file'
require 'thor-ssh/remote_server'
require 'thor-ssh/actions/empty_directory'
require 'thor-ssh/actions/create_file'
require 'thor-ssh/actions/create_link'
require 'thor-ssh/actions/file_manipulation'
require 'thor-ssh/actions/inject_into_file'

module ThorSsh
  module Actions
    
    # Returns a connection to the destination server for this thor class.
    def destination_connection
      @destination_connection
    end
    
    # Sets the connection to the destination server
    def destination_connection=(val)
      @destination_connection = val
    end
    
    # Returns a remote file or File object that can used to query
    # or change the state of files.  If there is no destination_server
    # it is assumed to be local and a normal File class is returned
    def destination_files
      if self.destination_connection
        return @destination_files ||= RemoteFile.new(self, self.destination_connection)
      else
        return @destination_files ||= LocalFile.new(self)
      end
    end
    
    # Returns a RemoteServer instance or a LocalServer instance.
    # Makes it so calls to run events can be called the same reguardless of 
    # the destination.
    def destination_server
      if self.destination_connection
        return @destination_server ||= RemoteServer.new(self, self.destination_connection)
      else
        return @destination_server ||= LocalServer.new(self)
      end
    end
    
    
    # As user takes a block and runs the code inside the block as the
    # specified user.  All actions are run as the user
    #
    # === Parameters
    # username<String>:: Who to run as
    # options<String>:: A hash of options for how to get to this user
    #
    # === Options
    # :shell  - Boolean, should this be invoked in the shell for the user 
    def as_user(username, options={})
      old_run_as_user = @run_as_user
      @run_as_user = username
      yield
      @run_as_user = old_run_as_user
    end
    
    def as_root(options={})
      as_user('root', options) do
        yield
      end
    end
    
    # The user commands should be run as as the moment
    def run_as_user
      @run_as_user
    end
    
    def inside(dir='', config={}, &block)
      raise "inside is not implemented in thor-ssh, please use full paths"
    end
    
    # Similar to run, but silent and always executes on the remote server
    def exec(command, options={})
      return destination_server.run(command, options)
    end
    
    def run(command, options={}, config={})
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
        return exec(command, options)
      end
    end
    
  end
end
