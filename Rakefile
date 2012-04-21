# -*- Ruby -*- mode
task :gem do
  sh "gem build lizard.gemspec"
end

namespace :test do
  def run_tests(helper,files)
    if t=ENV['TEST'] then files=t.split(" ") end
    ruby %Q{-rbundler/setup -Ilib -r #{helper} -e "%W(#{files.join(" ")}).each {|f| load(f)}" }
  end

  task :unit do |t|
     run_tests "./test/test_helper", FileList['test/unit/*_test.rb']
  end
  task :intg do |t|
     run_tests "./test/test_helper", FileList['test/integration/*_test.rb']
  end
end
