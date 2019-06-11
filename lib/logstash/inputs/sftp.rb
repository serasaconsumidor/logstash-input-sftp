# encoding: utf-8
require "logstash/inputs/base"
require "stud/interval"
require "net/sftp"
require "net/ssh"
require "socket"
# Generate a repeating message.
#
# This plugin is intented only as an example.

class LogStash::Inputs::Sftp < LogStash::Inputs::Base
  config_name "sftp"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain"

  # The message string to use in the event.
  config :message, :validate => :string, :default => "Hello World!"

  # Set how frequently messages should be sent.
  #
  # The default, `1`, means send a message every second.
  config :interval, :validate => :number, :default => 1


  #SFTP User Info
  config :username, :validate => :string, :default => "ftpuser"
  config :password, :validate => :string, :default => "ftppass"

  # SFTP server hostname (or ip address)
  config :remote_host, :validate => :string, :default => "localhost"

  # and port number.
  config :port, :validate => :number, :default => 2222

  # Remote SFTP path and local path
  config :remote_path, :validate => :string, :default => "/ftpuser/upload"
  config :local_path, :validate => :string, :default => "/Users/szn6549/ftpteste"


  public
  def register
    @host = Socket.gethostname

    puts "host", @host

    # we can abort the loop if stop? becomes true
    # @logger.info("Registering SFTP Input",
    #          :username => @username, :password => @password,
    #          :remote_host => @remote_host, :port => @port,
    #          :remote_path => @remote_path, :local_path => @local_path)
  end

  def run(queue)

    puts "Run"

    while !stop?

      process(queue)

      event = LogStash::Event.new("message" => @message, "host" => "Teste")
      decorate(event)
      queue << event
      # because the sleep interval can be big, when shutdown happens
      # we want to be able to abort the sleep
      # Stud.stoppable_sleep will frequently evaluate the given block
      # and abort the sleep(@interval) if the return value is true
      Stud.stoppable_sleep(@interval) { stop? }
    end # loop
  end # def run

  def process(queue)
    puts "dentro de process"

    Net::SSH::Transport::Algorithms::ALGORITHMS.values.each { |algs| algs.reject! { |a| a =~ /^ecd(sa|h)-sha2/ } }
    Net::SSH::KnownHosts::SUPPORTED_TYPE.reject! { |t| t =~ /^ecd(sa|h)-sha2/ }
    
    Net::SFTP.start("localhost", "ftpuser", :password => "ftppass", :port => 2222)do |sftp|
      puts "WORKED"
    end
  end

  def stop
    # nothing to do in this case so it is not necessary to define stop
    # examples of common "stop" tasks:
    #  * close sockets (unblocking blocking reads/accepts)
    #  * cleanup temporary files
    #  * terminate spawned threads
  end
end