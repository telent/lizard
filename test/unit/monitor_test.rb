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
    it "inherited and direct handlers both work" do
      succeeded=0
      m=Class.new(Lizard::Monitor) do
        listen :enable do
          succeeded+=1
        end
      end
      m2=Class.new(m) do
        listen :enable do
          succeeded+=1
        end
      end.new
      assert_equal 2, m2.listeners[:enable].length
      m2.listeners[:enable].map(&:call)
      assert_equal 2, succeeded
    end
    it "#notify invokes the handlers" do
      called=[]
      m=Class.new(Lizard::Monitor) do
        listen :enable do
          called << :m
        end
        listen :enable do
          called << :m
        end
      end
      m2=Class.new(m) do
        listen :enable do
          called << :m2
        end
      end
      m2.new.notify :enable
      assert_equal called.sort, [:m,:m,:m2].sort
    end
  end
end

    
