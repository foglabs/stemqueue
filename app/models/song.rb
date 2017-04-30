class Song < ActiveRecord::Base
  has_many :song_samples
  has_many :samples, through: :song_samples
  belongs_to :user

  validates :name, presence: true
  validates :user, presence: true

  def get_urls
    urls = {samps: [], userid: user.id, username: name, songid: id}
    # samples.each do |samp|
    #   #gives url as username/filename.ext
    #   urls << [samp.specimen.url.gsub(/\A(\w|\W)*audio\//, "")]
    # end

    song_samples.each do |songsamp|
      urls[:samps] << {link: songsamp.sample.specimen.url.gsub(/\A(\w|\W)*audio\//, ""), gain: songsamp.gain}
    end

    urls
  end

  def self.mix(songinfo)
    #last value of songinfo array is output name!
    # second to last is user id of song

    songo = Song.find(songinfo['songid'])
    songname = songo.name
    userid = songinfo['userid']

    filenames_string = ""
    counter = 0

    songinfo.each do |url|
      # download the boy to the local folder

      filename_noex = url[0].match(/\/(.*)\.{1}/)[1]
      filename_ex = url[0].match(/\/(.*\z)/)[1]

      `s3cmd get s3://stemden/audio/#{url[0]} ./process/#{filename_ex}`

      # addcountertofilename for file uniqueness
      `mv ./process/#{filename_ex} ./process/#{counter.to_s + filename_ex}`
      filename_noex = counter.to_s + filename_noex
      filename_ex = counter.to_s + filename_ex

      if filename_ex.end_with?("mp3")
        `/usr/sox-14.4.2/bin/sox -t mp3 ./process/#{filename_ex} -t wav ./process/#{filename_noex}.wav`

        # without extension
        filenames_string += "-v #{url[1]} ./process/" + filename_noex + ".wav "
      else
        #with extension
        filenames_string += "./process/" + filename_ex + " "
      end

      counter += 1
    end

    `/usr/sox-14.4.2/bin/sox -m #{filenames_string}#{songname}.wav`

    `s3cmd put -f --acl-public #{songname}.wav s3://stemden/audio/mixes/#{songname}.wav`
    `rm -rf ./process/*`

    sampinfo = {name: songname, category: 'mixes', userid: userid, url: "http://s3.amazonaws.com/stemden/audio/mixes/#{songname}.wav"}

    SampleMaker.perform_async(sampinfo: sampinfo)
  end
end


