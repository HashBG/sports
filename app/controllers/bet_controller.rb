require 'rest_client'

class BetController < ApplicationController
  respond_to :json
    
  def bet_with_btc
    btc_address = RestClient.post "http://87.117.226.162/WebApi/GetAddress.aspx",  {bets: transformed_params}.to_json, :content_type => :json, :accept => :json

    answer = {
      min: 0.001,
      max: 0.1,
      exchangeCourse: 500,
      #btc_address: "msNwmVTAJpYYa1Ppxn62gnmoeYtzLVt3ZS"
      btc_address: btc_address
    }
    render json: answer
  end
  
  private
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
  
end
