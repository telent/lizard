class Lizard::Config 
  attr_reader :values
  def initialize
    @values={}
  end
  def [](k)
    @values[k]
  end
  class << self
    def hash name
      define_method name do |val|
        @values[name]||={}
        @values[name].merge! val
      end
    end
    def list name
      define_method name do |val,&blk|
        @values[name] ||= []
        if blk then
          @values[name] <<  [val,blk]
        else
          @values[name] <<  val
        end
      end
    end
    def scalar name
      define_method name do |val|
        @values[name] = val
      end
    end
  end
end
