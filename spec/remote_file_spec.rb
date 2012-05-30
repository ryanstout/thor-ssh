require 'spec_helper'
require 'thor-ssh'

describe ThorSsh do
  before do
    @connection = mock(Net::SFTP)
    @base = mock('base')
    @remote_file = ThorSsh::RemoteFile.new(@base, @connection)
  end
  
  it "should set the connection" do
    @remote_file.connection.should == @connection
  end
  
  it "should check if a remote file exists" do
    sftp_connection = mock("sftp")
    sftp_connection.should_receive(:stat!).with('/test/path') { true }
    sftp_connection.should_receive(:close_channel).ordered.any_number_of_times
    
    @connection.stub(:sftp) { sftp_connection }
    @remote_file.exists?('/test/path').should == true
  end
end