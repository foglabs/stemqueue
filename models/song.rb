class Song < ActiveRecord::Base
  has_many :song_samples
  has_many :samples, through: :song_samples
  belongs_to :user

  validates :name, presence: true
  validates :user, presence: true

  def get_urls
    samp_rate = srate ? srate : 44100
    urls = {samps: [], userid: user.id, songid: id, srate: samp_rate}

    song_samples.each do |songsamp|
      urls[:samps] << {link: songsamp.sample.specimen.url.gsub(/\A(\w|\W)*audio\//, ""), gain: songsamp.gain}
    end

    urls
  end

  def self.scrub_fname(filename)
    # Split the name when finding a period which is preceded by some
    # character, and is followed by some character other than a period,
    # if there is no following period that is followed by something
    # other than a period (yeah, confusing, I know)
    fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

    # We now have one or two parts (depending on whether we could find
    # a suitable period). For each of these parts, replace any unwanted
    # sequence of characters with an underscore
    fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

    # Finally, join the parts with a period and return the result
    return fn.join '.'
  end

  def self.mix(logger, songid)
    #last value of songinfo array is output name!
    # second to last is user id of song
    songo = Song.find(songid)
    songname = Song.scrub_fname(songo.name)

    songinfo = songo.get_urls
    srate = songinfo[:srate]
    userid = songinfo[:userid]

    filenames_string = ""
    counter = 0

    files = songinfo[:samps]

    files.each do |stemhash|
      # download the boy to the local folder

      stemhash[:filename_noex] = stemhash[:link].match(/\/(.*)\.{1}/)[1]
      stemhash[:filename_ex] = stemhash[:link].match(/\/(.*\z)/)[1]
      `s3cmd get s3://stemden/audio/#{stemhash[:link]} ./process/#{filename_ex}`
      stemhash[:srate] = `sox --i -r ./process/#{filename_ex}`

      if stemhash[:srate] != srate
        `sox ./process/#{stemhash[:filename_ex]} -r #{srate.to_i} ./process/rated-#{stemhash[:filename_ex]}`
        stemhash[:filename_ex] = "rated-#{stemhash[:filename_ex]}"
      end

      `mv ./process/#{stemhash[:filename_ex]} ./process/#{counter.to_s + stemhash[:filename_ex]}`
      stemhash[:filename_ex] = "#{counter.to_s + stemhash[:filename_ex]}"

      filenames_string += "-v #{stemhash[:gain] || 0} #{stemhash[:filename_ex]} "
      counter += 1
    end

    # mix them shits
    soxstring = "-m #{filenames_string}#{songname}.wav"
    logger.info "Mixing #{soxstring}"
    `/usr/sox-14.4.2/bin/sox #{soxstring}`

    # upload them shits
    `s3cmd put -f --acl-public #{songname}.wav s3://stemden/audio/mixes/#{songname}.wav`
    `rm -rf ./process/*`

    sampinfo = {name: songname, category: 'mixes', userid: userid, url: "http://s3.amazonaws.com/stemden/audio/mixes/#{songname}.wav"}
    # SampleMaker.perform_async(sampinfo: sampinfo)
    Sample.create(user_id: sampinfo[:userid], name: sampinfo[:name], category: sampinfo[:category], remote_specimen_url: sampinfo[:url])
  end
end
