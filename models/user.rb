class User < ActiveRecord::Base
  has_many :samples
  has_many :songs
  has_many :comments, dependent: :destroy
  has_many :topics, dependent: :destroy

  validates :name, presence: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def admin?
    role == "bonsai"
  end
end
