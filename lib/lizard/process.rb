
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

  def initialize (*args)
    @child_pid=-1
    super
  end

  [:user,:start,:stop,:pidfile].each do |meth|
    define_method meth do |v|
      @attributes[meth] = v
    end
  end
  attr_reader :child_pid
  def status
    p=@child_pid
    warn [:status,p]
    s=if p && (p>0) && ::Process.exists?(p) then
        :run 
      else
        :stop
      end
    if s==:run then
      super
    end
  end

  def start_service
    @status=:starting
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
      Kernel.exec(self[:start])
    end
    warn "started #{@child_pid}"
    @stdout[1].close
    @stderr[1].close    
    true
  end
  def stop_service
    warn [:l,self[:stop],@attributes]
    if self[:stop].first then
      # XXX should take blocks here as well
      warn "explicit stop not yet implemented : #{self[:stop].inspect}"
      return false;
    end
    if @child_pid>0 then Process.kill(15,@child_pid) end
  end

  def child_exited(pid)
    warn "child #{pid} exited (or detached?)"
    @child_pid=-1
    self.make_it_so
  end
  def stream_closed(name)
    warn "stream for #{name} was closed"
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
  
  def stop_watch
    #@stdout[0].close these are already closed?
    #@stderr[0].close
  end
end

    
