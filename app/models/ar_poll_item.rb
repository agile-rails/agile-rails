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
# Table name: ar_poll_item : Poll items define entry fields on poll questionary and formulars.
#
#  id                 Integer         id
#  created_at           Time        created_at
#  updated_at           Time        updated_at
#  name                 String      Name (alias) of returned field name
#  text                 String      Caption of item
#  field_type           String      Input field type
#  size                 String      size
#  mandatory            Boolean     Item entry is mandatory
#  separator            String      Separator between items
#  options              String      Options for the item. Depends on item type.
#  order                Integer     Order of item on poll
#  active               Boolean     Item is active
# 
########################################################################
class ArPollItem < ApplicationRecord
  validates_length_of :name, minimum: 3

  belongs_to :ar_poll
end
