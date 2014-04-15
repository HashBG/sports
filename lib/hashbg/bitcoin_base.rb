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
    self.bitcoin_config = YAML.load(ERB.new(File.new(self.bitcoin_config_path).read).result)[Rails.env] 
    
    mattr_accessor :rpc_uri
    mattr_accessor :rpc
    self.rpc_uri = "http://#{self.bitcoin_config["user"]}:#{self.bitcoin_config["password"]}@#{self.bitcoin_config["host"]}:#{self.bitcoin_config["port"]}"
    self.rpc = Hashbg::BitcoinBase::BitcoinRPC.new(rpc_uri)

    def self.new_address!
      self.rpc.getnewaddress
    end
    
    def self.transaction(tid)
      begin
        self.rpc.gettransaction tid
      rescue Hashbg::BitcoinBase::BitcoinRPC::JSONRPCError => e
        nil
      end
    end
    
    def self.sender_addresses(tid)
      full_transaction = self.rpc.decoderawtransaction self.rpc.getrawtransaction(tid)
      sender_addresses = []
      full_transaction["vin"].each do |vin|
        sender_transaction = self.rpc.decoderawtransaction self.rpc.getrawtransaction(vin["txid"])
        sender_addresses += sender_transaction["vout"][vin['vout']]["scriptPubKey"]['addresses']
      end
      sender_addresses
    end
    
  end
  
end