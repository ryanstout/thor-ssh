require 'thor_ssh/actions/empty_directory'

class Thor
  module Actions
    class InjectIntoFile
      def replace!(regexp, string, force)
        unless base.options[:pretend]
          content = base.destination_files.binread(destination)
          if force || !content.include?(replacement)
            content.gsub!(regexp, string)
            base.destination_files.binwrite(destination, content)
          end
        end
      end
    end
  end
end