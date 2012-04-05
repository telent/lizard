require 'ostruct'
require 'lizard/config'
require 'pp'

class Lizard::Monitor
  class Poll < OpenStruct ;end
  class Config < Lizard::Config
    hash :log
    list :notification
    scalar :enable
    def poll args,&blk
      @values[:poll] ||=[]
      @values[:poll] << Poll.new({proc: blk}.merge(args))
    end
  end

  attr_reader :name
  attr_accessor :lizard
  
  def as_json
    @attributes
  end

  def initialize name,&blk
    @name=name
    @config=self.class.const_get("Config").new
    # implicit self, because users are expected to be dsl-use-heavy and 
    # ruby-light
    # http://blog.grayproductions.net/articles/dsl_block_styles
    @config.send(:instance_eval,&blk)
  end
  def tag
    @name
  end
  def syslog(stream,message)
    a=@config[:log][stream] or raise "no stream #{stream}"
    @lizard.syslog a[:facility],a[:priority],message,self.tag
  end
  class FixedLengthArray < Array
    # A subclass of Array which drops earlier elements when more are added.
    # One of these is passed as the argument to a #poll block, in which
    # it is used to accummulate history of previous polls so that we
    # can do hysteresis on values or tolerate intermittent errors
    def initialize(size)
      super(size)
      @bound=-size-1
    end
    # (Short Shameful Confession: this is presently the only method which
    # actually enforces the size limit)
    def <<(val)
      super(val)
      self[0..@bound]=[]
      self
    end
    # Take the average of the non-nil values in the array
    def average
      c=self.compact.count
      if c> 0 then
        self.compact.reduce(:+)/c
      else
        0
      end
    end
  end

  def enable!
    # call EM.add_periodic_timer for each poll, according to that poll's
    # interval. 
    monitor=self
    @config[:poll].each do |poll|
      poll.results=FixedLengthArray.new(poll.keep)
      poll.timer=EM.add_periodic_timer(poll.interval) {
        monitor.instance_exec(poll.results,&poll.proc)
      }
    end
    start_service
    @enabled=true
  end

  # Stop the monitor
  def disable!
    @enabled=false
    stop_service
    @config[:poll].each do |poll|
      poll.timer.cancel
    end
  end

  # subclasses may implement these if the service is something that
  # can be started/stopped under our control
  def start_service
  end
  def stop_service
  end

  def sync_with_config
    wanted=@config[:enable]
    if wanted != @enabled then
      if wanted then enable! else disable! end
    end
  end

  # #notify is called from #poll body clauses to send emails/texts/pages/
  # whatever form of notification is specified for this monitor by its
  # #notification clause(s)
  def notify(*message)
    @config[:notification].each do |n|
      method,defaults=Array(n).first
      c=Lizard::Notification.const_get(method.to_s.capitalize)
      defaults=(@lizard.notifications[method] || {}).merge(defaults)
      o=c.new @lizard,self,defaults, message
      o.send!
    end
  end
    
end
