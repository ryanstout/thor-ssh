require 'net/ssh'
require 'net/sftp'
require 'stringio'

module ThorSsh
  class RemoteFileWriter
    def initialize(connection, file)
      @connection = connection
      @file = file
      @offset = 0
    end
    
    def write(data)
      puts "WRITE: #{data.size} @ #{@offset}"
      # io = StringIO.new(data)
      @connection.sftp.write!(@file, @offset, data)
      
      puts "WROTE1"
      
      @offset += data.size
    end
  end
  
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
      # puts "DATA: #{data.size}"
      # file = connection.sftp.open!(path, 'wb')
      # 
      # # Write
      # connection.sftp.write!(file, 0, data)
      # 
      # # Close
      # connection.sftp.close!(file)

      io = StringIO.new(data)
      connection.sftp.upload!(io, path)
    end
    
    def file_opened
      puts "COOL)"
    end
    
    def open(file_name, mode, &block)
      # Open file
      file = connection.sftp.open(file_name, 'wb', &method(:file_opened))#, {:chunk_size => 4096})
      
      file_writer = RemoteFileWriter.new(connection, file)
      
      yield(file_writer)
      
      # Close
      connection.sftp.close(file)
      
      # , {:chunk_size => 4096}
      # connection.sftp.file.open(file_name, mode, &block)
      
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