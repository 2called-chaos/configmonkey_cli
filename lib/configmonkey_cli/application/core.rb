module ConfigmonkeyCli
  class Application
    module Core
      # ===================
      # = Signal trapping =
      # ===================
      def trap_signals
        debug "Trapping INT signal..."
        $interruptable_threads = []
        Signal.trap("INT") do
          $cm_runtime_exiting = true
          $interruptable_threads.each{|thr| thr.raise(Interrupt) if thr.alive? }
          Kernel.puts "Interrupting..."
        end
        # Signal.trap("TERM") do
        #   $cm_runtime_exiting = true
        #   Kernel.puts "Terminating..."
        # end
      end

      def release_signals
        debug "Releasing INT signal..."
        Signal.trap("INT", "DEFAULT")
        # Signal.trap("TERM", "DEFAULT")
      end

      def haltpoint thr = Thread.current
        thr.raise Interrupt if $cm_runtime_exiting
      end

      def interruptable &block
        Thread.new do
          begin
            thr = Thread.current
            $interruptable_threads << Thread.current
            thr[:return_value] = block.call(thr)
          ensure
            $interruptable_threads.delete(Thread.current)
          end
        end.join[:return_value]
      end


      # ==========
      # = Events =
      # ==========
      def hook *which, &hook_block
        which.each do |w|
          @hooks[w.to_sym] ||= []
          @hooks[w.to_sym] << hook_block
        end
      end

      def fire which, *args
        return if @disable_event_firing
        sync { debug "[Event] Firing #{which} (#{@hooks[which].try(:length) || 0} handlers) #{args.map(&:class)}", 99 }
        @hooks[which] && @hooks[which].each{|h| h.call(*args) }
      end


      # ==========
      # = Logger =
      # ==========
      def logger_filename
        "#{cm_cfg_path}/logs/configmonkey.log"
      end

      def logger
        sync do
          @logger ||= begin
            FileUtils.mkdir_p(File.dirname(@opts[:logfile]))
            Logger.new(@opts[:logfile], 10, 1024000)
          end
        end
      end
    end
  end
end
