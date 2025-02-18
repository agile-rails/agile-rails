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

######################################################################
# Controls for agile_edit form
######################################################################
module AgileEditControl

######################################################################
# Fill in currently logged user.
######################################################################
def new_record
  @record.field3   = 'ReadOnly field 1'
  @record[:field4] = 'ReadOnly field 2'
  @record.field44  = Time.now.localtime.end_of_month
end

######################################################################
# Process submit 
######################################################################
def before_save
  @record[:result] = params['record'].inject('') do |r, field|
    r << "#{field}=#{params['record'][field]}\n"
  end
  flash[:info] = 'Data processed succesfully.'

  # save data, but return false because data would be normally saved to DB by
  # controller, which would result in error
  false
end

end 
