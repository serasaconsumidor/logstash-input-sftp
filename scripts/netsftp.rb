require "net/sftp"

puts "inicio do processamento"

Net::SFTP.start("localhost", "ftpuser", :password => "ftppass", :port => 2222) do |sftp|
		puts "WORKED"
end