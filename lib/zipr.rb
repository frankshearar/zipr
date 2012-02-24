def sexp_loaded
  begin
    require 'sexp'
    true
  rescue LoadError
    # No sexp gem loaded. Oh well.
    false
  end
end
