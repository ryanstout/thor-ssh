require 'spec_helper'
require 'thor_test'
require 'vagrant/vagrant_manager'
require 'fileutils'


describe ThorSsh do
  before do
    # Setup the test and connect to a test server
    @remote_test = ThorTest.new
    @remote_test.destination_connection = VagrantManager.connect
    
    @local_test = ThorTest.new
    @local_test.destination_root = File.join(File.dirname(__FILE__), '/tmp/')
  end
  
  after do
    # Close the connection
    @remote_test.destination_connection.close
    
    # Clear local tmp dir
    FileUtils.rm_rf(File.join(File.dirname(__FILE__), '/tmp/test/'))
  end
  
  before(:all) do
    @remote_base_path = '/home/vagrant/thortest'
    @local_base_path = File.join(File.dirname(__FILE__), '/tmp/test/')
    
    @remote_test = ThorTest.new
    @remote_test.destination_connection = VagrantManager.connect
    @remote_test.destination_files.rm_rf(@remote_base_path)
    @remote_test.destination_connection.close
    
  end
  
  it 'should create an empty directory remotely' do
    @remote_test.empty_directory(@remote_base_path)
    @remote_test.destination_files.exists?(@remote_base_path)
  end
  
  it 'should create an empty directory locally' do
    @local_test.empty_directory(@local_base_path)
    @local_test.destination_files.exists?(@local_base_path)
  end
  
  it 'should create get a url remotely' do
    @remote_test.get('http://www.google.com/', "#{@remote_base_path}/google.txt")
    @remote_test.destination_files.binread("#{@remote_base_path}/google.txt").should match(/Google/)
  end
  
  it 'should create get a url locally' do
    @local_test.get('http://www.google.com/', "#{@local_base_path}/google.txt")
    @local_test.destination_files.binread("#{@local_base_path}/google.txt").should match(/Google/)
  end
  
  it 'should create a file and set the text remotely' do
    @remote_test.create_file("#{@remote_base_path}/createdFile", "More awesome content\nSecond Line of content")
    @remote_test.destination_files.binread("#{@remote_base_path}/createdFile").should == "More awesome content\nSecond Line of content"
  end
  
  it 'should create a file and set the text locally' do
    @local_test.create_file("#{@local_base_path}/createdFile", "More awesome content\nSecond Line of content")
    @local_test.destination_files.binread("#{@local_base_path}/createdFile").should == "More awesome content\nSecond Line of content"
  end
  
  it "should copy in text remotely" do
    @remote_test.destination_root = @remote_base_path + "/"
    @remote_test.template "templates/test_template.rb.tt"
    @remote_test.destination_files.binread("#{@remote_base_path}/templates/test_template.rb").should match(/Test Ruby File/)
  end
  
  it "should copy in text locally" do
    @local_test.destination_root = @local_base_path + "/"
    @local_test.template "templates/test_template.rb.tt"
    @local_test.destination_files.binread("#{@local_base_path}/templates/test_template.rb").should match(/Test Ruby File/)
  end
  
  def remote_mode(path)
    ls = @remote_test.destination_server.run("ls -lh \"#{@remote_base_path}/#{path}\"")
    mode = ls.strip.split(/ /).first.strip
    return mode
  end
  
  it "should set the mode remotely" do
    @remote_test.create_file("#{@remote_base_path}/modeFile", "More awesome content")
    @remote_test.chmod("#{@remote_base_path}/modeFile", 0644)
    remote_mode('modeFile').should == '-rw-r--r--'
    @remote_test.chmod("#{@remote_base_path}/modeFile", 0600)
    remote_mode('modeFile').should == '-rw-------'
  end
  
  def local_mode(path)
    ls = @local_test.destination_server.run("ls -lh \"#{@local_base_path}/#{path}\"")
    mode = ls.strip.split(/ /).first.strip
    return mode
  end
  
  it "should set the mode locally" do
    @local_test.create_file("#{@local_base_path}/modeFile", "More awesome content")
    @local_test.chmod("#{@local_base_path}/modeFile", 0644)
    local_mode('modeFile').should == '-rw-r--r--'
    @local_test.chmod("#{@local_base_path}/modeFile", 0600)
    local_mode('modeFile').should == '-rw-------'
  end
  
  it "should gsub files remotely" do
    file = "#{@remote_base_path}/gsubFile"
    @remote_test.create_file(file, "More awesome content")
    @remote_test.gsub_file file, /awesome/, 'cool'
    @remote_test.destination_files.binread(file).should == 'More cool content'
  end
  
  it "should gsub files locally" do
    file = "#{@local_base_path}/gsubFile"
    @local_test.create_file(file, "More awesome content")
    @local_test.gsub_file file, /awesome/, 'cool'
    @local_test.destination_files.binread(file).should == 'More cool content'
  end
  
  it "should remove files remotely" do
    file = "#{@remote_base_path}/removeFile"
    @remote_test.create_file(file, "More awesome content")
    @remote_test.destination_files.exists?(file).should == true
    @remote_test.remove_file(file)
    @remote_test.destination_files.exists?(file).should == false    
  end
  
  it "should remove files locally" do
    file = "#{@local_base_path}/removeFile"
    @local_test.create_file(file, "More awesome content")
    @local_test.destination_files.exists?(file).should == true
    @local_test.remove_file(file)
    @local_test.destination_files.exists?(file).should == false    
  end
  
  it "should inject text into files remotely" do
    file = "#{@remote_base_path}/injectFile"
    @remote_test.create_file(file, "First line\nSecond Line\nThird Line")
    @remote_test.insert_into_file(file, "2.5 line\n", :after => "Second Line\n")
    @remote_test.destination_files.binread(file).should == "First line\nSecond Line\n2.5 line\nThird Line"
  end
  
  it "should inject text into files locally" do
    file = "#{@local_base_path}/injectFile"
    @local_test.create_file(file, "First line\nSecond Line\nThird Line")
    @local_test.insert_into_file(file, "2.5 line\n", :after => "Second Line\n")
    @local_test.destination_files.binread(file).should == "First line\nSecond Line\n2.5 line\nThird Line"
  end
  
  it "should create links remotely" do
    file = "#{@remote_base_path}/symFile"
    link_file = "#{@remote_base_path}/linkedFile"
    @remote_test.create_file(file, "Text")
    
    @remote_test.create_link(link_file, file)
    
    @remote_test.destination_files.binread(link_file).should == "Text"
  end
  
  it "should create links locally" do
    file = "#{@local_base_path}/symFile"
    link_file = "#{@local_base_path}/linkedFile"
    @local_test.create_file(file, "Text")
    
    @local_test.create_link(link_file, file)
    
    @local_test.destination_files.binread(link_file).should == "Text"
  end
  
  it "should run exec with an exit code remotely" do
    stdout, stderr, exit_code, exit_signal = @remote_test.exec('false', true)
    exit_code.should == 1
  
    stdout, stderr, exit_code, exit_signal = @remote_test.exec('true', true)
    exit_code.should == 0
  end
  
  it "should run exec with an exit code locally" do
    stdout, stderr, exit_code, exit_signal = @local_test.exec('false', true)
    exit_code.should == 1
  
    stdout, stderr, exit_code, exit_signal = @local_test.exec('true', true)
    exit_code.should == 0
  end
end


