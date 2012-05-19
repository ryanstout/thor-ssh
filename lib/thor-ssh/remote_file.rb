require 'net/ssh'
require 'net/sftp'

module ThorSsh
  class RemoteFile
    attr_reader :connection
    
    def initialize(connection)
      @connection = connection
    end
    
    def exists?(path)
      begin
        connection.sftp.stat!(path)
      rescue Net::SFTP::StatusException
        return false
      end
      
      return true
    end
    
    def run(command)
      return connection.exec!(command)
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
      data = nil
      connection.sftp.file.open(path, "rb") do |f|
        data = f.read
      end
      
      return data
    end
    
    # TODO: we should just move this to a more standard thing
    def binwrite(path, data)
      file = connection.sftp.open!(path, 'wb')
      
      # Write
      connection.sftp.write!(file, 0, data)
      
      # Close
      connection.sftp.close!(file)
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