class Topic < ActiveRecord::Base
  belongs_to :user
  has_many :comments, dependent: :destroy

  validates :name, presence: true
  validates :user, presence: true

  def self.get_news
    news = Topic.where(post_type: 'news')
  end
end
