# a Collection is an array-like object in which each element is timestamped
# when added, and which discards elements older than a specified maximum
# time

require 'lizard/collection'

describe Lizard::Collection do
  before do
    @c=Lizard::Collection.new 60
  end

  it "logs values with timestamps" do
    @c.add(1,Time.now)
    assert_equal 1,@c.length
  end
  it "logs values without timestamps" do
    @c << 2
    val,time= @c.instance_eval do @data.first end
    assert_equal 2,val
    assert_in_delta Time.now,time
  end
  it "rejects elements which are too old" do
    @c.add(1,Time.now)
    @c.add(2,Time.now-80)
    assert_equal 1,@c.length
  end
  it "#average returns the average value" 
  it "#moving_average returns the exponentially decaying weighted moving average"
end
