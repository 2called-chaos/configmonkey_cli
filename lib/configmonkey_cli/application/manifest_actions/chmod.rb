module ConfigmonkeyCli
  class Application
    module ManifestAction
      class Chmod < Base
        def init path, mode, opts = {}
          @opts = opts.reverse_merge({
            #_p: true
          })

          @args = [path, mode]
        end

        def prepare
          @path = File.join(thor.destination_root, @args[0])
          @mode = @args[1]
        end

        def simulate
          if thor.options[:pretend]
            destructive
          else
            status :fake, :black, "#{@args[0]} (#{@args[1].to_s(8)})"
          end
        end

        def destructive
          if File.exist?(@path)
            if @mode == File.stat(@path).mode - 0100000
              status :identical, :blue, "#{@args[0]} (#{@args[1].to_s(8)})"
            else
              thor.chmod(@path, @mode)
            end
          else
            status :noexist, :red, "#{@args[0]} (#{@args[1].to_s(8)})"
          end
        end
      end
    end
  end
end
