module ConfigmonkeyCli
  class Application
    attr_reader :opts, :connections, :hooks, :env, :argv
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
        rescue SystemExit
          app.abort("Aborted", 2)
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
        diff_tool: nil,             # -D flag
        merge_tool: nil,            # -M flag
        bell: false,                 # -b flag
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

    def find_diff_tool
      [
        opts[:diff_tool],
        ENV["CM_DIFF"],
        ENV["THOR_DIFF"],
        ENV["RAILS_DIFF"],
        "colordiff",
        "git diff --no-index",
        "vim -d",
        "diff -u",
      ].compact.each do |cmd|
        if hit = `which #{cmd.split(" ").first}`.chomp.presence
          debug "§diff-using:(#{hit})#{cmd}"
          return cmd
        else
          debug "§diff-not-found:#{cmd}", 105
        end
      end
    end

    def find_merge_tool
      [
        opts[:merge_tool],
        ENV["CM_MERGE"],
        ENV["THOR_MERGE"],
        (`git config merge.tool`.chomp rescue nil),
        "vim -d",
        "diff -u",
      ].compact.each do |cmd|
        if hit = `which #{cmd.split(" ").first}`.chomp.presence
          debug "§merge-using:(#{hit})#{cmd}"
          return cmd
        else
          debug "§merge-not-found:#{cmd}", 105
        end
      end
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
        opts.on("-b", "--bell", "dont ring a bell when asked") { @opts[:bell] = true }
        opts.on("-D", "--diff", "change default diff tool") {|s| @opts[:diff_tool] = s }
        opts.on("-f", "--fake-host HOST", "override hostname") {|s| @opts[:hostname] = s }
        opts.on("-i", "--in DIR", "operate from this source directory instead of pwd") {|s| @opts[:working_directory] = s }
        opts.on("-o", "--out DIR", "operate on this target directory instead of /") {|s| @opts[:target_directory] = s }
        opts.on("-l", "--log [file]", "Log changes to file, defaults to ~/.configmonkey/logs/configmonkey.log") {|s| @opts[:logfile] = s || logger_filename }
        opts.on("-M", "--merge", "change default merge tool") {|s| @opts[:merge_tool] = s }
        opts.on("-n", "--dry-run", "Simulate changes only, does not perform destructive operations") { @opts[:simulation] = true }
        opts.on("-y", "--yes", "accept all prompts with yes") { @opts[:default_yes] = true }
        opts.on(      "--dev-dump-actions", "Dump actions and exit") { @opts[:dev_dump_actions] = true }
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

      # resolve diff/merge tool
      @opts[:diff_tool] = find_diff_tool
      @opts[:merge_tool] = find_merge_tool

      # thor bell
      ENV['THOR_ASK_BELL'] = "true" if @opts[:bell]

      # thor no-colors
      ENV['NO_COLOR'] = "true" if !@opts[:colorize]

      # thor diff-tool
      ENV['THOR_DIFF'] = opts[:diff_tool] if @opts[:diff_tool]
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
