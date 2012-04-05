
module Process
  def self.exists?(pid)
    begin
      kill(0,pid) 
      true
    rescue Errno::ESRCH
      false
    end
  end
end


class Lizard::Process < Lizard::Service
  module LogfileHandler
    def initialize(monitor,name)
      @monitor=monitor; @name=name
      @lizard=@monitor.lizard
    end
    def receive_data(data)
      data.split(/\n/).each do |l|
        @monitor.syslog @name,l
      end
    end
    def unbind 
      @monitor.stream_closed(@name)
    end
  end

  class Config < Lizard::Monitor::Config
    scalar :user
    scalar :start
    scalar :stop
  end

  def initialize (*args)
    @child_pid=-1
    super
  end

  attr_reader :child_pid

  def start_service
    @stdout = IO.pipe
    @stderr = IO.pipe
    EM.attach @stdout[0],LogfileHandler,self,:stdout
    EM.attach @stderr[0],LogfileHandler,self,:stderr
    @child_pid=Kernel.fork do
      @stdout[0].close
      @stderr[0].close
      $stdin.reopen("/dev/null","r")
      $stdout.reopen(@stdout[1])
      $stderr.reopen(@stderr[1])
      Kernel.exec(@config[:start])
    end
    syslog :stderr, "started #{@child_pid} with #{@config[:start]}"
    @stdout[1].close
    @stderr[1].close    
  end
  def stop_service
    syslog :stderr, "stopping #{@child_pid} by command"
    if self[:stop].first then
      # XXX should take blocks here as well
      warn "explicit stop not yet implemented : #{self[:stop].inspect}"
      return false;
    end
    if @child_pid>0 then Process.kill(15,@child_pid) end
  end

  def child_exited(pid)
    syslog :stderr, "#{@child_pid} exited (or detached?)"
    @child_pid=-1
    # as long as the service is enabled, try to bring it back up
    # XXX there may be a case for making this configurable, e.g.
    # poll :event=>:exit, count: 5 do |r| 
    #   # called each time a child dies
    #   r << Time.now  
    #   if r[0]< Time.now-5 then restart 
    #   else notify "disabled due to too many respawns", r
    #   end
    # end
    @config[:enabled] and start_service
  end

  def stream_closed(name)
    # this is for information only: a child may close its streams
    # and continue to run
    syslog :stderr, "#{@child_pid} #{name} stream was closed"
  end

  def test_pidfile
    # there are too many possibilities around pid files to be
    # terribly smart about it.  In particular, there are
    # combinations that make autorestart dicey

    # * pidfile exists, has not changed, process exists =>  ok
    # * pidfile exists, has changed
    #    process may have rewritten it
    #    or may have been restarted outside our control
    #    correct recovery action involves human decision
    # * pidfile exists, process doesn't =>  died unexpectedly
    # * pidfile nonexists, existed previously => probably dead
    # * pidfile nonexists, never has => may be startup?
    # * pidfile exists but process has died anyway and pid numbers looped
    #   => hopefully this will happen rarely and be picked up by
    #      a status check
    
    # we should do a proper status check in all situations where we
    # think the process has died so that we can convert a 'died' to
    # an 'unknown' if it miraculously is somehow still functioning anyway.
    # Then we can do a restart iff process is dead *and* not responding

    # we are going to assume (& take steps to assure) no background
    # processes running when we start.

  end
  
  def tag
    @name+"["+@child_pid.to_s+"]"
  end
  
end
