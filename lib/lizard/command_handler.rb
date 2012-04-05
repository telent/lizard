class Lizard
  module CommandHandler
    def initialize(lizard)
      @lizard=lizard
      super
    end
    def receive_data data
      error=nil
      begin
        # {monitor: 'sagepay', target_status: 'run'}
        j=JSON.parse data
        if m=j["monitor"] then
          monitor=@lizard.find_monitor_by_name(m)
          if monitor 
            if s=j['target_status'] then
              monitor.target_status s.to_sym
            end
          else
            error="no such monitor #{m}"
          end
        end
        unless error then
          send_data (if monitor then monitor.as_json else @lizard.all.values.map(&:as_json) end).to_json
          return
        end
      rescue JSON::ParserError =>e
        error=e.inspect
      end
      send_data ({error: e.inspect}).to_json 
    end
  end
end
