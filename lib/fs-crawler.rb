require "rubygems"
require "rb-inotify"
require "eventmachine"
require "socket"
require "yaml"


#
module Crawler

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
  class Config

    # the path to config file.
    #
    # @return [String]
    attr_accessor :path

    # specifying crawling pathes.
    #
    # @return [Array<String>]
    attr_accessor :targets

    # Creates a new {Config}.
    # If config file does not exist, it will set current directory as default path.
    def initialize path
      @path = path
      @config = YAML.load_file path
      @targets = @config["path"]
    rescue=>e
      @targets = ["."]
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

    #
    attr_accessor :options

    #
    attr_accessor :port

    #
    attr_accessor :ip

    #
    attr_accessor :dport

    #
    attr_accessor :dip

    #
    attr_accessor :config

    #
    attr_accessor :notifier

    #
    attr_accessor :stream

    #
    def initialize options
      @options = options
      @port = @options[:port]
      @ip = @options[:ip]
      @dport = @options[:dport]
      @dip = @options[:dip]
      @config = Config.new @options[:config]

      init_connection @dip, @dport
      init_notifier @config
    end

    #
    def run
      EM.run { EM.watch(@notifier.to_io) { @notifier.process } }
    end

    def init_connection ip, port
      @stream = TCPSocket.open ip, port
    rescue
      @stream = STDOUT
    end

    def init_notifier config
      @notifier = INotify::Notifier.new
      @config.targets.each do |target|
        @notifier.watch(target, :all_events) do |e|
          # notify target was modified to distination.
          @stream << "#{e.absolute_name}, #{e.flags.join('|')}"
        end
      end
    end
    
  end
  
end

