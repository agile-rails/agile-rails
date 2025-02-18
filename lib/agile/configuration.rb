#--
# Copyright (c) 2023+ Damjan Rems
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

module Agile
class Configuration

def self.defaults
  default = {}
  # 1: new, 2: filter, 3: sort
  default[:index_standard_actions]   = { 1 => 'new',  3 => 'filter' }
  # 1: edit, 2: duplicate, 3: delete
  default[:dataset_standard_actions] = { 1 => 'edit', 3 => 'delete' }
  # 1: back, 2: save, 3: save&back, 4: refresh, 5: enable, 6:new
  default[:form_standard_actions]    = { 1 => 'cancel', 3 => 'save&back' }
  # top, bottom, both
  default[:default_actions_position] = 'top'
  # top, left
  default[:default_labels_position]  = 'left'
  default
end

end
end
