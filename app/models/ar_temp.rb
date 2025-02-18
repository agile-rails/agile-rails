#--
# Copyright (c) 2024+ Damjan Rems
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#+

########################################################################
# == Schema information
#
# Table name: ar_temp : Table used for temporary data saving.
# 
# ar_temp table has three important fields:
#   key: String
#   data: String containing data set saved as yaml
#   order: String holding value to be osed for sorting selected refords
########################################################################
class ArTemp < ApplicationRecord

after_initialize do |record|
  @internals = YAML.unsafe_load(record.data.to_s) rescue {}
end

before_save do
  self.data = @internals.to_yaml
end

########################################################################
# Initilize object
########################################################################
def initialize(attributes = nil)
  super()
  @internals  = {}
  attributes  = attributes.nil? ? {} : attributes.stringify_keys
  self.key    = attributes.delete('key')  if attributes['key']
  self.active = attributes.delete('active') if attributes['active']
  self.order  = attributes.delete('order') if attributes['order']
  attributes.each { |k, v| @internals[k.to_s] = v }
end

########################################################################
# Respond_to should always return true.
########################################################################
def respond_to?(a = nil, b = nil)
  true
end

########################################################################
# Redefine send method. Send is used to assign or access value
########################################################################
def send(field, value = nil)
  return super(field) if field.is_a? Symbol

  field = field.to_s
  if field.match('=')
    field.chomp!('=')
    @internals[field] = value
  else
    @internals[field]
  end
end

########################################################################
# Redefine [] method to act similar as send method
########################################################################
def [](field)
  @internals[field.to_s]
end

########################################################################
# Redefine [] method to act similar as send method
########################################################################
def []=(field, value)
  @internals[field.to_s] = value
end

########################################################################
# Convert internal data to yaml
########################################################################
def to_yaml
  @internals.to_yaml
end

########################################################################
# For debugging
########################################################################
def to_s
  "ArTemp: @key=#{key} @data=#{data}"
end
  
########################################################################
# Method missing will return value if value defined by m parameter is saved to
# @internals array or will save field value to @internals hash if m matches '='.
########################################################################
def method_missing(m, *args, &block) #:nodoc:
  m = m.to_s
  return @internals[m] unless m.match('=')

  m.chomp!('=')
  @internals[m] = args.first
end

########################################################################
# Remove all documents with specified key from ar_temp table
########################################################################
def self.clear(key)
  where(key: key).delete_all
end

########################################################################
# Prepare ar_temp for data. It first checks if data associated with the key is to
# be deleted and then yields block code. 
# 
# Returns: Query for the data associated with the key
########################################################################
def self.prepare(key:, clear: nil)
  unless %w(no false 0).include?(clear.to_s.strip.downcase)
    clear(key)
    yield
  end
  where(key: key)
end

########################################################################
# Order data by new key. Will update order field with values from new field
########################################################################
def self.reorder_by(key, *new_order)
  where(key: key).each do |record|
    record.order = new_order.map(&:to_s).join('')
    record.save
  end
end

end
