require 'net/ssh'
require 'net/sftp'

module ThorSsh
  class RemoteServer
    attr_reader :connection
    
    def initialize(connection)
      @connection = connection
    end

    def run(command)
      return connection.exec!(command)
    end
    
  end
end