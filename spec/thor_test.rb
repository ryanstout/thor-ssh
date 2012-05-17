require 'thor'
require 'thor_ssh'


class ThorTest < Thor
  include Thor::Actions
  include ThorSsh::Actions
  
  def self.source_root
    File.dirname(__FILE__)
  end  
end
