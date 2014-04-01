class BetController < ApplicationController
  respond_to :json
    
  def bet_with_btc
    sleep(1)
    answer = {
      min: 0.001,
      max: 0.1,
      exchangeCourse: 500,
      btc_address: "1MvqXEnaHwcCz81gfmkNxEvLBQGhjKhAyg"
    }
    respond_with(answer)
  end
  
end
