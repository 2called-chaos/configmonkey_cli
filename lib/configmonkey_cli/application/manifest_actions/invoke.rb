module ConfigmonkeyCli
  class Application
    module ManifestAction
      class Invoke < Base
        def init command = nil, opts = {}, &command_builder
          if command_builder
            command = "#{command}" # reference copy
            command = command_builder.call(command, opts)
          end
          @args = [command]
          @opts = opts.reverse_merge(chomp: true, echo: true, fail: true)
        end

        def simulate
          status :invoke, :yellow, @args[0]
        end

        def destructive
          status :invoke, :yellow, @args[0]
          code, res = exec(@args[0], @opts[:chomp])

          if opts[:echo]
            lines = res.split("\n")
            if code.exitstatus.zero?
              say padded("#{c "[OK]", :green} #{lines[0]}", :black)
              lines[1..-1].each{|l| say padded("     #{l}") } if lines.length > 1
            else
              say padded("[#{code.exitstatus}] #{lines[0]}", :red)
              lines[1..-1].each{|l| say padded("     #{l}") } if lines.length > 1
              raise "Invoked process exited with status #{code.exitstatus}: #{res}" if opts[:fail]
            end
          end
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
