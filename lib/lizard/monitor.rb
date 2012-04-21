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
      @clisteners||=[]
      @clisteners << {event => blk}
    end
  end
  
  attr_reader :listeners
  def init_listeners(clss=self.class)
    @listeners ||= Hash.new {|h,k| h[k]=[] }
    v=clss.instance_variable_get(:@clisteners) 
    v and v.each do |a|
      k,v=a.first
      @listeners[k] << v
    end
    if (sup=clss.superclass) 
      init_listeners sup
    end    
  end

  def initialize
    init_listeners
  end

end
