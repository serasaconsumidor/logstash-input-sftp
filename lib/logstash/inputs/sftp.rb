# encoding: utf-8
require "logstash/namespace"
require "logstash/inputs/base"
require "stud/interval"
require "net/sftp"
require "net/ssh"
require "digest/md5"
require "filewatch/bootstrap"

# This plugin goal is intented to make a connection with sFTP
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
  config :remote_path, :validate => :string, :default => "/upload/ftp/"
  config :local_path, :validate => :string, :default => "/Users/szn6549/ftpteste/"

  # sincedb path
  config :sincedb_path, :validate => :string

  # path to the files to use as input
  config :path_to_files, :validate => :string, :default => "/Users/szn6549/ftpteste"


  public
  def register
    puts "inside register method"
    create_sincedb
  end # def register

  def create_sincedb
    sincedb_dir = ENV["HOME"]

    @sincedb_file = ".sincedb_" + Digest::MD5.hexdigest(@path_to_files)
    puts @sincedb_file    
    @sincedb_path = File.join(sincedb_dir, @sincedb_file)
    puts @sincedb_path

    FileUtils.touch(@sincedb_path)
  end # def create_sincedb

  def sincedb_write(file_name)
    puts "inside sincedb_write"
    begin
      db = File.open(@sincedb_path, "a")
      db.puts(file_name)
      db.close
    end
  end # def sincedb_write

  def run(queue)

    puts "inside run method"

    sftp = connect_sftp
    download_files_from_sftp(sftp)

    while !stop?
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

  def connect_sftp

    puts "inside connect_sftp"

    # ssh logic to auth algorithm
    Net::SSH::Transport::Algorithms::ALGORITHMS.values.each { |algs| algs.reject! { |a| a =~ /^ecd(sa|h)-sha2/ } }
    Net::SSH::KnownHosts::SUPPORTED_TYPE.reject! { |t| t =~ /^ecd(sa|h)-sha2/ }
    
    # connect to sftp with credentials
    Net::SFTP.start(@remote_host, @username, :password => @password, :port => @port) do |sftp|
      puts "inside net start"
      return sftp       
    end # def connect_sftp
  end

  def download_files_from_sftp(sftp)
    puts "inside download_files_from_sftp"

    sftp.dir.foreach('/upload/ftp') do |entry| 

      if !entry.name.start_with?(".")
        puts "inside foreach"

        puts entry.name

        #puts entry.longname 
        #puts entry.attributes.mtime
        #puts Time.at(entry.attributes.mtime) 

        sftp.download!(@remote_path + entry.name, @local_path + entry.name)
        puts "file downloaded"

        sincedb_write(entry.name)
        puts "file name writed on sincedb"
      end
    end
  end # def download_files_from_sftp

  def stop
    # nothing to do in this case so it is not necessary to define stop
    # examples of common "stop" tasks:
    #  * close sockets (unblocking blocking reads/accepts)
    #  * cleanup temporary files
    #  * terminate spawned threads
  end
end