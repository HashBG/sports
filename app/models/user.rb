class User < ActiveRecord::Base
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :validatable, :recoverable
         #, :registerable, :rememberable, :trackable
end
