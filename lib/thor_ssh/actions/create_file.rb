# Extend create file to work over ssh
class Thor
  module Actions
    class CreateFile
      def identical?
        exists? && @base.destination_files.binread(destination) == render
      end
  
      def invoke!
        invoke_with_conflict_check do
          @base.destination_files.mkdir_p(File.dirname(destination))
          @base.destination_files.binwrite(destination, render)
        end
        given_destination
      end
    end
  end
end