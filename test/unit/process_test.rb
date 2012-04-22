require 'lizard/monitor'
require 'lizard/monitor/process'

describe Lizard::Monitor::Process do
  before do
    @started=false
    strt= Proc.new { @started=true }
    stp=Proc.new { @started=false }
    @m=Class.new(Lizard::Monitor::Process) do
      start do 
        strt.call
      end
      stop do
        stp.call
      end
    end.new
  end
  it "#start starts" do
    @m.start
    assert @started
  end
  it "starts when :enable event received" do
    @m.notify :enable
    assert @started
  end
  it "stops when :disable received" do
    @m.notify :enable
    assert @started
    @m.notify :disable
    refute @started
  end
  it "restarts when sent :process_died event"
  it "doesn't restart if health: fail"
  it "sets health: warn if child dies more than three times in a minute"
  it "sets health: fail if child dies more than six times in a minute"
  it "resets health status on receiving external :reset event"
end
