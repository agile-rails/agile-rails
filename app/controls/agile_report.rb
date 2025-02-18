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
# Common methods required by reports
######################################################################
module AgileReport
attr_accessor :report_id, :bulk

######################################################################
# Clear data unless params[:clear] is 'no'
######################################################################
def new_record
  ArTemp.clear(temp_key) unless params[:clear].to_s == 'no'
end

######################################################################
# Will replace @form with @form['report'] if table=ar_temp.
# Will load agile_report_defaults if table=ar_memory and actions are not present.
######################################################################
def update_form
  agile_form_read if @form.nil?
  if AgileHelper.table_param(params) == 'ar_temp' && @form['report'].present?
    @form = @form['report']
  elsif AgileHelper.table_param(params) == 'ar_memory' && !AgileHelper.dont?(@form['defaults'])
    defaults = File.read(AgileHelper.form_file_find('agile_report_defaults'))
    defaults.gsub!('&report', AgileHelper.form_param(params))
    defaults = YAML.load(defaults) rescue nil
    return if defaults.nil?

    case @form['form']['actions'].class.to_s
    when 'NilClass'
    when 'Hash' then defaults = {}
    when 'String' # only print or export are specified
      if @form['form']['actions'] == 'print'
        defaults['form']['actions'].delete(30)
      elsif @form['form']['actions'] == 'export'
        defaults['form']['actions'].delete(20)
      end
    end
    @form.deep_merge!(defaults)
  end
end

######################################################################
# Print to PDF action
######################################################################
def print
  begin
    pdf_do
  rescue Exception => e
    Agile.dump_exception(e)
    render json: { msg_error: t('agile.runtime_error') } and return
  end

  pdf_file = "tmp/dokument-#{Time.now.to_i}.pdf"
  @pdf.render_file Rails.root.join('public', pdf_file)

  render json: print_response(pdf_file)
end

######################################################################
# Export data do excel action
######################################################################
def export
  export_to_excel(temp_key)
end

######################################################################
# Default filter to select data for result.
######################################################################
def data_filter
  params['clear'].to_s == 'yes' ? ArTemp.where(key: false) : ArTemp.where(key: temp_key).order(:order)
end

private

######################################################################
# Will create response message for print action. Response consists of
# opening pdf file in new browser tab and additional print_message if defined.
######################################################################
def print_response(pdf_file)
  response = { window: "/#{pdf_file}" }
  response.merge!(report_message) if respond_to?(:report_message, true)
  response
end

######################################################################
# Temp key consists of report name and user's id. Key should be added
# to every ar_temp document and is used to define data, which belongs
# to current user.
######################################################################
def temp_key
  "#{@report_id}-#{session[:user_id]}"
end

######################################################################
# Initialize report. Set report_id internal variable and initialize bulk
# for bulk saving data to ar_temp table.
######################################################################
def report_init(id)
  @report_id = id
  @bulk = []
end

######################################################################
# Check if all send fields are blank.
######################################################################
def all_blank?(*fields)
  fields.each { _1.blank? ? true : (break false) }
end

######################################################################
# Clears report data
######################################################################
def clear_data
  ArTemp.clear(temp_key)
end

######################################################################
# Will write data in bulks to ar_temp collection.
######################################################################
def write(data)
  the_end = data.nil? || data[:end]
  @bulk << data unless the_end && data.size < 2

  if (the_end && @bulk.size > 0) || @bulk.size > 100
    ArTemp.insert_all(
      @bulk.map { |e| { 'key' => temp_key, 'data' => e.stringify_keys.to_yaml, 'order' => e[:order] } }
    )
    @bulk = []
  end
end

######################################################################
# Export data to Excel
######################################################################
def export_to_excel(report_id)
  agile_form_read if @form.blank?
  # use report options if present
  columns = (@form['report'] || @form)['index']['data_set']['columns'].sort

  n, workbook = 0, Spreadsheet::Workbook.new
  excel = workbook.create_worksheet(name: report_id)
  # header
  columns.each_with_index do |column, i|
    caption = column.last['caption'] || column.last['label']
    label = t(caption)
    excel[n, i] = label.match(/translation missing/i) ? caption : label
  end

  data_filter.each do |doc|
    n += 1
    columns.each_with_index do |column, i|
      value = doc[column.last['name']].to_s.gsub('<br>', ";")
      value = value.gsub(/\<\/strong\>|\<strong\>|\<\/b\>|\<b\>/, '')
      excel[n, i] = value
    end
  end
  file_name = "#{report_id}-#{Time.now.to_i}.xls"
  workbook.write Rails.root.join('public', 'tmp', file_name)
  agile_render_ajax(operation: :window, value: "/tmp/#{file_name}")
end

############################################################################
# Returns html code for displaying date/time formatted by strftime. Will return '' if value is nil.
# 
# Parameters:
# [value] Date/DateTime/Time.  
# [format] String. strftime format mask. Defaults to locale's default format.
############################################################################
def agile_format_date_time(value, format = nil)
  return '' if value.nil?

  format ||= value.instance_of?(Date) ? t('date.formats.default') : t('time.formats.default')
  value.strftime(format)
end

##############################################################################
# Initialize PDF document.
#
# @opts [Hash] : PDF creation options
#
# Some default options are:
#   :font_size (10)
#   :margin [30,30,30,30]
#   :page_size 'A4'
#   :font %w[Arial arial.ttf arialbd.ttf]
##############################################################################
def pdf_init(opts = {})
  default_pdf_options(opts, :font_size, 10)
  default_pdf_options(opts, :margin, [30, 30, 30, 30])
  default_pdf_options(opts, :page_size, 'A4')
  default_pdf_options(opts, :min_version, 1.7)

  @pdf = Prawn::Document.new(opts)
  @pdf.font_size = opts[:font_size]

  @pdf.encrypt_document(owner_password: :random,
                        permissions: { print_document: true,
                                       modify_contents: false,
                                       copy_contents: false,
                                       modify_annotations: false })
  params[:font] ||= %w[Arial arial.ttf arialbd.ttf]
  @pdf.font_families.update(
    params[:font][0] => { normal: Rails.root.join('public', params[:font][1]),
                          bold: Rails.root.join('public', params[:font][2]) }
  )
  @pdf.font(params[:font][0])
  @pdf.renderer.min_version(opts[:min_version])
end

################################################################################
# Sets default pdf creation options whether from initial call or from form's print options.
###############################################################################
def default_pdf_options(opts, option, default)
  form_value = @form.dig('print', option.to_s)
  @form['print'].delete(option.to_s) if form_value
  opts[option] ||= form_value || default
end

################################################################################
# Prepares pdf default header from form definition
#
# Example if overwritten in report control file:
#   @table = %w[caption1 caption\ 2 caption\ 3 .......]
###############################################################################
def pdf_header
  pdf_head if defined?(:pdf_head)
  return if @table

  tab = []
  @form['print'].select{ |k, v| k.is_a?(Integer) }.sort { |a, b| a.first <=> b.first }.each do |k, v|
    tab << if v['caption']
             AgileHelper.t(v['caption'], v['caption'])
           else
             v['name'].capitalize
           end
  end
  @table = [tab]
end

################################################################################
# Reads report data and adds fields defined on form to @table array.
#
# Example if overwritten in report control file:
#   @table += data_filter.map { |e| [e.field1, e.field3, e.field3 ....] }
###############################################################################
def pdf_data
  keys = @form['print'].select{ |k, v| k.is_a?(Integer)}.sort { |a, b| a.first <=> b.first }.map{ |k, v| v['name'] }
  @table += data_filter.map do |rec|
    keys.map{ |key| rec[key] }
  end
end

################################################################################
# Prepare pdf report
#
# Any of those methods can be overwritten in report control file.
#   pdf_init
#   pdf_header
#   pdf_data
#   pdf_render
################################################################################
def pdf_do
  pdf_init
  pdf_header
  pdf_data
  pdf_render
end

################################################################################
# Renders table data
#
# Example if overwritten in report control file:
#   @pdf.table(@table, header: true, cell_style: { padding: [2, 2, 2, 2], align: :left, border_width: 0.5 }) do
#     column(0).style width: 80
#     column(1).style width: 50
#     column(3).style width: 35, align: :right
#   end
###############################################################################
def pdf_render
  opts = {}
  default_pdf_options(opts, 'header', true)
  header_style = @form['print'].delete('header_style')

  @form['print'].select{ |k, v| k.is_a?(String)}.each do |option, value|
    if option.is_a?(Hash)
      @form['print'][option].each do |k, v|
        opts[option] ||= {}
        opts[option][k] = v
      end
    else
      opts[option] = value
    end
  end

  print = @form['print'] # @form is nil inside table do loop  ????
  @pdf.table(@table, opts) do
    #@TODO Find out how different styles can be defined for print header
    #if header_style
       #_opts = {}
       #header_style.each { |k, v| _opts[k.to_sym] = v }
       #   row(0).style(opts)
    #  header_style.each { |k, v| row(0).send(k.to_sym, v) }
    #end

    print.select{ |k, v| k.is_a?(Integer)}.sort{ |a, b| a.first <=> b.first }.each_with_index do |data, i|
      options = data.last
      next unless options['style']

      _opts = {}
      options['style'].each { |k, v| _opts[k.to_sym] = v }
      column(i).style(_opts)
    end
  end
end

################################################################################
# Prints out single text (or object) on report.
#
# @param [Object] txt : Text or object. Result of to_s method of the object is
# @param [Hash] opts
###############################################################################
def pdf_text(txt, opts = {})
  box_opts = opts.dup
  ypos = @pdf.cursor
  xpos = opts.delete(:atx) || 0
  box_opts[:single_line] ||= true
  box_opts[:at] ||= [xpos, ypos]

  @pdf.text_box(txt.to_s, box_opts)
end

################################################################################
# Skip line on report
#
# @param [Integer] skip . Number of lines to skip. Default 1.
###############################################################################
def pdf_skip(skip = 1)
  @pdf.text('<br>' * skip, inline_format: true)
end

end
