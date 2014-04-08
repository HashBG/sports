require 'uri'
require 'yajl/http_stream'

module Hashbg
  module Apis
    
    mattr_accessor :apis_config
    mattr_accessor :apis_config_path
    self.apis_config_path = "config/apis.yml"
    self.apis_config = YAML.load(ERB.new(File.new(self.apis_config_path).read).result)[Rails.env]
    
    def self.odds_feed_config
      apis_config["odds_feed"]
    end
    
    def self.btc_api_config
      apis_config["btc_api"]
    end
    
    def self.get_odds_feed(tick = nil)
      if odds_feed_config["type"] == "file"
        json = File.new(odds_feed_config["location"], 'r')
        parser = Yajl::Parser.new
        parser.parse(json)
      else
        if tick
          url = URI.parse "#{odds_feed_config['location']}?tick=#{tick}"
        else
          url = URI.parse odds_feed_config["location"]
        end
        Yajl::HttpStream.get(url)
      end
    end
    
    def self.btc_api_uri
      btc_api_config["location"]
    end
    
  end
end