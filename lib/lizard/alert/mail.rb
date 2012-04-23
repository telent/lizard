module Lizard::Alert
  class Mail
    def self.defaults(args)
      @@args=args
    end
    def initialize(args={})
      @@args||={}
      @args=@@args.merge(args)
    end
    def call(message)
      EM::Protocols::SmtpClient.send(@args.merge(body: message))
    end
  end
end 
