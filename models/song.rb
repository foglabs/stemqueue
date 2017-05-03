class Song < ActiveRecord::Base
  has_many :song_samples
  has_many :samples, through: :song_samples
  belongs_to :user

  validates :name, presence: true
  validates :user, presence: true

  def get_urls
    urls = {samps: [], userid: user.id, songid: id}

    song_samples.each do |songsamp|
      urls[:samps] << {link: songsamp.sample.specimen.url.gsub(/\A(\w|\W)*audio\//, ""), gain: songsamp.gain}
    end

    urls
  end

  def self.mix(songid)
    #last value of songinfo array is output name!
    # second to last is user id of song
    songo = Song.find(songid)
    songname = songo.name

    songinfo = songo.get_urls

    userid = songinfo['userid']

    filenames_string = ""
    counter = 0

    songinfo[:samps].each do |stemhash|
      # download the boy to the local folder

      filename_noex = stemhash[:link].match(/\/(.*)\.{1}/)[1]
      filename_ex = stemhash[:link].match(/\/(.*\z)/)[1]

      `s3cmd get s3://stemden/audio/#{stemhash[:link]} ./process/#{filename_ex}`

      # addcountertofilename for file uniqueness
      `mv ./process/#{filename_ex} ./process/#{counter.to_s + filename_ex}`
      filename_noex = counter.to_s + filename_noex
      filename_ex = counter.to_s + filename_ex

      # if filename_ex.end_with?("mp3")
      #   `/usr/sox-14.4.2/bin/sox -t mp3 ./process/#{filename_ex} -t wav ./process/#{filename_noex}.wav`

      #   # without extension
      #   filenames_string += "-v #{stemhash[:gain] || 0} ./process/" + filename_noex + ".wav "
      # else
        #with extension
        filenames_string += "./process/" + filename_ex + " "
      # end

      counter += 1
    end

    # mix them shits
    `/usr/sox-14.4.2/bin/sox -m #{filenames_string}#{songname}.wav`

    # upload them shits
    `s3cmd put -f --acl-public #{songname}.wav s3://stemden/audio/mixes/#{songname}.wav`
    `rm -rf ./process/*`

    sampinfo = {name: songname, category: 'mixes', userid: userid, url: "http://s3.amazonaws.com/stemden/audio/mixes/#{songname}.wav"}
    # SampleMaker.perform_async(sampinfo: sampinfo)
    Sample.create(user_id: sampinfo[:userid], name: sampinfo[:name], category: sampinfo[:category], remote_specimen_url: sampinfo[:url])
  end
end
