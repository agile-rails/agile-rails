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

######################################################################
# Controls for ArMenuItem Form field.
######################################################################
module ArMenuItemControl

######################################################################
# Default filter for selecting menu items records
######################################################################
def default_filter
  ArMenuItem.where(ar_menu_id: ids().first, parent_id: ids().last).order(:order)
end

######################################################################
# Called when new empty record is created
######################################################################
def new_record
  @record.ar_menu_id = ids().first
  @record.parent_id  = ids().last
end

private

######################################################################
# Split ids parameter into array
######################################################################
def ids
  ids = params[:ids].split(';')
  ids << 0 if ids.size == 1
  ids
end

end
