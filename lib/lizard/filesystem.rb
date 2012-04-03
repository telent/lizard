class Lizard::Filesystem < Lizard::Monitor
  [:path,:device].each do |meth|
    define_method meth do |v|
      @attributes[meth] << v
    end
  end
end
