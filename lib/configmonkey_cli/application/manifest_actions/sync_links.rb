module ConfigmonkeyCli
  class Application
    module ManifestAction
      class SyncLinks < Base
        def init hargs_and_opts = {}
          @args, @opts = args_and_opts(hargs_and_opts)
          @opts = @opts.reverse_merge({
            prefix: nil,
            map: "d:dp",
            hard: false,
            exclude: [],
          })
        end

        def prepare
          @opts[:force] = app.opts[:default_yes]
          @opts[:symbolic] = !@opts[:hard]

          #-----------------
          @source = @args[0]
          @destination = @args[1]
          map = @opts[:map].split(":")

          # prefix source
          @source = File.join(map[0]["d"] ? thor.destination_root : manifest.directory, @source)
          @destination = File.join(map[1]["d"] ? thor.destination_root : manifest.directory, @destination)

          @sources = Dir[@source]
          @sources = Dir["#{@sources[0]}/*"] if @sources.length == 1 && FileTest.directory?(@sources[0])

          # prefix target link
          if(@opts[:prefix] && map[1].downcase["p"])
            @prefix = "cm--#{manifest.checksum(@opts[:prefix], soft: !map[1]["H"])}--"
            @purge = map[1]["P"]
          end
        end

        def simulate
          status :fake, :black, rel(@destination)
          destructive if thor.options[:pretend]
        end

        def destructive
          prefixed_sources = @sources.map do |src|
            File.join(@destination, "#{@prefix}#{File.basename(src)}")
          end.reject{|f| excluded?(f) }

          if @purge
            (Dir["#{File.join(@destination, @prefix)}*"] - prefixed_sources).each do |f|
              thor.remove_file(f)
              # @todo fix for https://github.com/erikhuda/thor/pull/720
              ::FileUtils.rm_rf(f) if File.symlink?(f)
            end
          end

          @sources.each do |src|
            if r = excluded?(src)
              status :excluded, :black, rel(src) << c(" #{r.inspect}", :black)
            else
              thor.create_link("#{@destination}/#{@prefix}#{File.basename(src)}", src, @opts)
            end
          end
        end

        def excluded? src
          [*@opts[:exclude]].detect do |filter|
            case filter
            when Proc
              filter.call(src)
            when Regexp
              src.match(filter)
            when String
              src.ends_with?(filter)
            end
          end
        end
      end
    end
  end
end
