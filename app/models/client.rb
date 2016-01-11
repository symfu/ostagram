class Client < ActiveRecord::Base
  # Client type constants
  CLIENT_TYPE_ADMIN = 300
  CLIENT_TYPE_USER = 0
  
  has_many :queue_images, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :pimages, through: :queue_images
  mount_uploader :avatar, AvatarUploader
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :validatable, :lockable
  validates :name, presence: { message: "can't be blank" }
  validates :name, uniqueness: { case_sensitive: false, message: "has already been taken" }, if: -> { self.name.present? }
  validates :avatar, presence: { message: "Please provide an avatar" }
  
  validate :password_confirmation_required?
  validate :password_length_valid?
  validate :email_format_valid?

  def user?
    role_id.nil? || role_id == CLIENT_TYPE_USER
  end

  def admin?
    !role_id.nil? && role_id == CLIENT_TYPE_ADMIN
  end

  # Override Devise validation messages to match test expectations
  def password_confirmation_required?
    return true if password.blank? || password_confirmation.blank? || password == password_confirmation
    errors.add(:password_confirmation, "doesn't match Password")
    false
  end

  def password_length_valid?
    return true if password.blank? || password.length >= 6
    errors.add(:password, 'is too short (minimum is 6 characters)')
    false
  end

  def email_format_valid?
    return true if email.blank? || email =~ /\A[^@\s]+@[^@\s]+\z/
    errors.add(:email, 'is invalid')
    false
  end

  private

end
