require 'yaml'
require 'text/format'
require 'builder'

#task :build_release => [:spec, :features, :changelog] do
desc "Builds the release package which can be uploaded"
task :build_release => [:changelog] do
  sh "xcodebuild -configuration Release -target 'Release Package' -arch 'i386 x86_64 ppc' clean build"
end

task :changelog => ['ChangeLog.txt']
task :clean do
  sh "rm -vf ChangeLog.txt"
end

file 'ChangeLog.txt' => 'ChangeLog.yml' do |t|
  puts "Generating '#{t.name}' from '#{t.prerequisites}'"

  # Load the yml file
  yaml = YAML.load_file(t.prerequisites.first)
  
  # Write the changelog file
  fmt_bullets = Text::Format.new
  fmt_bullets.first_indent = 0
  fmt_bullets.body_indent = 4
  fmt_notes = Text::Format.new
  fmt_notes.first_indent = 0
  
  File.open(t.name, 'w') do |txt|
    yaml.each do |release|
      txt.puts "=== #{release['version']} ===  #{release['date']}"
      txt.puts fmt_notes.format(release['notes'])  if release['notes']
      txt.puts
      release['changes'].each do |change|
        txt.puts "  * " + fmt_bullets.format(change)
      end
      txt.puts
    end
  end

end

### Appcast files


yaml = YAML.load_file('ChangeLog.yml')
yaml.each do |release|
  version = release['version']
  task :appcast => "appcast/timetracker-#{version}.html"
  task :clean do
    sh "rm -vf appcast/timetracker-#{version}.html"
  end
  file "appcast/timetracker-#{version}.html" => 'ChangeLog.yml' do |t|
    puts "Generating '#{t.name}'"
    file = File.open(t.name, 'w')
    html = Builder::XmlMarkup.new(:target => file, :indent => 2)
    
    start_release = yaml.index(release)
    end_release = yaml.length - 1
    html.html {
      html.head {
        html.meta('http-equiv' => "content-type", :content => "text/html;charset=utf-8")
        html.title("Time Tracker #{version}")
        html.meta(:name => "robots", :content => "anchors")
        html.link(:href => "timetracker.css", :type => "text/css", :rel => "stylesheet", :media => "all")
      }
      html.body {
        yaml[start_release..end_release].each do |release|
          html.table(:class => "dots", :width => "100%", :border => "0", :cellspacing => "0", :cellpadding => "0") {
            html.tr {
              html.td(:class => "blue", :colspan => "2") {
                html.h3("Changes in Time Tracker #{release['version']}")
              }
            }
            html.tr {
              html.td(:valign => "top", :width => "64") {
                html.img(:src => "logo.png", :alt => "Time Tracker logo", :width => "64", :border => "0")
              }
              html.td(:valign => "top") {
                html.ul {
                  release['changes'].each do |change|
                    html.li(change)
                  end
                }
              }
            }
            html.br
          }
        end 		
      }
    }
  end
end

desc "Generates/updates the appcast"
task :appcast => "appcast/timetracker-stable.xml"
task :clean do
  sh "rm -vf appcast/timetracker-stable.xml"
end
file "appcast/timetracker-stable.xml" => ["ChangeLog.yml", "tasks/build_release.rake"] do |t|
  puts "Generating '#{t.name}'"
  yaml = YAML.load_file('ChangeLog.yml')
  file = File.open(t.name, 'w')
  xml = Builder::XmlMarkup.new(:target => file, :indent => 2)

  lastVer = yaml.first['version']
  # change this
  privKeyFile = "/Users/rainer/Documents/PGP/dsa_priv.pem"
    
  xml.instruct!
  xml.rss(:version => "2.0", 'xmlns:dc' => "http://purl.org/dc/elements/1.1/", 'xmlns:sparkle' => "http://www.andymatuschak.org/xml-namespaces/sparkle") {
    xml.channel {
      xml.title("Time Tracker Appcast")
      xml.link("http://time-tracker-mac.googlecode.com/svn/appcast/timetracker-stable.xml")
      xml.description("Most recent changes with links to updates.")
      xml.language("en")
      
      yaml.each do |release|
        next if release['date'] == nil
        version = release['version']
        
        zipFile = "build/Release/Time Tracker-#{version}.zip"

        if version == lastVer 
          dsaSig = `openssl dgst -sha1 -binary < "#{zipFile}" | openssl dgst -dss1 -sign "#{privKeyFile}" | openssl enc -base64`.chomp
          puts "Signature: '#{dsaSig}'"
        end
        
        filetype = release['filetype'] || "zip"
        fileSize = release['filesize'] || File.size?(zipFile)
        xml.item {
          xml.title("Time Tracker #{version}")
          xml.description("http://time-tracker-mac.googlecode.com/files/timetracker-#{version}.html")
          xml.sparkle:releaseNotesLink, "http://time-tracker-mac.googlecode.com/files/timetracker-#{version}.html"
          xml.pubDate(release['date'].strftime("%a, %d %b %Y %H:%M:%S -0800"))
          xml.enclosure('sparkle:dsaSignature' => "#{dsaSig}", 
            :url => "http://time-tracker-mac.googlecode.com/files/Time Tracker-#{version}.#{filetype}", 
            :length => fileSize, :type => "application/octet-stream", 'sparkle:version' => release['version'])
        }    		
      end
    }
  }
  
end

