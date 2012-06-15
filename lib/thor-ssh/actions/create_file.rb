# Extend create file to work over ssh
class Thor
  module Actions
    def read_file(path)
      destination_files.binread(path)
    end
    
    class CreateFile
      def identical?
        exists? && @base.destination_files.binread(destination) == render
      end
  
      def invoke!
        invoke_with_conflict_check do
          @base.destination_files.mkdir_p(File.dirname(destination))
          @base.destination_files.binwrite(destination, render)
          # @base.destination_files.open(destination, 'wb') { |f| f.write render }
        end
        given_destination
      end
    end
  end
end