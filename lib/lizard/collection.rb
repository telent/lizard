class Lizard;end
class Lizard::Collection
  def initialize(max_age)
    @max_age=max_age
    @data=[]
  end
  def add(value,timestamp=nil)
    # this is almost certainly not the most efficient data structure
    # for the purpose.  It it, however, simple
    if timestamp 
      @data << [value,timestamp]
      @data = @data.sort_by {|f| f[1]}
    else
      @data << [value,Time.now]
    end
    expire
  end
  def length
    @data.length
  end
  def <<(v)
    add(v)
  end
  def expire
    cutoff=Time.now-@max_age
    @data=@data.keep_if {|i| i[1] > cutoff }
  end
end
