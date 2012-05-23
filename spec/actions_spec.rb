require 'spec_helper'
require 'thor_test'
require 'vagrant/vagrant_manager'


describe ThorSsh do
  before do
    # Setup the test and connect to a test server
    @thor_test = ThorTest.new
    @thor_test.destination_connection = VagrantManager.connect
  end
  
  after do
    # Close the connection
    # @thor_test.destination_connection.sftp.session.shutdown!
    @thor_test.destination_connection.close
  end
  
  before(:all) do
    @base_path = '/home/vagrant/thortest'
    
    @thor_test = ThorTest.new
    @thor_test.destination_connection = VagrantManager.connect
    @thor_test.destination_files.rm_rf(@base_path)
    # @thor_test.destination_connection.sftp.session.shutdown!
    @thor_test.destination_connection.close
    
  end
  
  it 'should create an empty directory' do
    @thor_test.empty_directory(@base_path)
    @thor_test.destination_files.exists?(@base_path)
  end
  
  it 'should create an empty directory' do
    @thor_test.get('http://www.google.com/', "#{@base_path}/google.txt")
    @thor_test.destination_files.binread("#{@base_path}/google.txt").should match(/Google/)
  end
  
  it 'should create a file and set the text' do
    @thor_test.create_file("#{@base_path}/createdFile", "More awesome content\nSecond Line of content")
    @thor_test.destination_files.binread("#{@base_path}/createdFile").should == "More awesome content\nSecond Line of content"
  end
  
  it "should copy in text" do
    @thor_test.destination_root = @base_path + "/"
    @thor_test.template "templates/test_template.rb.tt"
    @thor_test.destination_files.binread("#{@base_path}/templates/test_template.rb").should match(/Test Ruby File/)
  end
  
  def mode(path)
    ls = @thor_test.destination_server.run("ls -lh \"#{@base_path}/#{path}\"")
    mode = ls.strip.split(/ /).first.strip
    return mode
  end
  
  it "should set the mode" do
    @thor_test.create_file("#{@base_path}/modeFile", "More awesome content")
    @thor_test.chmod("#{@base_path}/modeFile", 0644)
    mode('modeFile').should == '-rw-r--r--'
    @thor_test.chmod("#{@base_path}/modeFile", 0600)
    mode('modeFile').should == '-rw-------'
  end
  
  it "should gsub files" do
    file = "#{@base_path}/gsubFile"
    @thor_test.create_file(file, "More awesome content")
    @thor_test.gsub_file file, /awesome/, 'cool'
    @thor_test.destination_files.binread(file).should == 'More cool content'
  end
  
  it "should remove files" do
    file = "#{@base_path}/removeFile"
    @thor_test.create_file(file, "More awesome content")
    @thor_test.destination_files.exists?(file).should == true
    @thor_test.remove_file(file)
    @thor_test.destination_files.exists?(file).should == false    
  end
  
  it "should inject text into files" do
    file = "#{@base_path}/injectFile"
    @thor_test.create_file(file, "First line\nSecond Line\nThird Line")
    @thor_test.insert_into_file(file, "2.5 line\n", :after => "Second Line\n")
    @thor_test.destination_files.binread(file).should == "First line\nSecond Line\n2.5 line\nThird Line"
  end
  
  it "should create links" do
    file = "#{@base_path}/symFile"
    link_file = "#{@base_path}/linkedFile"
    @thor_test.create_file(file, "Text")
    
    @thor_test.create_link(link_file, file)
    
    @thor_test.destination_files.binread(link_file).should == "Text"
  end
  
  it "should download a file remotely" do
    @thor_test.get('http://nginx.org/download/nginx-1.2.0.tar.gz', '/home/vagrant/nginx-1.2.0.tar.gz')
  end
  
end


