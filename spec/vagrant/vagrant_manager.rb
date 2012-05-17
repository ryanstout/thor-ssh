require 'vagrant'
require 'net/ssh'

# Return an ssh connection
class VagrantManager
  def self.connect
    @vm = Vagrant::Environment.new
    pk_path = @vm.primary_vm.ssh.info[:private_key_path] || @vm.default_private_key_path
    keys = [File.expand_path(pk_path, @vm.root_path)]

    host      = @vm.primary_vm.ssh.info[:host]
    port      = @vm.primary_vm.ssh.info[:port]
    username  = @vm.primary_vm.ssh.info[:username]
    
    puts host
    puts username
    puts port
    puts keys.inspect
    return Net::SSH.start(host, username, :port => port, :keys => keys)
  end
end

