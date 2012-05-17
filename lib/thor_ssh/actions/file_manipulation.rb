class Thor
  module Actions
    # TODO: link_file doesn't make since for links into the gem
    # def link_file(source, *args, &block)
    #   config = args.last.is_a?(Hash) ? args.pop : {}
    #   destination = args.first || source
    #   source = File.expand_path(find_in_source_paths(source.to_s))
    # 
    #   create_link destination, source, config
    # end
    
    
    def chmod(path, mode, config={})
      return unless behavior == :invoke
      path = File.expand_path(path, destination_root)
      say_status :chmod, relative_to_original_destination_root(path), config.fetch(:verbose, true)

      destination_files.chmod(mode, path) unless options[:pretend]
    end
    
    
    def gsub_file(path, flag, *args, &block)
      return unless behavior == :invoke
      config = args.last.is_a?(Hash) ? args.pop : {}

      path = File.expand_path(path, destination_root)
      say_status :gsub, relative_to_original_destination_root(path), config.fetch(:verbose, true)

      unless options[:pretend]
        content = destination_files.binread(path)
        content.gsub!(flag, *args, &block)
        destination_files.binwrite(path, content)
      end
    end
    
    def remove_file(path, config={})
      return unless behavior == :invoke
      path  = File.expand_path(path, destination_root)

      say_status :remove, relative_to_original_destination_root(path), config.fetch(:verbose, true)
      destination_files.rm_rf(path) if !options[:pretend] && destination_files.exists?(path)
    end
    
    
  end
end