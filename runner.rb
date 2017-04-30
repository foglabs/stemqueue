require 'activerecord'
require 'pg'
require 'aws-sdk'

ActiveRecord::Base.establish_connection(:adapter => "postgresql"
                                        :username => "oraudijrhpytsu",
                                        :password => "uq1SLbMPJBu1W5B8E63vGp5rrX",
                                        :host => "ec2-54-235-254-56.compute-1.amazonaws.com"
                                        :database => "d82nlgrl4gfqdc")

def eat_queue(logger, item)
  case item['type']

  when 'sample'
  
  when 'mix'
  
  else

  end


end

if __FILE__ == $0

  logger = Logger.new("/home/ec2-user/run.log", 'daily')

  AWS.config({ :access_key_id => ENV['SQS_ACCESS'],
               :secret_access_key => ENV['SQS_SECRET'] })

  sqs_client = AWS::SQS::Client.new
  queue = sqs_client.get_queue_url( { :queue_name => 'stemqueue' } )
  logger.info "Its ya boy Q"
  counter = 50

  while true
    if counter <= 0
      logger.info "Byebye Queue at #{Time.now}"
      exit
    end

    response = sqs_client.receive_message( { :queue_url => queue.queue_url, :max_number_of_messages => 10, :visibility_timeout => 3600 } )

    if response and response.messages.count > 0
      response.messages.each do | message |

        logger.info "Eating  #{message.body}"
        queue_item = JSON.parse( message.body )
        
        begin
          process_queue_item( logger, queue_item )
        rescue Exception => e
          logger.error "Fuck! Exception: #{e} bt: #{e.backtrace}"
        end

        sqs_client.delete_message( {:queue_url => queue.queue_url, :receipt_handle => message.receipt_handle } )

        counter -= 1
      end
    else
      sleep(120)
    end
  end
end