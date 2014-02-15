task default: :test

desc "Prepare archive for deployment"
task :archive do
  sh 'zip -r ~/splitjoin.zip autoload/ doc/splitjoin.txt ftplugin/ plugin/'
end

desc "Test with all possible command types"
task :test do
  sh 'rspec spec'
  sh 'TYPE=ack rspec spec'
  sh 'TYPE=ag rspec spec'
end
