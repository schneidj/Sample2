class User < ActiveRecord::Base
  attr_accessible :name, :email, :password, :password_confirmation
  has_secure_password
  
  has_many :microposts, :dependent => :destroy
  has_many :relationships, :foreign_key => "follower_id",
                           :dependent => :destroy
  has_many :following, :through => :relationships, :source => :followed
  has_many :reverse_relationships, :foreign_key => "followed_id",
                                   :class_name => "Relationship",
                                   :dependent => :destroy
  has_many :followers, :through => :reverse_relationships, :source => :follower

  validates :name, :presence => true, 
                   :length   => { :maximum => 50 }

  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, :presence => true, 
                    :format   => { :with => email_regex }, 
                    :uniqueness => { :case_sensitive => false }

  validates_presence_of :password, :on => :create

  validates :password, :length       => { :within => 6..40 }

  before_create { generate_token(:auth_token) }

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end

  def self.authenticate_with_auth_token(id, cookie_auth_token)
    user = find_by_id(id)
    (user && user.auth_token == cookie_auth_token) ? user : nil
  end
  
  def following?(followed)
    relationships.find_by_followed_id(followed)
  end

  def follow!(followed)
    relationships.create!(:followed_id => followed.id)
  end
  
  def unfollow!(followed)
      relationships.find_by_followed_id(followed).destroy
  end

  def feed
    # This is preliminary. See Chapter 12 for the full implementation.
    # Micropost.where("user_id = ?", id)
    Micropost.from_users_followed_by(self)
  end
end
