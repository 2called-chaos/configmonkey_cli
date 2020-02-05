module ConfigmonkeyCli
  class Application
    module ManifestAction
      class Custom < Base
        def init label = nil, &block
          @label = label
          block.call(Proxy.new(self)) if block
        end

        def inspect
          @label ? super.gsub("Custom @args", "Custom @label=#{@label} @args") : super
        end

        def prepare
          status :proc, :yellow, (@label || "unlabeled custom block"), :blue
        end

        def simulate
          @args.each do |scope, block|
            block.call if scope == :always || scope == :simulate
          end
        end

        def destructive
          @args.each do |scope, block|
            block.call if scope == :always || scope == :destructive
          end
        end

        class Proxy
          attr_reader :action

          def initialize action
            @action = action
          end

          def always &block
            @action.args << [:always, block]
          end

          def simulate &block
            @action.args << [:simulate, block]
          end

          def destructive &block
            @action.args << [:destructive, block]
          end
        end
      end
    end
  end
end
