require 'minitest/spec'
require 'minitest/autorun'
require 'rr'
class MiniTest::Unit::TestCase
  include RR::Adapters::MiniTest
end
