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
    begin
      btc_address = Hashbg::BitcoinBase.new_address!

      store_btc_address_to_listen!(btc_address)
      answer = {
        min: 0.001,
        max: 0.1,
        exchangeCourse: 500,
        btc_address: btc_address
      }
      render json: answer
    rescue => e
      render json: {error: e.message}
    end
  end
  
  def received_btc_transaction
    tid = params["transaction"]
    
    if transaction = Hashbg::BitcoinBase.transaction(tid)
      
      sender_addresses = Hashbg::BitcoinBase.sender_addresses tid
      sender_address = sender_addresses[0]
      receiver_addresses = []
      
      transaction["details"].each do |detail|
        if detail["category"] == "receive"
          address = detail["address"]
          receiver_addresses << address
          h = {"amount" => detail["amount"]}
          h["sender_address"] = sender_address
          
          update_received_payment!(address, h)
        end
      end
      
      logger.info "Received payment for #{receiver_addresses} from #{sender_address}"
      render json: "OK"
    else
      logger.info "Could not find transaction with ID #{tid}"
      render json: "ERROR: Could not find transaction wit ID #{tid}"
    end
  end
  
  private
 
  def store_btc_address_to_listen!(btc_address)
    update_doc!(@db, btc_address, "bets" => params["bets"])
  end

  def update_received_payment!(btc_address, payment)
    update_doc!(@db, btc_address, {"payment" => payment}, :merge => true, :only_update => true)
  end
  
end
