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

  #SFTP Credentials

  #SFTP User Info
  config :username, :validate => :string, :required => true
  config :password, :validate => :string, :required => true

  # SFTP server hostname (or ip address)
  config :remote_host, :validate => :string, :required => true

  # and port number.
  config :port, :validate => :number, :required => true

  # Remote SFTP path and local path
  config :remote_path, :validate => :string, :required => true
  config :local_path, :validate => :string, :required => true

  # sincedb path
  config :sincedb_path, :validate => :string

  public

  def register
    @logger.debug("DEBUG - Inside register method")
    # call the create .sincedb method
    create_sincedb
  end # def register
  
  def create_sincedb
    # get params to create the file
    begin
      sincedb_dir = ENV["HOME"]

      @sincedb_file = ".sincedb_" + Digest::MD5.hexdigest(@local_path)  
      @sincedb_path = File.join(sincedb_dir, @sincedb_file)

      FileUtils.touch(@sincedb_path)
      @logger.info("Sincedb file path" % @sincedb_path)
    end
  end

  def sincedb_write(file_name, file_data_downloaded)
    @logger.debug("DEBUG - Inside sincedb_write")
    begin
      db = File.open(@sincedb_path, "a")
      db.puts([file_name, file_data_downloaded].flatten.join(" "))
      db.close
    rescue => e
      @logger.error("Error in write in .sincedb file", :exception => e)
    end
  end # def sincedb_write

  def run(queue)
    @logger.debug("DEBUG - Inside run method")

    sftp = connect_sftp
    download_files_from_sftp(sftp)
  end # def run

  def connect_sftp
    @logger.debug("DEBUG - Inside connect_sftp")

    # ssh logic to auth algorithm
    Net::SSH::Transport::Algorithms::ALGORITHMS.values.each { |algs| algs.reject! { |a| a =~ /^ecd(sa|h)-sha2/ } }
    Net::SSH::KnownHosts::SUPPORTED_TYPE.reject! { |t| t =~ /^ecd(sa|h)-sha2/ }
    
    # connect to sftp with credentials
    Net::SFTP.start(@remote_host, @username, :password => @password, :port => @port) do |sftp|
      return sftp       
    end # def connect_sftp
  end

  def download_files_from_sftp(sftp)
    @logger.debug("DEBUG - Inside download_files_from_sftp")
    begin
      sftp.dir.foreach(@remote_path) do |entry| 
        if !entry.name.start_with?(".")
          sincedb_write(entry.name, Time.at(entry.attributes.mtime))
          sftp.download!(@remote_path + entry.name, @local_path + entry.name)
        end
      rescue => e
        @logger.error("Cannot interate, find files or read from sftp folder", :exception => e)
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