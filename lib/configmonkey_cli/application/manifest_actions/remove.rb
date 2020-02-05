module ConfigmonkeyCli
  class Application
    module ManifestAction
      class Remove < Base
        def init directory, *sub_directories
          @opts = sub_directories.extract_options!.reverse_merge({
            #_p: true
          })

          # assemble directories
          sub_directories.flatten!
          if sub_directories.any?
            @args = sub_directories.map {|d| File.join(directory, d) }
          else
            @args = [directory]
          end
        end

        def prepare
          @opts[:force] = app.opts[:default_yes]
          @directories = @args.map{|dir| File.join(thor.destination_root, dir) }
        end

        def simulate
          if thor.options[:pretend]
            destructive
          else
            @directories.each do |dir|
              status :fake, :black, @args[0]
            end
          end
        end

        def destructive
          @directories.each do |dir|
            if FileTest.directory?(dir)
              thor.remove_dir(dir, @opts)
            else
              thor.remove_file(dir, @opts)
            end
          end
        end
      end
    end
  end
end
