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
#++

##############################################################################
# ArSetup table is for settings, that are specific to the application,
# or part of application (gem). It consists of data definitions and form for editing the data.
# Data is saved internally in YAML format.
#
# When editing, admin can see and edit form definition (adding new fields to application setup), while user
# sees only data entry form.
#
# Usage:
#   my_app_settings = ArSetup.find_by(name: 'my_app')
#   my_app_settings = ArSetup.get('my_app')
#   company = my_app_settings.company_name
#   company, ceo = my_app_settings[:company_name, 'ceo_name']
#
##############################################################################
class ArSetup < ApplicationRecord

attr_reader :my_data, :my_fields

validates_length_of :name, minimum: 3

before_save do
  self.data = my_data.to_yaml
end

##############################################################################
# Will return editors var as array to the application. Editors are internaly saved
# as string separated by comma.
##############################################################################
def editors
  edit_ids.to_s.split(',').map(&:to_i)
end

##############################################################################
# Will return editors var as array to the application. Editors are internaly saved
# as string separated by comma.
##############################################################################
def editors=(value)
  self.edit_ids = value.join(',')
end

##############################################################################
# Will return settings record for specified application.
#
# @param [String] app_name The name of the application
# @return [Object, nil] The settings record if found, nil otherwise
##############################################################################
def self.get(app_name)
  ArSetup.find_by(name: app_name.to_s)
end

##############################################################################
# Will return value for single setting if called as method.
##############################################################################
def method_missing(m, *args, &block)
  m = m.to_s
  if m.match('=')
    m.chomp!('=')
    my_data[m] = args.first
  else
    my_data[m]
  end
end

##############################################################################
# Will return value for single setting. Called as parameter in square brackets.
# If more then one parameter is passed it will return them as array.
##############################################################################
def [](*keys)
  return my_data[keys.first.to_s] if keys.size == 1

  keys.map { |k| my_data[k.to_s] }
end

##############################################################################
# Should always respond as true
##############################################################################
def respond_to?(field_name)
  true
end

##############################################################################
#
##############################################################################
def my_data
  @my_data ||= (YAML.unsafe_load(data)) rescue {}
end

end
