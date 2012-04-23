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

  describe "attributes" do
    [:enable,:health].each do |a|
      it "has #{a} attribute" do
        assert Lizard::Monitor.new.respond_to?(a) 
      end
    end
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

  describe "timed code" do
    it "::every defines a code block which is called periodically" do
      coll=[]
      class FakePeriodicTimer 
        def initialize(interval,code)
          @@f=code; @@int=interval
        end
      end
      m=Class.new(Lizard::Monitor) do
        every 10 do
          # check that this code is run with the correct self
          coll << self
        end
      end.new(:periodic_timer=>FakePeriodicTimer)
      assert_equal 10,FakePeriodicTimer.send(:class_variable_get,:@@int)
      FakePeriodicTimer.send(:class_variable_get,:@@f).call
      assert_equal m,coll[0]
    end
  end    

  describe "alerts" do
    it "collects alerts" do
      out=[]
      m=Class.new(Lizard::Monitor) do
        alert :dan, Proc.new {|msg| out << [:dan,msg] }
        alert :root, Proc.new {|msg| out << [:root,msg] }
      end.new
      m.alert :dan,"message 1"
      assert_equal out,[[:dan,"message 1"]]
      m.alert :root,"message 2"
      assert_equal out,[[:dan,"message 1"],
                        [:root,"message 2"]]
    end
    it "alert also accepts a block" do
      out=[]
      m=Class.new(Lizard::Monitor) do
        alert :dan do |msg|
          out << [:dan,msg] 
        end
      end.new
      m.alert :dan,"message 1"
      assert_equal out,[[:dan,"message 1"]]
    end
  end

  describe "collect" do
    it "::collect creates a time-series collection (e.g. for metrics)" do
      m=Class.new(Lizard::Monitor) do
        v=Class.new(Array) do
          def initialize(hash)
            super()
          end
        end
        collect :fiftyhz, :class=> v
        listen :tick do
          @i||=0
          p = Math::sin(@i * Math::PI/36)
          collection[:fiftyhz] << p
          @i+=1
        end
      end.new
      10.times do |i| m.notify :tick end
      assert_equal 10,m.collection[:fiftyhz].length
      assert_in_delta 3.70773, m.collection[:fiftyhz].reduce(:+)
    end
  end
end

    
