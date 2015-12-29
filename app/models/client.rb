class Client < ActiveRecord::Base
  include ConstHelper
  has_many :queue_images
  has_many :likes
  mount_uploader :avatar, AvatarUploader
  # Include default devise modules. Others available are:
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :validatable, :lockable
  validates :name, presence: true
  validates :name, uniqueness: true, if: -> { self.name.present? }
  validates :avatar, presence: true

  def user?
    role_id.nil? || role_id == CLIENT_TYPE_USER
  end

  def admin?
    !role_id.nil? && role_id == CLIENT_TYPE_ADMIN
  end

  private

end
