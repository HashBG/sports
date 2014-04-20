HashbgSports::Application.routes.draw do

  devise_for :users
  
  root 'static_pages#index'
  
  require 'sidekiq/web'
  require 'sidetiq/web'
  
  mount Sidekiq::Web => '/sidekiq'
  
  post 'bet_with_btc' => 'bet#bet_with_btc', :format=>false, :defaults=>{:format=>'json'}
  post 'received_btc_transaction' => 'bet#received_btc_transaction', :format=>false, :defaults=>{:format=>'json'}
  
end
