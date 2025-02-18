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
# Implementation of journal_diff AgileRails form field. journal_diff field is used to 
# show differences between two fields in ArJournal collection.
#
# Internal use.
#
# ===Form options:
# * +name:+ field name (required)
# * +type:+ journal_diff (required)
# 
# Form example:
#    10:
#      name: diff
#      type: journal_diff
#      html:
#        size: 100x25
###########################################################################
class JournalDiff < AgileFormField

###########################################################################
# Render journal_diff AgileRails form field code
###########################################################################
def render 
  @yaml['name'] = 'old' if @record[@yaml['name']].nil?
  @html += '<div class="ar-journal">'
  JSON.parse(@record[@yaml['name']]).each do |k, v|
    old_value = v.class == Array ? v[0] : v
    new_value = v.class == Array ? v[1] : v
    @html += %(<div class="field">#{@env.check_box('select', k)} #{k}</div>
               <div class="diff-m">#{@env.mi_icon('remove red')}<div>#{old_value}</div></div>
               <div class="diff-p">#{@env.mi_icon('add green')}<div>#{new_value}</div></div>)
  end
  @html += '</div>'
  self
end
end

end
