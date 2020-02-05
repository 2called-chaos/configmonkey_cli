module ConfigmonkeyCli
  class Application
    module ManifestAction
      class Rsync < Base
        def init hargs_and_opts = {}
          @args, @opts = args_and_opts(hargs_and_opts)
          @opts = @opts.reverse_merge({
            binary: "rsync",
            delete: true,
            delay: true,
            preview: false,
            flags: [],
          })
        end

        def prepare
          @source = @args[0]
          @destination = @args[1]
          status :synchronize, :green, "#{@source} => #{@destination}"
        end

        def simulate
          render_sync(do_sync(true))
        end

        def destructive
          if @opts[:preview] && !(app.opts[:default_yes] || app.opts[:default_accept])
            preview = do_sync(true)
            render_sync(preview)
            if preview.any?
              if manifest.yes?("Apply changes?", default: @opts[:preview] == true || [:y, :yes].include?(@opts[:preview].to_sym))
                render_sync do_sync
              end
            end
          else
            render_sync do_sync
          end
        end

        # ----------------------------------------------

        def str_flags force_dry = false
          ([].tap{|f|
            f << "--archive"
            f << "--whole-file" # better I guess?
            f << "--dry-run" if force_dry || app.opts[:simulation]
            f << "--itemize-changes" # for parsing and display
            f << "--delay-updates" if @opts[:delay]
            if @opts[:delete]
              f << (@opts[:delay] ? "--delete-#{@opts[:delay].is_a?(String) ? @opts[:delay] : "delay"}" : "--delete")
            end
          }.compact + @opts[:flags]).join(" ")
        end

        def rsync_command src, dst, force_dry = false
          [
            @opts[:binary],
            str_flags(force_dry),
            Shellwords.escape(File.join(manifest.directory, src)),
            Shellwords.escape(File.join(thor.destination_root, dst))
          ].join(" ")
        end

        def status_color_from_mode mode
          if mode[1] == "f"
            :white
          elsif mode == "*deleting"
            :red
          elsif mode[1] == "d"
            :blue
          else
            :white
          end
        end

        def status_color_for_mode mode
          if mode[0] == ">" || mode[0..1] == "cd"
            :green
          elsif mode == "*deleting"
            :red
          else
            :yellow
          end
        end

        def render_sync ary
          ary.each do |mode, file|
            status mode, status_color_for_mode(mode), file, status_color_from_mode(mode)
          end
        end

        def do_sync force_dry = false
          cmd = rsync_command(@source, @destination, force_dry)
          code, res = exec(cmd)
          raise "rsync exited with status #{code}: #{res}" unless code.exitstatus == 0
          res.split("\n").map{|l| l.split(" ", 2) }
        end

        def exec cmd, chomp = true
          app.debug "§invoking:#{cmd}"
          _stdin, _stdouterr, _thread = Open3.popen2e(cmd)
          _thread.join
          res = _stdouterr.read
          [_thread.value, chomp ? res.chomp : res]
        ensure
          _stdin.close rescue false
          _stdouterr.close rescue false
        end
      end
    end
  end
end
