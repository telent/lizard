
describe Lizard::Process do
  before do
    @lizard=Lizard.new
  end

  it "instantiates" do
    @lizard.add Process,'sagepay' do 
      user 'stargreen'
      start '/home/stargreen/bin/bundle-exec rake sagepay-queue'
      pid '/var/run/rticulate/sagepay-queue.pid'
      detaches false
      rotate stdout: [size: 100*1024*1024], stderr: [time: 86400]
      check do
        #http_get 'http://localhost:3023/sagepay', warn: 1, timeout: 5 do |r|
        #  r.status==405 # method not allowed
        #end
        42
      end
      check do
        3.14
      end
    end
    w=@lizard.all
    assert_equal ["sagepay"],w.keys.sort
    att= w["sagepay"].instance_eval { @attributes }

    # scalar valued properties store first arg
    assert_equal "stargreen",att[:user]
    assert_equal "/home/stargreen/bin/bundle-exec rake sagepay-queue",att[:start]
    x={:stdout=>[{:size=>104857600}], :stderr=>[{:time=>86400}]}
    assert_equal x,att[:rotate]

    # block-valued properties store a list of zero-arg blocks
    assert_equal 42,att[:check][0].call
    assert_equal 3.14,att[:check][1].call
  end
end

describe Lizard::Filesystem do
  before do
    @lizard=Lizard.new
  end
  it "instantiates" do
    skip "not implemented"
    Lizard::Filesystem.new 'postgres' do
      check do
        statvfs=Filesystem.statvfs "/home"
      end
    end
  end
end

  
