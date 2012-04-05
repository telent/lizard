class Lizard::Service < Lizard::Monitor
  def as_json
    {status: self.status, target_status: @config[:target_status], pid: @child_pid  }.
      merge(super)
  end
end
