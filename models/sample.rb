class Sample < ActiveRecord::Base
  belongs_to :user
  has_many :song_samples, dependent: :destroy
  has_many :songs, through: :song_samples
  has_many :comments, dependent: :destroy

  validates :specimen, presence: {message: "You didn't include a file."}
  validates :category, presence: true
  validates :name, presence: true, uniqueness: true
  validates :user, presence: true

  mount_uploader :specimen, SpecimenUploader

  def self.makesample(sampinfo)
    Sample.create(user: User.find(sampinfo['userid']), name: sampinfo['name'], category: sampinfo['category'], remote_specimen_url: sampinfo['url'])
  end
end
