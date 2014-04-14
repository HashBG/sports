require 'net/http'
require 'uri'
require 'json'

module Hashbg
  
  module BitcoinBase
    
    
    class BitcoinRPC
      def initialize(service_url)
        @uri = URI.parse(service_url)
      end
  
      def method_missing(name, *args)
        post_body = { 'method' => name, 'params' => args, 'id' => 'jsonrpc' }.to_json
        resp = JSON.parse( http_post_request(post_body) )
        raise JSONRPCError, resp['error'] if resp['error']
        resp['result']
      end
  
      def http_post_request(post_body)
        http    = Net::HTTP.new(@uri.host, @uri.port)
        request = Net::HTTP::Post.new(@uri.request_uri)
        request.basic_auth @uri.user, @uri.password
        request.content_type = 'application/json'
        request.body = post_body
        http.request(request).body
      end
  
      class JSONRPCError < RuntimeError; end
    end
    
    mattr_accessor :bitcoin_config
    mattr_accessor :bitcoin_config_path
    self.bitcoin_config_path = "config/bitcoin.yml"
    self.bitcoin_config = {
      "user"=> "btc",
      "password"=> "test",
      "port"=> 18338,
      "host"=> "127.0.0.1"
    }
    # YAML.load(ERB.new(File.new(self.couchdb_config_path).read).result)[Rails.env]
    
    mattr_accessor :rpc_uri
    mattr_accessor :rpc
    self.rpc_uri = "http://#{self.bitcoin_config["user"]}:#{self.bitcoin_config["password"]}@#{self.bitcoin_config["host"]}:#{self.bitcoin_config["port"]}"
    self.rpc = Hashbg::BitcoinBase::BitcoinRPC.new(rpc_uri)
=begin
    def self.rpc_uri
      debugger
      "http://#{self.bitcoin_config["user"]}:#{self.bitcoin_config["password"]}@#{self.bitcoin_config["host"]}:#{self.bitcoin_config["port"]}"
    end
    
    def self.rpc
      BitcoinRPC.new(rpc_uri)
    end
=end
    def self.new_address!
      self.rpc.getnewaddress
    end
    
    def self.transaction(tid)
      self.rpc.gettransaction tid
    end
    
  end
  
end