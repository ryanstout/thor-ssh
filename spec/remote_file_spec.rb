require 'spec_helper'
require 'thor-ssh'

describe ThorSsh do
  before do
    @connection = mock(Net::SFTP)
    @remote_file = ThorSsh::RemoteFile.new(@connection)
  end
  
  it "should set the connection" do
    @remote_file.connection.should == @connection
  end
  
  it "should check if a remote file exists" do
    sftp_connection = mock("sftp")
    sftp_connection.should_receive(:stat!).with('/test/path') { true }
    
    @connection.stub(:sftp) { sftp_connection }
    @remote_file.exists?('/test/path').should == true
  end
end