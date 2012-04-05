class Lizard
  module Syslog 
    def initialize(host,port)
      @host=host; @port=port
    end
    def send_message(facility,priority,content,tag="lizard")
      # per http://www.faqs.org/rfcs/rfc3164.html
      @hostname||=Socket.gethostname.split(".").first
      f=[:kernel,:user,:mail,:daemon,:auth,:syslog,
         :lpr,:news,:uucp,:cron,:authpriv,:ftp,
         12,13,14,15,
         :local0,:local1,:local2,:local3,
         :local4,:local5,:local6,:local7].index(facility)
      p=[:emerg,:alert,:crit,:err,
         :warning,:notice,:info,:debug].index(priority)
      raise "facility #{facility} unrecognized" unless f
      raise "priority #{priority} unrecognized" unless p
      timestamp=Time.now.strftime("%b %_m %H:%M:%S")
      payload=sprintf("<%d>",(f << 3)|p)+
        "#{timestamp} #{@hostname} #{tag}:#{content}"
      send_datagram payload[0..1023],@host,@port
    end
  end                 
end
