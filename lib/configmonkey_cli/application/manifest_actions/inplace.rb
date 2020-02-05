module ConfigmonkeyCli
  class Application
    module ManifestAction
      class Inplace < Base
        def init label = nil, &block
          @label = label
          @block = block
        end

        def inspect
          @label ? super.gsub("Custom @args", "Custom @label=#{@label} @args") : super
        end

        def prepare
          status :proc, :yellow, (@label || "unlabeled inplace block"), :blue
        end

        def simulate
          destructive
        end

        def destructive
          @block.call
        end
      end
    end
  end
end
