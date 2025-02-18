ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
#require "fileutils"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end


ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
end

###################################################################################33
# Load initial data from test-template.yaml
###################################################################################33
def test_data_load
  data = YAML.unsafe_load_file( File.expand_path('../fixtures/test-template.yaml', __FILE__))
  data.each do |model_name, records|
    model = model_name.classify.constantize
    model.delete_all
    records.each do |record|
      new_record = model.new
      record.each { |field_name, value| new_record[field_name] = value }
      new_record.save
    end
  end
end

def logger
  Rails.logger
end

test_data_load

