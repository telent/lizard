require 'lizard/monitor'

describe Lizard::Monitor do
  it "a subclass retains the setup done in its parent" do
    m=Class.new(Lizard::Monitor) do
      name "anguimorph"
    end
    m2=Class.new(m)
    assert_equal "anguimorph",m.new.name 
    assert_equal "anguimorph",m2.new.name 
  end
      
  describe "events" do
    it "#listen registers an event handler" do
      succeeded=nil
      m=Class.new(Lizard::Monitor) do
        listen :enable do
          succeeded=true
        end
      end.new
      assert_equal 1, m.listeners[:enable].length
      m.listeners[:enable].map(&:call)
      assert succeeded
    end
    it "handlers are inherited" do
      succeeded=nil
      m=Class.new(Lizard::Monitor) do
        listen :enable do
          succeeded=true
        end
      end
      m2=Class.new(m).new
      assert_equal 1, m2.listeners[:enable].length
      m2.listeners[:enable].map(&:call)
      assert succeeded
    end
  end
end

    
