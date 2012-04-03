require 'lizard'
require 'pp'

lizard=Lizard.new
#Thread.new { EM.run }.abort_on_exception = true

lizard.add Process,'sagepay' do 
  user 'stargreen'
  start 'iostat 3'
  target_status :run
  rotate stdout: [size: 100*1024*1024], stderr: [time: 86400]
  check do
    http_get 'http://www.google.com', warn: 1, timeout: 5 do |r|
      r.status==200
    end
  end
end

lizard.add Process,'sag' do 
  start 'vmstat 10 &'
  detaches true
end

lizard.start_watch

