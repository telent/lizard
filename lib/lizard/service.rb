class Lizard::Service < Lizard::Monitor
  def status
    # XXX run checks
    :run
  end
  
  def as_json
    {status: self.status, target_status: @target_status, pid: @child_pid  }.
      merge(super)
  end

  def target_status (s)
    [:run, :stop].include?(s) or raise "Invalid status #{s} requested"
    if s==@target_status then
      return  # nothing to do
    end
    @target_status=s
    make_it_so
  end
  def make_it_so
    if [:starting,:stopping].include?(self.status) then
      return
    end
    warn [:making,self.status,@target_status]
    if EM.reactor_running?
      # XXX set up timeout for this transition
      case @target_status 
      when :run then self.start_service
      when :stop then self.stop_service
      end
    end
  end
end
