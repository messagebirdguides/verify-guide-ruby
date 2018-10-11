require 'dotenv'
require 'sinatra'
require 'messagebird'

set :root, File.dirname(__FILE__)
Dotenv.load if Sinatra::Base.development?

client = MessageBird::Client.new(ENV['MESSAGEBIRD_API_KEY'])

get '/' do
  erb :step1, locals: { errors: nil }
end

post '/step2' do
  number = params['number']
  otp = nil

  begin
    otp = client.verify_create(
      number,
      reference: 'MessageBirdReference',
      originator: 'Code',
      template: 'Your verification code is %token.'
    )
  rescue MessageBird::ErrorException => ex
    errors = ex.errors.each_with_object([]) do |error, memo|
      memo << "Error code #{error.code}: #{error.description}"
    end.join("\n")
    return erb :step1, locals: { errors: errors }
  end

  erb :step2, locals: { otp_id: otp.id, errors: nil }
end

post '/step3' do
  id = params[:id]
  token = params[:token]

  begin
    client.verify_token(id, token)
  rescue MessageBird::ErrorException => ex
    errors = ex.errors.each_with_object([]) do |error, memo|
      memo << "Error code #{error.code}: #{error.description}"
    end.join("\n")
    return erb :step2, locals: { otp_id: nil, errors: errors }
  end

  erb :step3, locals: { errors: nil }
end
