require 'lizard/monitor'
require 'lizard/monitor/process'

describe Lizard::Monitor::Process do
  it "#start starts" do
    started=false
    m=Class.new(Lizard::Monitor::Process) do
      start do 
        started=true
      end
      stop do
      started=false
      end
    end.new
    m.start
    assert started
  end
  it "starts when :enable event received" do
    started=false
    m=Class.new(Lizard::Monitor::Process) do
      start do 
        started=true
      end
      stop do
        started=false
      end
    end
    m2=Class.new(m).new
    m2.notify :enable
    assert started
  end
end
