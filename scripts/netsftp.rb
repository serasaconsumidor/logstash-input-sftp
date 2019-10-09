require "net/sftp"

puts "inicio do processamento"

Net::SSH::Transport::Algorithms::ALGORITHMS.values.each { |algs| algs.reject! { |a| a =~ /^ecd(sa|h)-sha2/ } }
Net::SSH::KnownHosts::SUPPORTED_TYPE.reject! { |t| t =~ /^ecd(sa|h)-sha2/ }

Net::SFTP.start("localhost", "ftpuser", :password => "ftppass", :port => 2222) do |sftp|
		puts "WORKED"
end