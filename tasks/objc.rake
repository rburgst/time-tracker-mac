task :build => "objc:compile"

namespace :objc do
  desc "Compiles all Objective-C bundles for testing"
  
  task :clean do
    FileUtils.rm_r Dir["build/bundles"], :verbose => true
    FileUtils.rm_r Dir["build/nibs"], :verbose => true
  end
  
  task :compile => "build/bundles/Application.bundle"
  
  file 'build/bundles/Application.m' do
    FileUtils.mkdir_p "build/bundles"
    puts "Generating Application.m"
    File.open('build/bundles/Application.m', 'w') do |f|
      f.write('void Init_Application() {}')
    end
  end
  
  file "build/bundles/Application.bundle" => 'build/bundles/Application.m' do
    FileUtils.mkdir_p "build/bundles"
    FileUtils.rm Dir["build/bundles/Application.bundle"]
    puts "Building Application.bundle"
    sh "gcc -o build/bundles/Application.bundle -lobjc -framework Foundation -bundle build/bundles/Application.m build/bundles/*.o"
  end
  
  model_file_paths = []
  model_file_paths += Dir.glob("src/objc/*.m")
  
  model_file_paths.each do |path|
    path =~ /^(.*\/)?(.*)\.m/
    model_dir = $1
    model_name = $2
    
    file "build/bundles/Application.bundle" => "build/bundles/#{model_name}.o"
    
    file "build/bundles/#{model_name}.o" => ["./#{model_dir}#{model_name}.m", "./#{model_dir}#{model_name}.h"] do |t|
      FileUtils.mkdir_p "build/bundles"
      #puts "Building #{model_name}.o"
      sh "gcc -o build/bundles/#{model_name}.o -c ./#{model_dir}#{model_name}.m"
    end

  end

  nib_files = []
  task :compile_nib
  nib_files.each do |nib_name|
    nib = "build/nibs/#{nib_name}.nib"
    xib = "English.lproj/#{nib_name}.xib"

    task :compile_nib => nib

    file nib => xib do
      FileUtils.mkdir_p "build/nibs"
      puts "Compiling #{xib} to #{nib}"
      sh "ibtool --errors --warnings --notices --output-format human-readable-text --compile #{nib} #{xib}"
    end

  end
  
end

