module ConfigmonkeyCli
  class Application
    module ManifestAction
      class Template < Copy
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

        def _perform_directory(source, destination, opts)
          status :invalid, :red, "directory not allowed for template", :red
        end

        def _perform_file(source, destination, opts)
          hostname = app.opts[:hostname]
          thor.template(@source, @destination, @opts.merge(context: binding))
        end
      end
    end
  end
end
