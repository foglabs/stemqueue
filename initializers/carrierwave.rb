# # if !Rails.env.test?
#   CarrierWave.configure do |config|
#     config.fog_credentials = {
#       provider: 'AWS',                                                       # required
#       aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
#       aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']                    # required
#     }
#     config.fog_directory  = ENV['S3_BUCKET']                                 # required
#   end
# # end

# if !Rails.env.test?
  CarrierWave.configure do |config|
    config.fog_credentials = {
      provider: 'AWS',                                                       # required
      aws_access_key_id: ENV['S3_ACCESS'],
      aws_secret_access_key: ENV['S3_SECRET']                   # required
    }
    config.fog_directory  = ENV['S3_BUCKET']                                 # required
  end
# end
