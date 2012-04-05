module Lizard::Notification
  class Mail
    def subject_line
      "[lizard] #{@lizard.hostname}/#{@monitor.name} #{(@message.join(" "))[0..60]}"
    end
    def initialize(lizard,monitor,defaults,message)
      @message=message      
      @lizard=lizard
      # 'defaults' is the merge of settings in the individual monitor
      # and overall default settings in Lizard.new :notifications. We
      # merge again with global mail settings to get "infrastructure"
      # things like mailhost, port, tls/auth config
      @defaults=lizard.mail.merge(defaults)
      @monitor=monitor
      @subject=subject_line
      if h=defaults[:header] and s=h[:subject] then
        @subject=s
      end
    end
    def body
      %Q{
The monitor #{@monitor.name} on host #{@lizard.hostname} reports a
possible problem.  The message is

  #{@message.join("\n")}

Anguimorphically yours

  - The Lizard
}
    end

    def send!
      h=(@defaults[:header] || {}).merge({subject: @subject})
      attr=@defaults.merge({ header:h,body: self.body})
      warn attr
      EM::Protocols::SmtpClient.send(attr)
    end
  end
end
