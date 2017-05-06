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

    # check for existing filename
    checknames = Sample.where("name LIKE ?", "%#{songname}%").all.to_a
    last = checknames.sort_by! {|s| s.name[-1].to_i }.last

    if last

      logger.info "Found existing sample with #{songname}!"
      iteration = last.name.match(/_\d\z/)

      if iteration
        logger.info "Iteration found"
        songname = "#{songname}_#{(last.name[-1].to_i)+1}"
      else
        logger.info "none found"

        songname = "#{songname}_2"
      end

      logger.info "Name will be #{songname}..."
    end

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
      `s3cmd get s3://stemden/audio/#{stemhash[:link]} ./process/#{stemhash[:filename_ex]}`
      stemhash[:srate] = `/usr/sox-14.4.2/bin/sox --i -r ./process/#{stemhash[:filename_ex]}`.try(:to_i)

      if stemhash[:srate] != srate
        `/usr/sox-14.4.2/bin/sox ./process/#{stemhash[:filename_ex]} -r #{srate.to_i} ./process/ready-#{stemhash[:filename_ex]}`
      else        
        `/usr/sox-14.4.2/bin/sox ./process/#{stemhash[:filename_ex]} ./process/ready-#{stemhash[:filename_ex]}`
      end

      stemhash[:filename_ex] = "ready-#{stemhash[:filename_ex]}"

      `mv ./process/#{stemhash[:filename_ex]} ./process/#{counter.to_s + stemhash[:filename_ex]}`
      stemhash[:filename_ex] = "#{counter.to_s + stemhash[:filename_ex]}"

      logger.info "This sample right der #{stemhash.inspect}"

      filenames_string += "-v #{stemhash[:gain] || 1} ./process/#{stemhash[:filename_ex]} "
      counter += 1
    end

    # mix them shits
    soxstring = "-m #{filenames_string} ./process/#{songname}.wav"
    logger.info "Mixing #{soxstring}"
    `/usr/sox-14.4.2/bin/sox #{soxstring}`

    # upload them shits
    # `s3cmd put -f --acl-public #{songname}.wav s3://stemden/audio/mixes/#{songname}.wav`

    sampinfo = {name: songname, category: 'mixes', userid: userid, url: "http://s3.amazonaws.com/stemden/audio/mixes/#{songname}.wav"}
    sample = Sample.new(user_id: sampinfo[:userid], name: sampinfo[:name], category: sampinfo[:category])

    uploader = SpecimenUploader.new
    File.open("./process/#{songname}.wav") do |file|
      sample.specimen = file
    end

    
    sample.save
    `rm -rf ./process/*`
    logger.info "Done with #{sample.id}"
    sample
  end
end
