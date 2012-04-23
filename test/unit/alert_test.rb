%w(EM Protocols SmtpClient).reduce(Object) {|m,o| m.const_set(o,Module.new) }
require 'lizard/alert/mail'

describe Lizard::Alert::Mail do
  it "sends email using EventMachine" do
    args={domain: "example.com", 
      host: "localhost",
      port: 567,
      to: "root@example.com",
      from: "lizard@example.com"}
    m=Lizard::Alert::Mail.new(args)
    mock(EM::Protocols::SmtpClient).send(args.merge(body: "TEST MESSAGE"))
    m.call("TEST MESSAGE")
  end
  it "has sensible default subject line"
  it "uses ERB templates to interpolate supplied message into a mail body"
end
