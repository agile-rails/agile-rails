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

##########################################################################
# == Schema information
#
# Table name: ar_big_table : Big Table
#
#  id                 Integer           id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  key                  String               Key (ident) used to retrieve key/values
#  description          String               description
#  site_id              Integer       Data will be used only for defined site. If empty, then it is default for all sites in database.
#  active               Boolean     This key is active
#  created_by           Integer       created_by
#  updated_by           Integer       updated_by
#  ar_big_table_values  Embedded: ArBigTableValue Values defined by this key
#   
# Big table is meant to be a common space for defining default choices for select fields on forms. 
# Documents are organized as key-value pair with the difference that values for the key can 
# be defined for each site and can also be localized.
# 
# Usage (as used in forms):
# 
# In the example administrator may help user by providing values that can be used 
# on ArAd document position field by defining them in ads-position key of big table.
# Example is from ar_ads.yml form.
# 
#    10:
#      name: position
#      type: text_with_select
#      eval: ar_big_table 'ads-positions'
#      size: 20
#        
##########################################################################
class ArBigTable < ApplicationRecord

has_many :ar_big_table_values

validates :key,         presence: true
validates :description, presence: true

########################################################################
# Will return possible choices for specified key prepared for usage in select input field.
########################################################################
def self.choices_for(key, site = nil, locale = nil)
  result = []
  data = find_by(key: key, site_id: site)
  data ||= find_by(key: key, site_id: nil) if site
  if data
    data.ar_big_table_values.order(description: 'asc').each do |one_value|
      next unless one_value.active

      description = one_value.get_localized_description(locale)
      result << [description, one_value.value]
    end
  end
  result.empty? ? [nil] : result
end

end
