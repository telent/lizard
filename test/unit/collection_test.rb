# a Collection is an array-like object in which each element is timestamped
# when added, and which discards elements older than a specified maximum
# time

require 'lizard/collection'

describe Lizard::Collection do
  it "rejects elements which are too old" do
    c=Lizard::Collection.new 60
    c.add(1,Time.now)
    c.add(2,Time.now-30)
    c.add(2,Time.now-40)
    c.add(2,Time.now-80)
    assert_equal 3,c.length
  end
end
