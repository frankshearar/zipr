require 'rantly/property'

class Rantly
  def any
    choose(integer, string, boolean)
  end
end
