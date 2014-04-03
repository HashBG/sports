HashbgSports::Application.routes.draw do

  root 'static_pages#index'
  
  require 'sidekiq/web'
  require 'sidetiq/web'
  
  mount Sidekiq::Web => '/sidekiq'
  
  #get 'bet_with_btc' => 'bet#bet_with_btc', :constraints => {:format => :json}
  get 'bet_with_btc' => 'bet#bet_with_btc', :format=>false, :defaults=>{:format=>'json'}
  
end