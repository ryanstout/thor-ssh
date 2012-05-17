require 'thor_ssh/actions/create_file'

class Thor
  module Actions
    class CreateLink
      def identical?
        exists? && base.destination_files.identical?(render, destination)
      end

      def invoke!
        invoke_with_conflict_check do
          base.destination_files.mkdir_p(File.dirname(destination))
          # Create a symlink by default
          config[:symbolic] = true if config[:symbolic].nil?
          base.destination_files.unlink(destination) if exists?
          if config[:symbolic]
            base.destination_files.symlink(render, destination)
          else
            base.destination_files.link(render, destination)
          end
        end
        given_destination
      end

    end
  end
end
