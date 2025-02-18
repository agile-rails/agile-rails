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
# Controls for belongs_to AgileRails Form field.
######################################################################
module BelongsToControl

######################################################################
# Default filter for selecting related records
######################################################################
def default_filter
  model = @tables.last[0]
  return YAML.load(@record[params[:belongs_to]]) if model == 'ar_memory'

  if model.column_names.include? 'parent_type'
    model.where(parent_type: @tables.first[0].to_s, parent_id: params[:ids])
  else
    parent_table_index = @tables.size - 2
    belongs_to_field = "#{(params[:belongs_to] || @tables[parent_table_index][1])}_id"
    ids = params[:ids].split(';')
    model.where(belongs_to_field => ids[parent_table_index])
  end
end

######################################################################
# Before save, set required fields
######################################################################
def before_save
  if @record.respond_to?(:parent_type)
    @record.parent_type = @tables.first[0].to_s
    @record.parent_id   = params[:ids]
  else
    parent_table_index = @tables.size - 2
    belongs_to_field = "#{params[:belongs_to] || @tables[parent_table_index][1]}_id="
    ids = params[:ids].split(';')
    @record.send(belongs_to_field, ids[parent_table_index])
  end
end

end
