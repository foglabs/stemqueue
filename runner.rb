require 'aws-sdk'
require 'active_record'
require 'pg'
require 'fog/aws'
require 'fog'
require 'carrierwave'
require 'carrierwave/orm/activerecord'
require 'carrierwave/storage/fog'

require './uploaders/specimen_uploader'
# require './initializers/carrierwave'
require './models/sample'
require './models/song'
require './models/song_sample'
require './models/user'


CarrierWave.configure do |config|
  config.fog_provider = 'fog/aws' 
  config.fog_directory  = ENV['S3_BUCKET']                                 # required
  config.fog_credentials = {
    provider: 'AWS',                                                       # required
    aws_access_key_id: ENV['S3_ACCESS'],
    aws_secret_access_key: ENV['S3_SECRET'],                   # required
    region: 'us-east-1'
  }

end

ActiveRecord::Base.establish_connection(:adapter => "postgresql",
                                        :username => "oraudijrhpytsu",
                                        :password => "uq1SLbMPJBu1W5B8E63vGp5rrX",
                                        :host => "ec2-54-235-254-56.compute-1.amazonaws.com",
                                        :database => "d82nlgrl4gfqdc")

def eat_queue(logger, item)
  case item['type']
    # when 'sample'
    #   puts "SAMPLE: #{item}"
    #   s=Sample.makesample(item)
    #   puts "CREATED: #{s}"
    when 'mix'
      logger.info "MIX: #{item}"    
      m=Song.mix(logger, item['songid'])
      logger.info "CREATED MIX: #{m}"
  else
    logger.info "type not found"
  end
end

if __FILE__ == $0

  logger = Logger.new("/home/ec2-user/run.log", 'daily')

  Aws.config.update({
    region: 'us-east-1',
    credentials: Aws::Credentials.new(ENV['SQS_ACCESS'], ENV['SQS_SECRET'])
  })

  sqs_client = Aws::SQS::Client.new
  queue = sqs_client.get_queue_url( { :queue_name => 'stemqueue' } )
  logger.info "Q-Com Online"
  # counter = 50

  while true
    # if counter <= 0
    #   logger.info "Byebye Queue at #{Time.now}"
    #   exit
    # end

    response = sqs_client.receive_message( { :queue_url => queue.queue_url, :max_number_of_messages => 10, :visibility_timeout => 3600 } )

    if response and response.messages.count > 0
      response.messages.each do | message |

        logger.info "Eating  #{message.body}"
        qitem = JSON.parse( message.body )
        
        begin
          eat_queue( logger, qitem )
        rescue Exception => e
          logger.error "Fuck! Exception: #{e} bt: #{e.backtrace}"
        end

        sqs_client.delete_message( {:queue_url => queue.queue_url, :receipt_handle => message.receipt_handle } )

        # counter -= 1
      end
    else
      # sleep(120)
    end
  end
end