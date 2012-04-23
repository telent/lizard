require 'socket'

module Lizard::Syslog
  class Server
    def initialize(args)
      @host=args[:host] || "localhost"
      @port=args[:port] || 514
      # XXX install ourselves into eventmachine
    end
    def new_stream(args)
      Lizard::Syslog::Stream.new args.merge({server: self})
    end
    def write(data)
      # XXX do something with eventmachine
    end
  end

  class Stream  
    def initialize(args)
      @facility=args[:facility] || :user
      @priority=args[:priority] || :info
      @tag=args[:tag] || :tag
      @server=args[:server] 
      @hostname=args[:priority] || Socket.gethostname.split(".").first
    end

    def format_message(content)
      f=[:kernel,:user,:mail,:daemon,:auth,:syslog,
         :lpr,:news,:uucp,:cron,:authpriv,:ftp,
         12,13,14,15,
         :local0,:local1,:local2,:local3,
         :local4,:local5,:local6,:local7].index(@facility)
      p=[:emerg,:alert,:crit,:err,
         :warning,:notice,:info,:debug].index(@priority)
      raise "facility #{@facility} unrecognized" unless f
      raise "priority #{@priority} unrecognized" unless p
      timestamp=Time.now.strftime("%b %_m %H:%M:%S")
      sprintf("<%d>",(f << 3)|p)+
        "#{timestamp} #{@hostname} #{@tag}:#{content}"
    end
    
    def write(message)
      @server.write(format_message(message))
    end
  end
end
