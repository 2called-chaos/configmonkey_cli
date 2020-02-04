module ConfigmonkeyCli
  class Application
    class Configuration
      module AppHelper
        def cm_cfg_path
          ENV["CM_CFGDIR"].presence || File.expand_path("~/.configmonkey")
        end

        def cm_cfg_configfile
          "#{cm_cfg_path}/config.rb"
        end

        def load_appconfig
          return unless File.exist?(cm_cfg_configfile)
          eval File.read(cm_cfg_configfile, encoding: "utf-8"), binding, cm_cfg_configfile
        end

        def generate_manifest directory
          #FileUtils.mkdir_p(config_directory)
          #File.open(config_filename(name), "w", encoding: "utf-8") do |f|
          #  f << File.read("#{File.dirname(__FILE__)}/configuration.tpl", encoding: "utf-8")
          #end
        end

        def load_and_execute_manifest
          manifest = Manifest.new(self, File.realpath(File.expand_path(opts[:working_directory])), @argv[0])
          if opts[:dev_dump_actions_and_exit]
            puts *manifest.actions.map(&:to_s)
            exit 0
          elsif opts[:simulation]
            manifest._simulate!
          else
            manifest._execute!
          end
        end
      end
    end
  end
end
