HashbgSports::Application.routes.draw do

  root 'static_pages#index'
  
  require 'sidekiq/web'
  require 'sidetiq/web'
  
  mount Sidekiq::Web => '/sidekiq'
  
  #get 'bet_with_btc' => 'bet#bet_with_btc', :constraints => {:format => :json}
  post 'bet_with_btc' => 'bet#bet_with_btc', :format=>false, :defaults=>{:format=>'json'}
  post 'received_btc_amount' => 'bet#received_btc_amount', :format=>false, :defaults=>{:format=>'json'}
  
end
