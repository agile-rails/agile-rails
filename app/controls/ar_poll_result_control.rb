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
# AgileRails controls for ArPollResult model.
######################################################################
module ArPollResultControl

######################################################################
# Default data_set filter
######################################################################
def default_filter
  get_query
end

######################################################################
# Filter action called. Update url to reflect filter conditions and reload form.
######################################################################
def set_filter
  url = url_for(controller: :agile, action: :index, table: :ar_poll_result,
                'record[poll_id]' => params[:record][:poll_id],
                'record[start_date]' => params[:record][:start_date],
                'record[end_date]' => params[:record][:end_date])
  render json: { url: url }
end

######################################################################
# Export data to CSV file.
######################################################################
def do_export
  c, keys = '', []
  get_query.to_a.each do |doc|
    # ensure, that fields are always in same order
    data = YAML.load(doc.data)
    if c.blank?
      data.each { |k, v| keys << k }
      c += "#{I18n.t('helpers.label.ar_poll_result.created_at')}\t"
      c += "#{keys.join("\t")}\n"
    end
    c += "#{doc.created_at.strftime(I18n.t('date.formats.default'))}\t"
    keys.each { |k| c += "#{data[k]}\t" }
    c += "\n"
  end
  File.write(Rails.root.join('public','export.csv'), c)
  render json: { window: 'export.csv' } # will download file
end

private
######################################################################
# Creates query for Poll results
######################################################################
def get_query
  return ArPollResult.all if params[:record].blank? # initial call

  start_date = (AgileFormFields::DatePicker.get_data(params,'start_date') || Time.now).beginning_of_day
  end_date   = (AgileFormFields::DatePicker.get_data(params,'end_date') || start_date).end_of_day
  poll_id    = params.dig(:record, :poll_id)
  qry = ArPollResult.where('created_at >= ? and created_at <= ?', start_date, end_date)
  return qry if poll_id.nil?

  qry.where(ar_poll_id: poll_id)
end

end
