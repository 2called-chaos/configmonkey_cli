module ConfigmonkeyCli
  class Application
    module ManifestAction
      class Base
        attr_reader :app, :manifest, :args, :opts, :thor

        def initialize app, manifest, *args, &block
          @app = app
          @thor = manifest.thor
          @args = []
          @opts = {}
          @manifest = manifest

          init(*args, &block)
        end

        def to_s
          "#<…::#{self.class.name.split("::").last(2).join("::")} @args=#{@args} @opts=#{@opts}>"
        end
        alias_method :inspect, :to_s

        def args_and_opts hargs_and_opts = {}
          args, opts = [], {}
          hargs_and_opts.each do |k, v|
            if k.is_a?(String)
              args << k << v
            elsif k.is_a?(Symbol)
              opts[k] = v
            else
              raise "what the heck did you pass as a key?"
            end
          end
          [args, opts]
        end

        def rel path
          thor.relative_to_original_destination_root(path)
        end

        def expand_src src = ""
          File.join(manifest.directory, src)
        end

        def expand_dst dst = ""
          File.join(thor.destination_root, dst)
        end

        def exists? *args
          if args[0].is_a?(Hash)
            File.exists?(send(:"expand_#{args[0].keys[0]}", args[0].values[0]))
          else
            File.exists?(args[0])
          end
        end

        def status name, *args
          case args.length
          when 0
            raise ArgumentError("at least name and string is required")
          when 1 # status :fake, rel(@destination)
            thor.say_status name, args[0], :green
          when 2 # status :fake, :green, rel(@destination)
            thor.say_status name, args[1], args[0]
          when 3 # status :fake, :green, rel(@destination), :red
            thor.say_status name, thor.set_color(args[1], *args[2..-1]), args[0]
          end
        end

        ([:padded, :c, :say, :ask, :yes?, :no?] + Manifest::MANIFEST_ACTIONS).each do |meth|
          define_method(meth) do |*args, &block|
            manifest.send(meth, *args, &block)
          end
        end

        def init *a, &b
        end

        def prepare
        end

        def simulate &b
          app.warn self.inspect
        end

        def destructive &b
        end
      end
    end
  end
end
