class Client < ActiveRecord::Base
  ROLE_ADMIN = 300
  ROLE_REGULAR_USER = 0
  
  MINIMUM_PASSWORD_LENGTH = 6
  EMAIL_FORMAT_REGEX = /\A[^@\s]+@[^@\s]+\z/

  has_many :queue_images, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :pimages, through: :queue_images

  mount_uploader :avatar, AvatarUploader

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :validatable, :lockable

  validates :name, presence: { message: "can't be blank" }
  validates :name, uniqueness: { case_sensitive: false, message: "has already been taken" }, 
            if: :name_present?
  validates :avatar, presence: { message: "Please provide an avatar" }
  
  validate :password_confirmation_matches
  validate :password_meets_minimum_length
  validate :email_has_valid_format

  def user?
    role_id.nil? || role_id == ROLE_REGULAR_USER
  end

  def regular_user?
    user?
  end

  def admin?
    role_id == ROLE_ADMIN
  end

  private

  def name_present?
    name.present?
  end

  def password_confirmation_matches
    return true if password_and_confirmation_match?
    
    errors.add(:password_confirmation, "doesn't match Password")
    false
  end

  def password_and_confirmation_match?
    password.blank? || password_confirmation.blank? || password == password_confirmation
  end

  def password_meets_minimum_length
    return true if password_length_valid?
    
    errors.add(:password, "is too short (minimum is #{MINIMUM_PASSWORD_LENGTH} characters)")
    false
  end

  def password_length_valid?
    password.blank? || password.length >= MINIMUM_PASSWORD_LENGTH
  end

  def email_has_valid_format
    return true if email_format_valid?
    
    errors.add(:email, 'is invalid')
    false
  end

  def email_format_valid?
    email.blank? || EMAIL_FORMAT_REGEX.match(email)
  end
end
