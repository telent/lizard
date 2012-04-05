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
            false and warn "reaping #{kid}"
            if m=@lizard.find_monitor_by_pid(kid) then
              false and warn "found monitor #{m.name}"
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
end
