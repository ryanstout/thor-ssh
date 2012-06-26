require 'net/ssh'
require 'net/sftp'
require 'stringio'

module ThorSsh
  class PermissionError < StandardError ; end
  
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

    def exec(command, options={})
      return base.exec(command, options)
    end
    
    # Creates the directory at the path on the remote server
    def mkdir_p(path)
      stdout, stderr, _, _ = exec("mkdir -p #{path.inspect}", :with_codes => true)

      if stderr =~ /Permission denied/
        base.say_status :permission_error, stderr, :red
        raise PermissionError, "unable to create directory #{path}"
      end
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
        begin
          # Attempt to upload to the path
          data = connection.sftp.upload!(path)
        rescue Net::SFTP::StatusException => e
          close_sftp!
          raise PermissionError, "Unable to download #{path}"
        end
        
        # connection.sftp.file.open(path, "rb") do |f|
        #   data = f.read
        # end
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
      data = data.gsub(/\n\r/, "\n").gsub(/\r\n/, "\n")
      
      io = StringIO.new(data)
      begin
        # Attempt to upload to the path
        connection.sftp.upload!(io, path)
      rescue Net::SFTP::StatusException => e
        # In the event we don't have permission, upload to 
        # a temp dir, then copy with sudo
        close_sftp!
        
        temp_dir = nil
        base.as_user(nil) do
          current_dir = run("pwd").strip
          temp_dir = "#{current_dir}/.thorssh"
          # Make the dir as the default user
          run("mkdir -p \"#{temp_dir}\"")
        end
        
        temp_file = "#{temp_dir}/#{File.basename(path)}"
        
        # io = StringIO.new(data)
        io = StringIO.new(data)
        connection.sftp.upload!(io, temp_file)
        close_sftp!


        user = base.run_as_user

        # Move the file as the user
        base.as_root do
          folder_path = File.dirname(path)
          unless base.destination_files.exists?(folder_path)
            # Create the directory this is supposed to transfer into
            mkdir_p(folder_path)
            
            # And set the correct user/group
            if user
              chown(user, user, folder_path)
            end
          end
          
          # Move the file
          run("mv #{temp_file.inspect} #{path.inspect}")
        end
        
        unless base.destination_files.exists?(path)
          # Something went wrong
          raise PermissionError, "#{path} failed to create/update failed" 
        end
        
        if user
          # Set the correct user as if this user had uploaded
          # directly.
          base.as_root do
            chown(user, user, path)
          end
        end

        return
      end
      close_sftp!
    end
    
    def chmod(mode, file_name)
      if mode.is_a?(Integer)
        # Mode is an integer, convert to octal
        mode = '%04d' % mode.to_s(8)
      end
      
      return run("chmod #{mode} \"#{file_name}\"")
    end
    
    def chown(user, group, list, options={})
      changed = []
      not_changed = []
      recursive_flag = options[:recursive] ? '-R' : ''
      [list].flatten.each do |file|
        _, _, file_user, file_group = exec("ls -lh #{file.inspect}").split(/\n/).reject {|l| l =~ /^total/ }.last.split(/\s/)
        if user == file_user && group == file_group
          not_changed << file
        else
          changed << file
          base.as_root do
            # We can just always run this as root for the user
            exec("chown #{recursive_flag} #{user}:#{group} #{file.inspect}")
          end
        end
      end
      
      return changed, not_changed
    end
    
    def chown_R(user, group, list)
      return chown(user, group, list, :recursive => true)
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