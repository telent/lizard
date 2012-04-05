require 'lizard'

# Instantiate the overall controller

lizard=Lizard.new :syslog_server=>"localhost:514", # this is default
:command_socket=>"/var/run/lizard.socket", # for controlling a running Lizard
:mail=>{
  # If you want Lizard to send mail, you must tell it how.
  # :mail specifies global mail settings such as mailhost, port number,
  # TLS and auth configuration.  The allowable options are as for
  # EventMachine::Protocols::SmtpClient
  host: "btyemark.telent.net", domain: "4a.telent.net",
  to: "root@telent.net", from: "root@stargreen.com"
}
# :notifications specifies _defaults_ for all forms of notification.
# In the case of email that would be things like sender/recipient address
# etc that can meaningfully be overridden by individual monitors

# Add monitors for each service to control  

lizard.add Process,'iostat' do 
  # username to run as
  user 'stargreen' 
  # how to start this process
  start 'iostat 3' 
  # whether to start this process?  Set to :stop to disable
  target_status :run

  # logging is via syslog
  log stderr: {facility: :user, priority: :warning}
  log stdout: {facility: :user, priority: :debug}

  poll interval: 5, keep: 5 do |results|
#    http_get 'http://www.google.com', warn: 1, timeout: 5 do 
#      results << ((r.status==200) && r.elapsed)
#    end
    # this is clearly an example.  Imagine that rand*2 is instead 
    # measuring something useful about the service being checked
    results << rand*2
    if (c=results.compact.count) < 3 then
      notify "connection flakey #{c}/5",results
    end
    if (a=results.average) > 1 then
      notify "connection slow #{a} avg",results
      restart_service
    end
  end
  
  # where to send notifications when something calls #notify.  This is
  # in addition to the default notifications list maintained in the
  # Lizard object
  notification :mail => {
    to: "dan@telent.net", 
    # subject: "Lizard alert", # subject line defaults to something sane
    # from: "lizard@telent.net" # usually set globally
  }
end

lizard.start_watch

