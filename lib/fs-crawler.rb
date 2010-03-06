require "rubygems"
require "eventmachine"
require "find"
require "pathname"
require "rb-inotify"
require "socket"
require "time"
require "yaml"

module Crawler                  # :nodoc:

  # Configuration file format is yaml.
  # For example, below setting is linux kernel source code.
  # 
  # @example
  #   path:
  #     - arch/x86
  #     - include
  #     - init
  #     - lib
  #     - kernel
  #     - mm
  #
  # == key list
  # - path
  # - ignore
  class Config

    # the path to config file.
    #
    # @return [String]
    attr_accessor :path

    # specifying crawling pathes.
    #
    # @return [Array<String>]
    attr_accessor :targets

    # specifying no crawing pathes.
    #
    # @return [Array<String>]
    attr_accessor :ignores

    # Creates a new {Config}.
    # If config file does not exist, it will set current directory as default path.
    def initialize path
      @path = path
      @config = YAML.load_file path
      @targets = @config["path"]
      @ignores = @config["ignore"]
    rescue=>e
      @targets = ["."]
      @ignores = [".git/", ".svn/"]
    end
    
  end

  #
  #
  #
  class Filesystem
    # for inotify(2) flags.
    FLAGS = [ :access,
              :attrib,
              :close_write,
              :close_nowrite,
              :modify,
              :open,
              :moved_from,
              :moved_to,
              :create,
              :delete,
              :delete_self,
              :move_self,
              :close,
              :move,
              :all_events,
            ].freeze

    # program argument hash.
    attr_accessor :options

    # distination port number.
    attr_accessor :port

    # distination IP address or host name.
    attr_accessor :ip

    # Crawler::Config object.
    attr_accessor :config

    # rb-inotify object.
    attr_accessor :notifier

    # distination socket port or stdout stream.
    attr_accessor :stream

    # Create a new Filesystem.
    def initialize options
      @options = options
      @port = @options[:port]
      @ip = @options[:host]
      @config = Config.new @options[:config]

      init_connection @ip, @port
      init_notifier @config
    end

    # start to watch filesystem event.
    def run
#      EM.run { EM.watch(@notifier.to_io) { @notifier.process } }
      @notifier.run
    end

    #
    def init_connection ip, port
      @stream = TCPSocket.open ip, port
    rescue
      @stream = $defout
    end

    #
    def init_notifier config
      @notifier = INotify::Notifier.new
      @config.targets.each do |target|
        Find.find(target) do |entry|
          path = Pathname.new(entry)
          abspath = path.realpath.to_s

          # find ignore case...
          next if path.directory?
          next if @config.ignores.detect {|i| abspath =~ /#{i}/ }

          # add watch list.
          puts "Add '#{abspath}' watching now"
          @notifier.watch(abspath, :all_events) do |e|
            # notify target was modified to distination.
            @stream.write "'#{e.absolute_name}' '#{Time.now.iso8601(3)}' #{e.flags.join('|')}\n"
          end
        end
      end
    end
    
  end
  
end

