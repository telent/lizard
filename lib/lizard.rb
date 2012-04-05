# # Lizard
#


require 'eventmachine'
require 'json'
require 'socket' # for Socket.gethostname

require 'lizard/signal_handler'
require 'lizard/command_handler'
require 'lizard/syslog'

class Lizard
  # pathname for unix-domain control socket 
  attr_accessor :command_socket
  # hostname:port of the syslog server that we should send all messages
  # to
  attr_accessor :syslog_server
  # how to connect to the mail server.  Accepts a hash of options which
  # are passed through to EventMachine::Protocols::SmtpClient constructor
  attr_accessor :mail
  # default options for various notification modules (see classes in
  # Lizard::Notifications namespace)
  attr_accessor :notifications
  
  # any accessor can be passed as a keyword argument to #new
  def initialize(attr={})
    @monitors={}
    @notifications={}
    {
      command_socket: "/tmp/lizard.sock",
      syslog_server: "localhost:514"
    }.merge(attr).each{|k,v| 
      s="#{k}=".to_sym; if self.respond_to?(s) then self.send(s,v) end
    }
  end

  # send to syslog: utility method used by monitors
  def syslog(*args)
    @syslog_socket.send_message *args
  end

  def hostname
    @hostname||=Socket.gethostname
  end

  # # Add a monitor to the system
  # Accepts a block argument to configure
  # monitor: refer to Lizard::Monitor and subclasses for valid options 
  def add clss,name,&blk
    unless clss.is_a?(Lizard::Monitor) then
      clss=Lizard.const_get(clss.to_s.capitalize)
    end
    mon=clss.new name,&blk
    @monitors[name]=mon
    mon.lizard=self
    mon
  end

  def all
    @monitors
  end
  def reset
    @monitors={}
  end
  def find_monitor_by_pid pid
    @monitors.values.find {|l| l.respond_to?(:child_pid) && (l.child_pid==pid) }
  end
  def find_monitor_by_name name
    @monitors[name]
  end

  # Start the world
  def start
    EM.run do
      @signal_pipe=IO.pipe
      Signal.trap("CHLD") do 
        @signal_pipe[1].write(Signal.list["CHLD"].chr)
      end
      EM.attach(@signal_pipe[0],SignalHandler,self)
      EM.start_unix_domain_server self.command_socket,CommandHandler,self
      host,port=@syslog_server.split(/:/)
      @syslog_socket=EM.open_datagram_socket host,0,Lizard::Syslog,host,port
      @monitors.values.each do |l| l.sync_with_config end
    end   
  end

  # Stop the world, get off.
  def stop
    @monitors.each do |l| l.config[:enable]=false; l.sync_with_config end
    if @monitors.find {|m| m.status }  then
      # wait for stop
      warn "waiting for services to stop"
      EM.add_timer 1, proc { self.stop }
      return

    end
    EM.stop
    if f=@signal_pipe then f[0].close;  f[1].close ; end
    Signal.trap("CHLD",'DEFAULT')
    @signal_pipe=nil
  end

end

require_relative './lizard/monitor'
require_relative './lizard/notification/mail'
require_relative './lizard/service'
require_relative './lizard/process'
require_relative './lizard/filesystem'

