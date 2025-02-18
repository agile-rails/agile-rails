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
# Table name: ar_poll : Polls
#
#  id                 Integer           id
#  created_at           Time          created_at
#  updated_at           Time          updated_at
#  name                 String        Unique poll name
#  title                String        Title for the poll
#  sub_text             String        Short description of the poll
#  pre_display          String        pre_display
#  operation            String        Operation performed on submit
#  parameters           String        Aditional parameters for operation
#  display              String        Select how fields are positioned on form
#  css                  String        CSS specific to this poll
#  form                 String        You can specified input items by providing form acording to rules of AgileRails form.
#  valid_from           DateTime      Pole is valid from
#  valid_to             DateTime      Pole is valid to
#  captcha_type         String        Catpcha type name if captcha is used
#  active               Boolean       active
#  created_by           Integer       created_by
#  updated_by           Integer       updated_by
#
# ArPoll documents are used for different questionaries and formulars which can
# be accessed independent or connected with ArPage documents. Entry fields can be defined
# in related ar_poll_items table or as AgileRails form YAML style entered into form field.
########################################################################
class ArPoll < ApplicationRecord
  
has_many :ar_poll_items

########################################################################
# Save poll results to ArPollResults table
# 
# Params:
# data : Hash : Records hash (params[:record])
########################################################################
def save_results(data)
  h = {}
  items = form.blank? ? ArPollItem.where(ar_poll_id: id) : YAML.load(self.form.gsub('&nbsp;', ' '))
  items.each do |item|
    next if %w(hidden_field submit_tag link_to comment).include?(item.field_type) # ignore
    next if item.try(:options).match('hidden') # also ignore

    h[ item['name'] ] = data[ item['name'] ]
  end
  ArPollResult.create(ar_poll_id: id, data: h.to_yaml)
end    
    
end
