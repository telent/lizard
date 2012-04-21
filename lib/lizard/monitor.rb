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
    def alert(name,proc=nil,&blk)
      @alerts||=[]
      @alerts << {name=>(if block_given? then blk else proc end) }
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

  def init_alerts(clss=self.class)
    @alerts ||= Hash.new {|h,k| h[k]=[] }
    v=clss.instance_variable_get(:@alerts) 
    v and v.each do |a|
      k,v=a.first
      @alerts[k] << v
    end
    if (sup=clss.superclass) 
      init_alerts sup
    end    
  end
  
  def alert(name,message)
    @alerts[name].map{|a| a.call(message) }
  end

  def initialize
    init_listeners
    init_alerts
  end

  def notify event
    @listeners[event].each do |l|
      l.call
    end
  end

end
