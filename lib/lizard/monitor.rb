class Lizard::Monitor
  attr_reader :name,:check
  attr_accessor :lizard
  
  def as_json
    @attributes
  end

  def initialize name,&blk
    @name=name
    @log={}
    @attributes=Hash.new {|h,k| h[k]=[] }
    # implicit self, because users are expected to be dsl-use-heavy and 
    # ruby-light
    # http://blog.grayproductions.net/articles/dsl_block_styles
    instance_eval &blk
  end
  def []=(k,v)
    @attributes[k] << v
  end
  def [](k)
    @attributes[k] 
  end
  [:check].each do |meth|
    define_method meth do |&blk|
      @attributes[meth] << blk
    end
  end
  def log params
    @log=@log.merge(params)
  end
  def tag
    @name
  end
  def syslog(stream,message)
    a=@log[stream]
    warn [:stream,a,@log]
    @lizard.syslog a[:facility],a[:priority],message,self.tag
  end
end
