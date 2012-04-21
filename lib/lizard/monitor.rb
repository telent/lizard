require 'pp' 
class Lizard; end

class Lizard::Monitor
  class << self
    def name(value)
      define_method :name do
        value
      end
    end
    def listen(event,&blk)
      @clisteners||=Hash.new {|h,k| h[k]=[] }
      @clisteners[event] << blk
    end
  end
  
  attr_reader :listeners
  def init_listeners(clss=self.class)
    @listeners ||= {}
    @listeners=@listeners.merge(clss.instance_variable_get(:@clisteners) ||{})
    if (sup=clss.superclass) != Object
      init_listeners sup
    end    
  end

  def initialize
    init_listeners
  end

end
