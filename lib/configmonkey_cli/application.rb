module ConfigmonkeyCli
  class Application
    attr_reader :opts, :connections, :hooks
    include Helper
    include OutputHelper
    include Colorize
    include Core
    include Dispatch
    include Configuration::AppHelper

    # =========
    # = Setup =
    # =========
    def self.dispatch *a
      new(*a) do |app|
        app.load_appconfig
        app.parse_params
        begin
          app.dispatch
          app.haltpoint
        rescue Interrupt
          app.abort("Interrupted", 1)
        ensure
          app.fire(:cm_shutdown)
          app.debug "#{Thread.list.length} threads remain..."
        end
      end
    end

    def initialize env, argv
      @boot = Time.current
      @env, @argv = env, argv
      @hooks = {}
      @connections = {}
      @monitor = Monitor.new
      @opts = {
        working_directory: Dir.pwd, # -i flag
        target_directory: "/",      # -o flag
        hostname: `hostname`.chomp, # -f flag
        default_accept: false,      # -a flag
        default_yes: false,         # -y flag
        dispatch: :index,           # (internal) action to dispatch
        simulation: false,          # -n flag
        check_for_updates: true,    # -z flag
        colorize: true,             # -m flag
        debug: false,               # -d flag
        # silent: false,              # -s flag
        # quiet: false,               # -q flag
        stdout: STDOUT,             # (internal) STDOUT redirect
      }
      init_params
      yield(self)
    end

    def to_s
      "#<ConfigmonkeyCli::Application @boot=#{@boot} @opts=#{@opts} @running=#{@running}>"
    end

    def init_params
      @optparse = OptionParser.new do |opts|
        opts.banner = "Usage: configmonkey [options]"

        opts.separator(c "# Application options", :blue)
        opts.on("--generate-manifest", "Generates an example manifest in current directory") { @opts[:dispatch] = :generate_manifest }
        opts.on("-a", "--accept", "accept all defaults") { @opts[:default_accept] = true }
        opts.on("-f", "--fake-host HOST", "override hostname") {|s| @opts[:hostname] = s }
        opts.on("-i", "--in DIR", "operate from this source directory instead of pwd") {|s| @opts[:working_directory] = s }
        opts.on("-o", "--out DIR", "operate on this target directory instead of /") {|s| @opts[:target_directory] = s }
        opts.on("-l", "--log [file]", "Log changes to file, defaults to ~/.configmonkey/logs/configmonkey.log") {|s| @opts[:logfile] = s || logger_filename }
        opts.on("-n", "--dry-run", "Simulate changes only, does not perform destructive operations") { @opts[:simulation] = true }
        opts.on("-y", "--yes", "accept all prompts with yes") { @opts[:default_yes] = true }
        opts.on(      "--dev-dump-actions", "Dump actions and exit") { @opts[:dev_dump_actions_and_exit] = true }
        # opts.on("-q", "--quiet", "Only print errors") { @opts[:quiet] = true }

        opts.separator("\n" << c("# General options", :blue))
        opts.on("-d", "--debug [lvl=1]", Integer, "Enable debug output") {|l| @opts[:debug] = l || 1 }
        opts.on("-m", "--monochrome", "Don't colorize output") { @opts[:colorize] = false }
        opts.on("-h", "--help", "Shows this help") { @opts[:dispatch] = :help }
        opts.on("-v", "--version", "Shows version and other info") { @opts[:dispatch] = :info }
        opts.on("-z", "Do not check for updates on GitHub (with -v/--version)") { @opts[:check_for_updates] = false }
      end
    end

    def parse_params
      @optparse.parse!(@argv)
    rescue OptionParser::ParseError => e
      abort(e.message)
      dispatch(:help)
      exit 1
    end

    def sync &block
      @monitor.synchronize(&block)
    end

    def running?
      @running
    end
  end
end
