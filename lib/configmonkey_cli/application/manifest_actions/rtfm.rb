module ConfigmonkeyCli
  class Application
    module ManifestAction
      class Rtfm < Base
        def init directory, opts = {}
          @directory = directory
          @opts = opts.reverse_merge({
            name: "__THIS_IS_A_GIT_BASED_CONFIG__",
            symbolic: true,
          })
        end

        def prepare
          @actual_directory = expand_dst(@directory)
          @link = File.join(@actual_directory, @opts[:name])
        end

        def simulate
          if thor.options[:pretend]
            destructive
          else
            status :fake, :black, rel(@link)
          end
        end

        def destructive
          thor.create_link(@link, manifest.directory)
        end
      end
    end
  end
end
