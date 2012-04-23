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
  it "default settings can be made at the class level which apply to all instances" do
    Lizard::Alert::Mail.defaults host: "mail.example.com"
    m=Lizard::Alert::Mail.new
    assert_equal "mail.example.com",m.instance_variable_get(:@args)[:host]
  end
end
