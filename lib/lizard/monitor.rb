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
    def every(interval,&blk)
      @timers ||=[]
      @timers << {interval=> blk}
    end
    def alert(name,proc=nil,&blk)
      @alerts||=[]
      @alerts << {name=>(if block_given? then blk else proc end) }
    end
    def collect name, options
      clss=options.delete(:class)
      @collections||=[]
      @collections << {name => clss.new(options) }
    end
  end

  
  # Should this service be monitored?  truthy or falsey
  attr_reader :enable

  # Attribute denotes whether it is actually up, or is flakey, or is
  # down, or has unknown status.  Values TBD
  attr_reader :health

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

  def init_timers(clss=self.class)
    v=clss.instance_variable_get(:@timers) 
    v and v.each do |a|
      k,v=a.first
      v1=Proc.new do
        self.instance_eval &v
      end
      (@periodic_timer || 
       Kernel.const_get("EventMachine").const_get("PeriodicTimer")).new(k, v1)
    end
    if (sup=clss.superclass) 
      init_timers sup
    end    
  end

  attr_reader :collection
  def init_collections(clss=self.class)
    @collection ||= Hash.new {|h,k| h[k]=[] }
    v=clss.instance_variable_get(:@collections) 
    v and v.each do |a|
      k,v=a.first
      # subclasses override superclass
      @collection[k] ||= v
    end
    if (sup=clss.superclass) 
      init_collections sup
    end    
  end
  
  def alert(name,message)
    @alerts[name].map{|a| a.call(message) }
  end

  attr_reader :periodic_timer

  def initialize(attributes={})
    # perhaps this would be clearer removed and replaced with use of 
    # a mocking library
    a=attributes[:periodic_timer] and @periodic_timer=a

    init_listeners
    init_alerts
    init_collections
    init_timers
    # with anonymous classes it sometimes gets hard to guess whether
    # "warn foo" is showing you a class or an instance.  This ivar
    # exists solely to help debugging
    @instance=true 
  end

  def notify event
    @listeners[event].each do |l|
      #  needs to be instance_eval or something to ensure
      # "this" is the instance
      instance_eval &l
    end
  end

end
