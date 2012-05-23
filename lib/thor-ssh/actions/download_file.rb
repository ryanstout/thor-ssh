require 'thor-ssh/actions/create_file'
require 'open-uri'


# Class to download a file instead of creating it
class Thor
  module Actions
    class DownloadFile < CreateFile
      attr_accessor :source
      
      def initialize(base, source, destination, config={})
        @source = source
        super(base, destination, config)
      end
      
      # def exists?
      #   puts "CHECK EXISTS"
      #   false
      # end
      
      def identical?
        # TODO: find a good way to check if these are identical, then move the file
        # into place depending on user action
        # exists? && @base.destination_files.binread(destination) == render

        puts "CHECK IDENTICAL"
        false
      end
      
      def render
        puts "RENDER: #{source}"
        @render ||= open(source) {|input| input.binmode.read }
      end
      
      
      def download
        # Check for wget
        if @base.exec("which wget").strip != ''
          # We have wget, download with that
          @base.exec("wget \"#{source}\" -O \"#{destination}\"")
        elsif @base.exec("which curl").strip != ''
          # We have curl, download
          @base.exec("curl -o \"#{destination}\" \"#{source}\"")
        else
          # No program to download remotely
          raise "To download files you need either wget or curl on the remote server"
        end
      end
  
      # TODO: invoke_with_conflict_check workes except for diff
      def invoke!
        # invoke_with_conflict_check do
          @base.say_status :download, source
          @base.destination_files.mkdir_p(File.dirname(destination))
          download()
        # end
        given_destination
      end
    end
  end
end