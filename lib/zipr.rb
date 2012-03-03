def sexp_loaded
  begin
    require 'sexp'
    true
  rescue LoadError
    # No sexp gem loaded. Oh well.
    false
  end
end

require 'zipr/either'
require 'zipr/enumerable-extensions'
require 'zipr/functors'
require 'zipr/trampoline'
require 'zipr/unsupported-operation'
require 'zipr/zipper'
