require 'lizard'
require 'pp'

lizard=Lizard.new
#Thread.new { EM.run }.abort_on_exception = true

lizard.add Process,'sagepay' do 

  user 'stargreen'
  start 'iostat 3'
  target_status :run

  log stderr: {facility: :user, priority: :warning}
  log stdout: {facility: :user, priority: :debug}

  poll interval: 30, keep: 5 do |results|
    http_get 'http://www.google.com', warn: 1, timeout: 5 do |r|
      results << ((r.status==200) && r.elapsed)
    end
    if results.compact.count < 3 then
      notify "connection flakey"
    end
    if results.average > 1 then
      notify "connection slow"
      restart
    end
  end
end

lizard.add Process,'sag' do 
  start 'vmstat 10 &'
#  detaches true
end

lizard.start_watch

