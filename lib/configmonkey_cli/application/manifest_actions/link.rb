module ConfigmonkeyCli
  class Application
    module ManifestAction
      class Link < Base
        def init hargs_and_opts = {}
          @args, @opts = args_and_opts(hargs_and_opts)
          @opts = @opts.reverse_merge({
            prefix: nil,
            map: "d:d",
            hard: false,
          })
        end

        def prepare
          @opts[:force] = app.opts[:default_yes]
          @opts[:symbolic] = !@opts[:hard]
          @source = @args[0]
          @destination = @args[1]
          map = @opts[:map].split(":")

          # prefix source
          @source = File.join(map[0]["d"] ? thor.destination_root : manifest.directory, @source)
          @destination = File.join(map[1]["d"] ? thor.destination_root : manifest.directory, @destination)

          # prefix target link
          if(@opts[:prefix] && map[1].downcase["p"])
            prefix = "cm--#{manifest.checksum(@opts[:prefix], soft: !map[1]["H"])}--"
            @destination = File.join(File.dirname(@destination), "#{prefix}#{File.basename(@destination)}")
          end
        end

        def simulate
          if thor.options[:pretend]
            destructive
          else
            status :fake, :black, rel(@destination)
          end
        end

        def destructive
          thor.create_link(@destination, @source, @opts)
        end
      end
    end
  end
end
