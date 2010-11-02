$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'models'
require 'httparty'

module Zong

  class Zongosaurus
    include HTTParty
    base_uri 'http://localhost/sendit.ldmobile.net'
    debug_output $stderr

    def ack (params= {})
      self.class.get('/MO/zong_ack.php', :query => params)
    end
  end

  class BaseLog

    attr_reader :file_path, :file_size

    def initialize (file_path)
      @file_path = file_path
      if File.exists? @file_path
        @file_size = File.size(@file_path)
      else
        @file_size = 0
      end
    end

    def text
      open(@file_path, 'r') { |f| f.read }
    end

    def last_line
      open(@file_path, 'r') { |f| f.readlines.last }
    end

    def reset
      f = open(@file_path, 'w')
      f.close
    end

    def changed?
      File.size(@file_path) != @file_size
    end
  end
end