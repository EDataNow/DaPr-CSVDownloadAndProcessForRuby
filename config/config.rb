require 'aws-sdk'
require 'csv'
require 'ostruct'

csv = CSV.new(File.read(Dir.glob("../config.csv").first), :headers => true, :header_converters => :symbol, :converters => :all)
@config = OpenStruct.new(csv.to_a.map {|row| row.to_hash }.first)

Aws.config.update({
  credentials: Aws::Credentials.new(@config.access_key_id, @config.secret_access_key),
  region: @config.region
})

@config.processor ||= File.expand_path("./db_store.rb")