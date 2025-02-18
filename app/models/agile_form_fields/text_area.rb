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
module AgileFormFields

###########################################################################
# Implementation of text_area AgileRails form field.
# 
# ===Form options:
# * +type:+ text_area (required)
# * +name:+ Field name (required) 
# * +html:+ html options which apply to text_area field (optional)
# 
# Form example:
#    10:
#      name: css
#      type: text_area
#      size: 100x30
###########################################################################
class TextArea < AgileFormField

###########################################################################
# Return value for readonly field
###########################################################################
def ro_standard
  value = @record[@yaml['name']]
  @html += "<div class='ar-readonly'>#{value.gsub("\n",'<br>')}</div>" unless value.blank?
  self
end

###########################################################################
# Render text_area AgileRails form field code
###########################################################################
def render
  set_initial_value
  record = record_text_for(@yaml['name'])
  @html += @env.text_area(record, @yaml['name'], @yaml['html'])
  self
end

end
end
