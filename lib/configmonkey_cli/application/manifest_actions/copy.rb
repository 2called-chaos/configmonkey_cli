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
          @destination = expand_dst(@args[1])
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
          has_changed = !File.exist?(@destination)

          if @opts[:after_change] && File.exist?(@destination)
            has_changed = File.binread(absolute_source) != File.binread(@destination)
          end

          if FileTest.directory?(absolute_source)
            _perform_directory(@source, @destination, @opts)
          else
            _perform_file(@source, @destination, @opts)
            if @opts[:chmod] && File.exist?(absolute_source) && File.exist?(@destination)
              mode = @opts[:chmod] == true ? File.stat(absolute_source).mode - 0100000 : @opts[:chmod]
              thor.chmod(@destination, mode) unless mode == File.stat(@destination).mode - 0100000
            end
          end

          @opts[:after_change].call if has_changed && @opts[:after_change]
        end

        def _perform_directory(source, destination, opts)
          thor.directory(source, destination, opts)
        end

        def _perform_file(source, destination, opts)
          thor.copy_file(source, destination, opts)
        end
      end
    end
  end
end
