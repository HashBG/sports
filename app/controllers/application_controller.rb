class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
=begin  
  after_filter :set_csrf_cookie_for_ng

  protected

  def verified_request?
    super || form_authenticity_token == request.headers['X-XSRF-TOKEN']
  end

  private
  def set_csrf_cookie_for_ng
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end
=end

  def render *args
    gon.flash = flash.to_h
    super
  end

  before_filter :set_gon_current_user

  private
  def set_gon_current_user
    gon.current_user = current_user
  end
  
end
