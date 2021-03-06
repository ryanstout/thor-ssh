require 'vagrant'
require 'net/ssh'

# Return an ssh connection
class VagrantManager
  def self.connect
    @vm = Vagrant::Environment.new(:cwd => File.dirname(__FILE__)).primary_vm

    ssh_info = @vm.ssh.info

    # Build the options we'll use to initiate the connection via Net::SSH
    opts = {
      :port                  => ssh_info[:port],
      :keys                  => [ssh_info[:private_key_path]],
      :keys_only             => true,
      :user_known_hosts_file => [],
      :paranoid              => false,
      :config                => false,
      :forward_agent         => ssh_info[:forward_agent]
      # :verbose => :debug,
      # :timeout => 1
    }

    # Check that the private key permissions are valid
    @vm.ssh.check_key_permissions(ssh_info[:private_key_path])

    # Connect to SSH, giving it a few tries
    return Net::SSH.start(ssh_info[:host], ssh_info[:username], opts)
    
    
    # return Net::SSH.start("127.0.0.1", "vagrant", {:port=>2222, :keys=>["/Users/ryanstout/.vagrant.d/insecure_private_key"], :keys_only=>true, :user_known_hosts_file=>[], :paranoid=>false, :config=>false, :forward_agent=>false, :verbose=>:debug, :timeout=>1})
  end
end

