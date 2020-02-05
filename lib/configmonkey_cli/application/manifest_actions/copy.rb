module ConfigmonkeyCli
  class Application
    module ManifestAction
      class Copy < Base
        def init hargs_and_opts = {}
          @args, @opts = args_and_opts(hargs_and_opts)
        end

        def prepare
          @opts[:force] = app.opts[:default_yes]
          @source = @args[0]
          @destination = File.join(thor.destination_root, @args[1])
        end

        def simulate
          if thor.options[:pretend]
            destructive
          else
            status :fake, :black, rel(@destination)
          end
        end

        def destructive
          absolute_source = File.join(thor.source_paths[0], @source)
          if FileTest.directory?(absolute_source)
            thor.directory(@source, @destination, @opts)
          else
            thor.copy_file(@source, @destination, @opts)
            if @opts[:chmod] && File.exist?(absolute_source) && File.exist?(@destination)
              mode = @opts[:chmod] == true ? File.stat(absolute_source).mode - 0100000 : @opts[:chmod]
              thor.chmod(@destination, mode) unless mode == File.stat(@destination).mode - 0100000
            end
          end
        end
      end
    end
  end
end
