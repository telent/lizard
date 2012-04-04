require 'eventmachine'
require 'json'
require 'socket' # for Socket.gethostname

class Lizard
  module SignalHandler
    def initialize(lizard)
      @lizard=lizard
      super
    end
    def receive_data data
      signal=data[0].ord
      case signal 
      when Signal.list["CHLD"] then
        begin
          while kid=::Process.waitpid(-1,::Process::WNOHANG )
            #warn "reaping #{kid}"
            if m=@lizard.find_monitor_by_pid(kid) then
              #warn "found monitor #{m.name}"
              m.child_exited(kid)
            end
          end
        rescue Errno::ECHILD
          warn "Received SIGCHLD unexpectedly"
          nil
        end
        #warn "done"
      end
    end
  end
  module CommandHandler
    def initialize(lizard)
      @lizard=lizard
      super
    end
    def receive_data data
      error=nil
      begin
        # {monitor: 'sagepay', target_status: 'run'}
        j=JSON.parse data
        if m=j["monitor"] then
          monitor=@lizard.find_monitor_by_name(m)
          if monitor 
            if s=j['target_status'] then
              monitor.target_status s.to_sym
            end
          else
            error="no such monitor #{m}"
          end
        end
        unless error then
          send_data (if monitor then monitor.as_json else @lizard.all.values.map(&:as_json) end).to_json
          return
        end
      rescue JSON::ParserError =>e
        error=e.inspect
      end
      send_data ({error: e.inspect}).to_json 
    end
  end
  module Syslog 
    def initialize(host,port)
      @host=host; @port=port
    end
    def send_message(facility,priority,content,tag="lizard")
      # per http://www.faqs.org/rfcs/rfc3164.html
      @hostname||=Socket.gethostname.split(".").first
      f=[:kernel,:user,:mail,:daemon,:auth,:syslog,
         :lpr,:news,:uucp,:cron,:authpriv,:ftp,
         12,13,14,15,
         :local0,:local1,:local2,:local3,
         :local4,:local5,:local6,:local7].index(facility)
      p=[:emerg,:alert,:crit,:err,
         :warning,:notice,:info,:debug].index(priority)
      raise "facility #{facility} unrecognized" unless f
      raise "priority #{priority} unrecognized" unless p
      timestamp=Time.now.strftime("%b %_m %H:%M:%S")
      payload=sprintf("<%d>",(f << 3)|p)+
        "#{timestamp} #{@hostname} #{tag}:#{content}"
      send_datagram payload[0..1023],@host,@port
    end
  end                 

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

  # Add a monitor to the system.  Accepts a block argument to configure
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
  def start_watch
    EM.run do
      @signal_pipe=IO.pipe
      Signal.trap("CHLD") do 
        @signal_pipe[1].write(Signal.list["CHLD"].chr)
      end
      EM.attach(@signal_pipe[0],SignalHandler,self)
      EM.start_unix_domain_server self.command_socket,CommandHandler,self
      host,port=@syslog_server.split(/:/)
      @syslog_socket=EM.open_datagram_socket host,0,Lizard::Syslog,host,port

      @monitors.values.each do |l| l.make_it_so end
    end   
  end

  # Stop the world, get off.
  def stop_watch
    @monitors.each do |l| l.target_status=:stop end
    if @monitors.find {|m| [:run,:stopping].include?(m.status) }  then
      # wait for stop
      warn "waiting for services to stop"
      EM.add_timer 1, proc { self.stop_watch }
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

