module ConfigmonkeyCli
  class Application
    class Manifest
      MANIFEST_ACTIONS = [:chmod, :copy, :custom, :inplace, :invoke, :link, :mkdir, :rsync, :remove, :rtfm, :sync_links, :template]

      class ExecutionError < ::RuntimeError
        def initialize file, original_exception
          @file = file
          @original_exception = original_exception
        end

        def message
          ln = ex.message[@file] && ex.message.match(/#{Regexp.escape(@file)}:([0-9]+)/)&.to_a&.second
          ln ||= backtrace.reverse.detect{|l| l[@file] }&.split(":")&.second
          "#{@file}#{":#{ln}" if ln}\n --- #{ex.message.gsub(@file, "<manifest>")}"
        end

        def backtrace
          ex.backtrace
        end

        def original_exception
          @original_exception
        end
        alias_method :ex, :original_exception
      end

      class Invalid < ExecutionError
      end

      class ThorHelperApp < Thor
        include Thor::Actions
      end

      attr_reader :app, :directory, :manifest_file, :actions, :thor, :padding

      def initialize app, directory, manifest_file = "manifest.rb"
        @app = app
        @directory = directory
        init_thor!
        @padding = 26
        @manifest_file = File.join(directory, manifest_file || "manifest.rb")
        @actions = []
        @host_constraint = []
        @target_directory = app.opts[:target_directory]
        all do
          begin
            eval File.read(@manifest_file, encoding: "utf-8"), binding, @manifest_file
          rescue Exception => ex
            raise Invalid.new(@manifest_file, ex)
          end
        end
        app.debug "§constraint-final:#{@host_constraint}", 120
      end

      def checksum *args
        opts = args.extract_options!
        if opts[:soft]
          @_checksum_soft ||= begin
            to_c = args.map(&:to_s)
            to_c.unshift @manifest_file
            Digest::SHA1.hexdigest(to_c.to_s)
          end
        else
          @_checksum_hard ||= begin
            to_c = args.map(&:to_s)
            to_c.unshift Digest::SHA1.file(@manifest_file)
            Digest::SHA1.hexdigest(to_c.to_s)
          end
        end
      end

      def to_s
        "#<…::Manifest @directory=#{@directory} @actions=#{@actions.length}>"
      end

      def init_thor!
        ThorHelperApp.source_root(directory)
        @thor = ThorHelperApp.new([], { pretend: app.opts[:simulation] })

        @thor.shell.class_eval do
          def say_status(status, message, log_status = true)
            return if quiet? || log_status == false
            spaces = "  " * (padding + 1)
            color  = log_status.is_a?(Symbol) ? log_status : :green

            status = status.to_s.rjust(12)
            status = set_color status, color, true if color

            if($cm_current_action_name)
              cm_action = $cm_current_action_name.to_s.rjust(12)
              cm_action = set_color cm_action, $cm_current_action_color, true if $cm_current_action_color
            end

            buffer = "#{cm_action}#{status}#{spaces}#{message}"
            buffer = "#{buffer}\n" unless buffer.end_with?("\n")

            stdout.print(buffer)
            stdout.flush
          end

          def ask q, *args, &block
            ConfigmonkeyCli::Application.instance_method(:interruptable).bind(Object.new).call do
              begin
                q = "\a" << q if ENV["THOR_ASK_BELL"]
                super(q, *args, &block)
              rescue Interrupt => ex
                Thread.main.raise(ex)
              end
            end
          end
        end
      end

      def _dump!
        @actions.each do |constraint, action, instance|
          begin
            $cm_current_action_name = action
            $cm_current_action_color = :magenta
            thor.say_status :dump, instance, :black
          ensure
            $cm_current_action_name = $cm_current_action_color = nil
          end
        end
      end

      def _simulate!
        _execute!(true)
      end

      def _execute! simulate = false
        set_destination_root(@target_directory, false)

        if simulate
          thor.say_status :info, thor.set_color("---> !!! SIMULATION ONLY !!! <---", :green), :cyan
        else
          thor.say_status :info, thor.set_color("---> !!! HOT HOT HOT !!! <---", :red), :cyan
        end
        thor.say_status :info, (thor.set_color("Source Dir: ", :magenta) << thor.set_color(directory, :blue)), :cyan
        thor.say_status :info, (thor.set_color(" Dest Root: ", :magenta) << thor.set_color(thor.destination_root, :blue)), :cyan
        @actions.each_with_index do |(constraint, action, instance), index|
          begin
            $cm_current_action_index = index
            $cm_current_action_name = action
            $cm_current_action_color = :magenta
            instance.prepare
            simulate ? instance.simulate : instance.destructive
          ensure
            $cm_current_action_index = $cm_current_action_name = $cm_current_action_color = nil
            app.haltpoint
          end
        end
      rescue Interrupt, SystemExit
        raise
      rescue Exception => ex
        raise(ExecutionError.new(@manifest_file, ex))
      end

      def _with_constraint *constraint
        if @host_constraint.last == constraint
          return yield if block_given?
        end
        if _breached_constraint?(constraint)
          app.debug "§constraint-ignore:#{constraint}", 119
          return
        end
        begin
          @host_constraint << constraint
          app.debug "§constraint-push:#{constraint}", 120
          app.debug "§constraint-now:#{@host_constraint}", 121
          yield if block_given?
        ensure
          app.debug "§constraint-pop:#{@host_constraint.pop}", 120
          app.debug "§constraint-now:#{@host_constraint}", 121
        end
      end

      def _breached_constraint? constraint = nil
        in_constraint = catch :return_value do
          [@host_constraint, [constraint || []]].each do |list|
            list.each do |act, args|
              case act
              when :any then next
              when :on
                args.include?(app.opts[:hostname]) ? next : throw(:return_value, false)
              when :not_on
                args.include?(app.opts[:hostname]) ? throw(:return_value, false) : next
              end
            end
          end
          true
        end
        !in_constraint
      end

      def push_action *args
        if $cm_current_action_index
          @actions.insert $cm_current_action_index + 1, [@host_constraint.dup] + args
        else
          @actions.push [@host_constraint.dup] + args
        end
      end

      def set_destination_root drpath, from_manifest = true
        if from_manifest
          base = File.realpath(File.expand_path(@directory))
          xpath = File.expand_path(drpath[0] == "/" ? drpath : File.join(base, drpath))
          if app.opts[:target_directory] != "/"
            thor.say_status :warn, (thor.set_color(" Dest Root: ", :magenta) << thor.set_color(xpath, :blue) << thor.set_color(" IGNORED! -o parameter will take precedence", :red)), :red
          else
            @target_directory = xpath
          end
        else
          thor.destination_root = File.realpath(File.expand_path(drpath))
        end
      end


      # =======
      # = DSL =
      # =======

      def padded str, *color
        "".rjust(padding, " ") << (color.any? ? c(str.to_s, *color) : str.to_s)
      end

      def c str, *color
        thor.set_color(str, *color)
      end

      def say str, *color
        thor.say((color.any? ? c(str.to_s, *color) : str.to_s))
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

      # do block no matter the `hostname`
      def all &block
        _with_constraint(:any, &block)
      end

      # do block only if `hostname` is in *hosts
      def on *hosts, &block
        _with_constraint(:on, hosts.flatten.map(&:to_s), &block)
      end

      # do block except if `hostname` is in *hosts
      def not_on *hosts, &block
        _with_constraint(:not_on, hosts.flatten.map(&:to_s), &block)
      end

      MANIFEST_ACTIONS.each do |meth|
        define_method(meth) do |*args, &block|
          push_action(meth, "ConfigmonkeyCli::Application::ManifestAction::#{meth.to_s.camelize}".constantize.new(app, self, *args, &block))
          app.haltpoint
        end
      end

      def ask question, opts = {}
        if opts[:use_thread] != false
          return app.interruptable { ask(question, opts.merge(use_thread: false)) }
        end
        opts[:limited_to] = opts.delete(:choose) if opts[:choose]
        opts[:add_to_history] = true unless opts.key?(:add_to_history)
        color = opts.delete(:color)
        spaces = "".ljust(opts[:padding]) if opts[:padding]
        begin
          @thor.ask("#{spaces}#{question}", color, opts).presence
        rescue Interrupt
          app.haltpoint(Thread.main)
        end
      end

      def yes? question, opts = {}
        opts[:quit] = true unless opts.key?(:quit)
        opts[:default] = true unless opts.key?(:default)
        opts[:padding] = @padding unless opts.key?(:padding)
        return true if app.opts[:default_yes]
        return opts[:default] if app.opts[:default_accept]
        o = "#{opts[:default] ? :Yn : :yN}"
        o << "h" if opts[:help]
        o << "q" if opts[:quit]
        q = "#{question} [#{o}]"
        c = opts[:color].presence || (opts[:default] ? :red : :yellow)
        askopts = opts.slice(:padding, :limited_to, :choose, :add_to_history).merge(color: c, use_thread: false)
        if askopts[:padding] && askopts[:padding] > 10
          qq = thor.set_color(q, askopts[:color]) if askopts[:color]
          q = "#{thor.set_color("?", :red)}  #{qq || q}"
          askopts[:padding] -= 3
        end

        app.interruptable do
          catch :return_value do
            loop {
              x = (ask(q, askopts) || (opts[:default] ? :y : :n)).to_s.downcase.strip

              if ["y", "yes", "1", "t", "true"].include?(x)
                throw :return_value, true
              elsif ["n", "no", "0", "f", "false"].include?(x)
                throw :return_value, false
              elsif ["h", "help", "?"].include?(x)
                @thor.say_status :help, "#{opts[:help]}", :cyan
              elsif ["q", "quit", "exit"].include?(x)
                raise SystemExit
              else
                @thor.say_status :warn, "choose one of y|yes|1|t|true|n|no|0|f|false#{"|q|quit|exit" if opts[:quit]}#{"|?|h|help" if opts[:help]}", :red
              end
            }
          end
        end
      end

      def no? question, opts = {}
        !yes?(question, opts.merge(default: false))
      end
    end
  end
end
