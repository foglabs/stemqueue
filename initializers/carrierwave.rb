CarrierWave.configure do |config|
  config.fog_credentials = {
    provider: 'AWS',                                                       # required
    aws_access_key_id: ENV['S3_ACCESS'],
    aws_secret_access_key: ENV['S3_SECRET'],                   # required
    region: 'us-east-1'
  }
  config.fog_directory  = ENV['S3_BUCKET']                                 # required
end

# CarrierWave.configure do |config|
#   config.storage = :file
# end
