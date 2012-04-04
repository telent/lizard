require 'lizard'
require 'pp'

#Thread.new { EM.run }.abort_on_exception = true

# :mail specifies global mail settings such as mailhost, port number,
# TLS and auth configuration.
# :notifications specifies _defaults_ for all forms of notification.
# In the case of email that would be things like sender/recipient address
# etc that can meaningfully be overridden by individual monitors

lizard=Lizard.new :mail=>{
  host: "btyemark.telent.net", domain: "4a.telent.net",
  to: "root@telent.net", from: "root@stargreen.com"
}

lizard.add Process,'sagepay' do 

  user 'stargreen'
  start 'iostat 3'
  target_status :run

  log stderr: {facility: :user, priority: :warning}
  log stdout: {facility: :user, priority: :debug}

  poll interval: 5, keep: 5 do |results|
#    http_get 'http://www.google.com', warn: 1, timeout: 5 do 
#      results << ((r.status==200) && r.elapsed)
#    end
    results << rand*2
    if (c=results.compact.count) < 3 then
      notify "connection flakey #{c}/5",results
    end
    if (a=results.average) > 1 then
      notify "connection slow #{a} avg",results
      restart_service
    end
  end
  notification :mail => {
    to: "dan@telent.net", 
    # subject: "Lizard alert", # subject line defaults to something sane
    # from: "lizard@telent.net" # usually set globally
  }
end

lizard.add Process,'sag' do 
  start 'vmstat 10 &'
#  detaches true
end

lizard.start_watch

