class Thor
  module Actions
    class EmptyDirectory
      # Checks if the directory exists on the detination server
      def exists?
        @base.destination_files.exists?(destination)
      end
      
      def invoke!
        invoke_with_conflict_check do
          @base.destination_files.mkdir_p(destination)
        end
      end
      
      def revoke!
        say_status :remove, :red
        @base.destination_files.rm_rf(destination) if !pretend? && exists?
        given_destination
      end
      
    end
  end
end