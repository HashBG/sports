require 'hashbg/couchdb_base'

class BetController < ApplicationController
  include Hashbg::CouchdbBase
  respond_to :json
  
  skip_before_filter :verify_authenticity_token, :only => [:received_btc_amount]
  
  def initialize
    super
    @db ||= CouchRest.database!(couch_host("bets"))
    ensure_read_only_db!(@db)
  end
    
  def bet_with_btc
    btc_address = RestClient.post "http://87.117.226.162/WebApi/GetAddress.aspx",  {bets: transformed_params}.to_json, :content_type => :json, :accept => :json

    if btc_address
      store_btc_address_to_listen!(btc_address)
      answer = {
        min: 0.001,
        max: 0.1,
        exchangeCourse: 500,
        #btc_address: "msNwmVTAJpYYa1Ppxn62gnmoeYtzLVt3ZS"
        btc_address: btc_address
      }
      render json: answer
    else
      render json: {error: "No bitcoin address available"}
    end

  end
  
  def received_btc_amount
    if payment_params!
      if payment_params["status"] == "OK"
        update_doc!(@db, payment_params["our_address"], "payment" => payment_params)
        render json: "OK"
      else
        update_doc!(@db, payment_params["our_address"], "error" => payment_params)
        render json: "OK - received error message"
      end
    end
  end
  
  private
  
  def payment_params!
    keys = (["our_address", "sender_address", "amount", "detected_at", "status"] - payment_params.keys)
    if keys.empty?
      true 
    else
      logger.error "malformed btc server response: #{params}"
      render json: {missing_keys: keys}
      false
    end
  end
  
  def payment_params
    @payment_params ||= params["payment"] || {}
  end
  
  def transformed_params
    r = []
    params["bets"].each do |match_id, content|
      r << transformed_match_entry(match_id, content)
    end
    r
  end
  
  def transformed_match_entry(match_id, content)
    r = content.except("coefficient")
    r["match"] = match_id
    r["coefficient"] = content["coefficient"]["decimal"] 
    r
  end
  
  def store_btc_address_to_listen!(btc_address)
    update_doc!(@db, btc_address, "bets" => params["bets"])
  end
  
end
