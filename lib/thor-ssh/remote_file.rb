require 'net/ssh'
require 'net/sftp'
require 'stringio'

module ThorSsh  
  class RemoteFile
    attr_reader :connection
    attr_reader :base
    
    def initialize(base, connection)
      @base = base
      @connection = connection
    end

    # This is a workaround for bug:
    # https://github.com/net-ssh/net-sftp/issues/13
    def close_sftp!
      connection.sftp.close_channel()
      connection.instance_variable_set('@sftp', nil)
    end
    
    def exists?(path)
      begin
        res = connection.sftp.stat!(path)
      rescue Net::SFTP::StatusException
        close_sftp!
        return false
      end
      
      close_sftp!
      return true
    end
    
    def run(command)
      return base.exec(command)
    end
    
    # Creates the directory at the path on the remote server
    def mkdir_p(path)
      run "mkdir -p \"#{path}\""
    end
    
    # Remote the file/folder on the remote server
    def rm_rf(path)
      run "rm -rf \"#{path}\""
    end
    alias :unlink :rm_rf
    
    def symlink(old_name, new_name)
      run("ln -s \"#{old_name}\" \"#{new_name}\"")
    end

    def link(old_name, new_name)
      run("ln \"#{old_name}\" \"#{new_name}\"")
    end
    
    def binread(path)
      # If we first logged in as the running user
      if base.destination_server.running_as_current_user?
        data = nil
        connection.sftp.file.open(path, "rb") do |f|
          data = f.read
        end
        close_sftp!
      else
        # We just run this as root, when reading we don't need to go back
        # down to the user
        data = @base.destination_server.run("cat \"#{path}\"")
      end

      return data
    end
    
    # TODO: we should just move this to a more standard thing
    def binwrite(path, data)
      io = StringIO.new(data)
      connection.sftp.upload!(io, path)
      close_sftp!
    end
    
    def chmod(mode, file_name)
      if mode.is_a?(Integer)
        # Mode is an integer, convert to octal
        mode = '%04d' % mode.to_s(8)
      end
      
      return run("chmod #{mode} \"#{file_name}\"")
    end
    
    def inode(file_name)
      return run("ls -i \"#{file_name}\"").strip.split(/ /).first
    end
    
    # See if these paths point to the same inode
    def identical?(file1, file2)
      inode(file1) == inode(file2)
    end

  end
end