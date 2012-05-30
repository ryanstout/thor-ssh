require 'fileutils'

module ThorSsh
  class LocalFile
    attr_reader :base
    
    def initialize(base)
      @base = base
    end
    
    def exists?(path)
      File.exists?(path)
    end
    
    def run(command)
      return system(command)
    end
    
    # Creates the directory at the path on the remote server
    def mkdir_p(path)
      FileUtils.mkdir_p(path)
    end
    
    # Remote the file/folder on the remote server
    def rm_rf(path)
      FileUtils.rm_rf(path)
    end
    alias :unlink :rm_rf
    
    def symlink(old_name, new_name)
      File.symlink(old_name, new_name)
    end

    def link(old_name, new_name)
      File.link(old_name, new_name)
    end
    
    def binread(path)
      data = nil
      File.open(path, "rb") do |f|
        data = f.read
      end
      
      return data
    end
    
    # TODO: we should just move this to a more standard thing
    def binwrite(path, data)
      File.open(path, 'wb') do |file|
        file.write(data)
      end
    end

    def chmod(mode, file_name)
      File.chmod(mode, file_name)
    end
    
    # See if these paths point to the same inode
    def identical?(file1, file2)
      File.identical?(file1, file2)
    end

  end
end