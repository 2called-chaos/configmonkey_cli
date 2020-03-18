module ConfigmonkeyCli
  class Application
    module ManifestAction
      class Mkdir < Base
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
          @directories = @args.map{|dir| expand_dst(dir) }
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
            thor.empty_directory(dir, @opts)
          end
        end
      end
    end
  end
end
