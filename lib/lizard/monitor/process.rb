class Lizard::Monitor::Process < Lizard::Monitor
  class << self
    def start(&blk)
      define_method :start do
        instance_eval &blk
      end
    end
    def stop(&blk)
      define_method :stop do
        instance_eval &blk
      end
    end
  end
  listen :enable do
    start
  end  
  listen :disable do
    stop
  end  
end
