require 'pp' 
require 'lizard/filtered_stream'

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
    def stream(name, under_stream, &blk)
      @streams||=[]
      @streams << {name => Lizard::FilteredStream.new(under_stream,blk)}
    end
  end

  
  # Should this service be monitored?  truthy or falsey
  attr_reader :enable

  # Attribute denotes whether it is actually up, or is flakey, or is
  # down, or has unknown status.  Values TBD
  attr_reader :health

  attr_reader :listeners
  attr_reader :collection
  attr_reader :stream

  def init_thing(symbol,initial,clss=self.class,&blk)
    v=clss.instance_variable_get(symbol) 
    v and v.each do |a|
      k,v=a.first
      blk.call(k,v)
    end
    if (sup=clss.superclass) 
      init_thing symbol,initial,sup,&blk
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

    init_thing(:@clisteners, @listeners=Hash.new {|h,k| h[k]=[] }) do |k,v|
      @listeners[k] << v
    end
    init_thing(:@alerts, @alerts=Hash.new {|h,k| h[k]=[] }) do |k,v|
      @alerts[k] << v
    end
    init_thing(:@timers, nil) do |k,v|
      v1=Proc.new do
        self.instance_eval &v
      end
      (@periodic_timer || 
       Kernel.const_get("EventMachine").const_get("PeriodicTimer")).new(k, v1)
    end
    init_thing(:@collections, @collection = Hash.new {|h,k| h[k]=[]}) do |k,v|
      # subclasses override superclass
      @collection[k] ||= v
    end
    init_thing(:@streams, @stream={}) do |k,v|
      # subclasses override superclass
      @stream[k] ||= v
    end
  
    # with anonymous classes it sometimes gets hard to guess whether
    # "warn foo" is showing you a class or an instance.  This ivar
    # exists solely to help debugging
    @instance=true 
  end

  def notify event
    @listeners[event].each do |l|
      instance_eval &l
    end
  end

end
