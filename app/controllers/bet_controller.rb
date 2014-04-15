require 'hashbg/couchdb_base'
require 'hashbg/bitcoin_base'

class BetController < ApplicationController
  include Hashbg::CouchdbBase
  respond_to :json
  
  skip_before_filter :verify_authenticity_token, :only => [:received_btc_transaction]
  
  def initialize
    @db ||= CouchRest.database!(couch_admin_host("bets"))
    ensure_read_only_db!(@db)
  end

  def bet_with_btc
    btc_address = Hashbg::BitcoinBase.new_address!
    
    if btc_address
      store_btc_address_to_listen!(btc_address)
      answer = {
        min: 0.001,
        max: 0.1,
        exchangeCourse: 500,
        btc_address: btc_address
      }
      render json: answer
    else
      msg = "No bitcoin address available"
      if response["error"]
        msg = response["error"]
      end
      render json: {error: msg}
    end
  end
  
  def received_btc_transaction
    tid = params["transaction"]
    
    transaction = Hashbg::BitcoinBase.transaction tid
    
    sender_addresses = Hashbg::BitcoinBase.sender_addresses tid
    sender_address = sender_addresses[0] 
    
    transaction["details"].each do |detail|
      address = detail["address"]
      h = {"amount" => detail["amount"]}
      h["sender_address"] = sender_address
      
      update_received_payment!(address, h)
    end
    
    render json: "OK"
  end
  
  private
 
  def store_btc_address_to_listen!(btc_address)
    update_doc!(@db, btc_address, "bets" => params["bets"])
  end

  def update_received_payment!(btc_address, payment)
    update_doc!(@db, btc_address, {"payment" => payment}, true)
  end
  
end
