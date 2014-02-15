task default: :test

desc "Prepare archive for deployment"
task :archive do
  sh 'zip -r ~/writable_search.zip autoload/ doc/writable_search.txt ftplugin/ plugin/ syntax/'
end

desc "Test with all possible command types"
task :test do
  sh 'rspec spec'
  sh 'TYPE=ack rspec spec'
  sh 'TYPE=ag rspec spec'
end
