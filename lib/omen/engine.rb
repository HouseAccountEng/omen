module Omen
  # Teaches Rails where this gem's models live, and prefixes their tables with `omen_`.
  class Engine < ::Rails::Engine
    isolate_namespace Omen
  end
end
