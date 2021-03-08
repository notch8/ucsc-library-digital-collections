class User < ApplicationRecord
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Role-management behaviors.
  include Hydra::RoleManagement::UserRoles


  # Connects this user object to Curation Concerns behaviors.
  include Hyrax::User
  # Connects this user object to Hyrax behaviors.
  include Hyrax::User
  include Hyrax::UserUsageStats

  def current_access_grants
    @current_access_grants ||= UserAccessGrant.where(user_id: id).where("start < ?", DateTime.now).where("end > ?", DateTime.now).map(&:object_id)
  end

 # if Blacklight::Utils.needs_attr_accessible?
 #   attr_accessible :email, :password, :password_confirmation
 # end

  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end
end
