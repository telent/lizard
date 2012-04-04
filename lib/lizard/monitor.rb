require 'ostruct'

class Lizard::Monitor
  class Poll < OpenStruct; end
  attr_reader :name,:check
  attr_accessor :lizard
  
  def as_json
    @attributes
  end

  def initialize name,&blk
    @name=name
    @log={}
    @polls=[]
    @notifications=[]
    @attributes=Hash.new {|h,k| h[k]=[] }
    # implicit self, because users are expected to be dsl-use-heavy and 
    # ruby-light
    # http://blog.grayproductions.net/articles/dsl_block_styles
    instance_eval &blk
  end
  def []=(k,v)
    @attributes[k] << v
  end
  def [](k)
    @attributes[k] 
  end
  def log params
    @log=@log.merge(params)
  end
  def notification n
    @notifications << n
  end
  def tag
    @name
  end
  def syslog(stream,message)
    a=@log[stream]
    @lizard.syslog a[:facility],a[:priority],message,self.tag
  end
  def poll(args,&blk)
    @polls << Poll.new(args.merge({proc: blk}))
  end
  class FixedLengthArray < Array
    def initialize(size)
      super(size)
      @bound=-size-1
    end
    def <<(val)
      super(val)
      self[0..@bound]=[]
      self
    end
    def average
      c=self.compact.count
      if c> 0 then
        self.compact.reduce(:+)/c
      else
        0
      end
    end
  end
  def start_service
    # call EM.add_periodic_timer for each poll, according to that poll's
    # interval. 
    monitor=self
    @polls.each do |poll|
      poll.results=FixedLengthArray.new(poll.keep)
      poll.timer=EM.add_periodic_timer(poll.interval) {
        # this block should be evaluated in the context of some object that
        # has #notify and #restart methods
        self.instance_eval do
          poll.proc.call(poll.results)
        end
      }
    end
  end
  def stop_service
    @polls.each do |poll|
      poll.timer.cancel
    end
  end

  def restart_service
    self.stop_service and self.start_service
  end

  def notify(*message)
    @notifications.each do |n|
      method,defaults=Array(n).first
      c=Lizard::Notification.const_get(method.to_s.capitalize)
      defaults=(@lizard.notifications[method] || {}).merge(defaults)
      o=c.new @lizard,self,defaults, message
      o.send!
    end
  end

end
