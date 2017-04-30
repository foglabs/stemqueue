class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :sample
  belongs_to :topic
  validates :body, presence: true, length: {maximum: 255}
  validates :user, presence: true

  def topic?
    #does comment have topic id, or sample id?
    if topic_id
      true
    elsif sample_id
      false
    end
  end
end
