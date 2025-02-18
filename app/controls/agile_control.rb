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
# Common controls for Agile controller
######################################################################
module AgileControl

######################################################################
# Clear current form filter
######################################################################
def filter_off
  table_name = AgileHelper.table_param(params).strip.split(';').first.underscore
  save_filter_value(nil, table_name, :filter)
  save_filter_value(1, table_name, :page)
  url = url_for(controller: :agile, t: table_name, f: AgileHelper.form_param(params))

  render json: { url: url }
end

######################################################################
# Set current filter for table
######################################################################
def filter_on
  table_name = AgileHelper.table_param(params).strip.split(';').first.underscore
  save_filter_value(1, table_name, :page)
  set_session_filter(table_name)
  url = url_for(controller: :agile, table: table_name, form_name: AgileHelper.form_param(params))
  respond_to do |format|
    format.json { render json: { url: url } }
    format.html { redirect_to url }
  end

end

########################################################################
# Will check and set sorting options for current dataset. Subroutine of index method.
########################################################################
def sort
  return if params['sort'].nil?

  table_name = AgileHelper.table_param(params).strip.split(';').first.underscore
  old_sort = session.dig(:filters, table_name, :sort).to_s
  sort, direction = old_sort.split(' ')
  # reverse sort if same selected
  direction = direction == 'asc' ? 'desc' : 'asc' if params['sort'] == sort
  direction ||= 'asc'
  save_filter_value("#{params[:sort]} #{direction}", table_name, :sort)
  save_filter_value(1, table_name, :page)

  params['sort'] = nil # otherwise there is problem with other links
  url = url_for(controller: :agile, t: table_name, f: AgileHelper.form_param(params))

  render json: { url: url }
end

private
########################################################################
# Will set session[table_name]['filter'] and save last filter settings to session.
# subroutine of check_filter_options.
########################################################################
def set_session_filter(table_name)
  # models that can not be filtered (for now)
  return if table_name.in?(%w[(ar_temp ar_memory])
  # field_name should exist on set filter condition
  return if params[:filter_oper] && params[:filter_field].blank? && params[:filter_value].blank?

  filter_value = if params[:filter_value].blank?
                   '#NIL' # #NIL indicates that no filtering is needed
                 elsif params[:filter_value].to_s[0] == '@'
                   # Internal value. Remove leading @ and evaluate expression
                   expression = ArInternals.get(params[:filter_value])
                     eval(expression) rescue 'Error!'
                 else
                   params[:filter_value]
                 end
  if params[:filter_oper] == 'eval'
    save_filter_value({ table: table_name, operation: 'eval', value: params[:filter_value] }, table_name, :filter)
  # if filter field parameter is omitted then just set filter value
  elsif params[:filter_field].nil?
    save_filter_value(filter_value, table_name, :filter, :value)
  else
    # as field defined. Split name and alternative input field
    field = if params[:filter_field].match(' as ')
              params[:filter_input] = params[:filter_field].split(' as ').last.strip
              params[:filter_field].split(' as ').first.strip
            else
              params[:filter_field]
            end
    new_filter = { field: field, operation: params[:filter_oper], value: filter_value, input: params[:filter_input], table: table_name }
    save_filter_value(new_filter, table_name, :filter)
  end
  # must be. Otherwise, kaminari includes params on paging links
  params[:filter_id]     = nil
  params[:filter_oper]   = nil
  params[:filter_input]  = nil
  params[:filter_field]  = nil
end

end
