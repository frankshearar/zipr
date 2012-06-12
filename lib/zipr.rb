def sexp_loaded
  Kernel::const_defined?(:Sexp)
end

require 'zipr/either'
require 'zipr/enumerable-extensions'
require 'zipr/functors'
require 'zipr/trampoline'
require 'zipr/unsupported-operation'
require 'zipr/zipper'
