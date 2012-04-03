# Let it never be said/that romance is dead / -*- Ruby -*- Ruby Ruby Ruby!

desc "generate FFI structs"
task :ffi_generate do
  require 'ffi'
  require 'ffi/tools/generator'
  require 'ffi/tools/struct_generator'

  ffi_files = Dir.glob("lib/*.rb.ffi")
  ffi_options = {}# :cflags => "-I/usr/local/mylibrary" }
  ffi_files.each do |ffi_file|
    ruby_file = ffi_file.gsub(/\.ffi$/,'')
    unless uptodate?(ruby_file, [ffi_file])
      puts "generating: #{ffi_file} => #{ruby_file}"
      FFI::Generator.new ffi_file, ruby_file, ffi_options    
    end
  end
end

task :test do
  sh (["ruby","-Ilib","-rminitest/autorun","-rlizard","-rpp"]+
    Dir.glob("test/*.test.rb")).join(" ")
end
