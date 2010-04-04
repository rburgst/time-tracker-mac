task :upload => :appcast

desc "uploads the artifacts to google code"
task :upload do
  require 'yaml'
  yaml = YAML.load_file('ChangeLog.yml')
  version = yaml.first['version']
  file = "build/Release/Time Tracker-#{version}.zip"
  html_file = "appcast/timetracker-#{version}.html"
  sh "python tasks/googlecode_upload.py -s 'Time Tracker for Mac #{version}' -p time-tracker-mac -l 'OpSys-OSX,Type-Archive' '#{file}'"
  sh "python tasks/googlecode_upload.py -s 'Release notes for Time Tracker #{version}' -p time-tracker-mac -l 'Deprecated' '#{html_file}'"
end