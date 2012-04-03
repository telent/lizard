require 'eventmachine'
require 'json'

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
            warn "reaping #{kid}"
            if m=@lizard.find_monitor_by_pid(kid) then
              warn "found monitor #{m.name}"
              m.child_exited(kid)
            end
          end
        rescue Errno::ECHILD
          warn "No child processes"
          nil
        end
        warn "done"
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

  def initialize
    @monitors={}
  end
  def command_socket
    "/tmp/lizard.sock"
  end

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
  def start_watch
    EM.run do
      @signal_pipe=IO.pipe
      Signal.trap("CHLD") do 
        @signal_pipe[1].write(Signal.list["CHLD"].chr)
      end
      EM.attach(@signal_pipe[0],SignalHandler,self)
      EM.start_unix_domain_server self.command_socket,CommandHandler,self
      @monitors.values.each do |l| l.make_it_so end
    end   
  end
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
require_relative './lizard/service'
require_relative './lizard/process'
require_relative './lizard/filesystem'

