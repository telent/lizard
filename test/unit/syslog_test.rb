require 'lizard/syslog'

describe "syslog" do
  it "formats messages" do
    stub(Time).now { Time.at 1335210930 }
    conn=Lizard::Syslog::Stream.new facility: :local2, priority: :warning,
      hostname: "example"
    assert_equal "<148>Apr  4 20:55:30 warning tag:hello",conn.format_message("hello")
  end
  it "works as a stream" do
    fake_server=StringIO.new
    conn=Lizard::Syslog::Stream.new facility: :local2, priority: :warning,
    hostname: "example", server: fake_server
    conn.write "something scary happened"
    assert_match /<148>.+scary/, fake_server.string
  end
end
