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
# Implementation of belongs_to AgileRails form field.
# belongs_to form field is used to edit records that are related to currently edited record.
#
# Related records are edited inside iframe.
#
# ===Form options:
# * +name:+ field name (required)
# * +type:+ belongs_to (required)
# * +form_name:+ name of form which will be used for editing
# * +load:+ when is embedded iframe loaded. default=on form load, delay=on tab select, always=every time tab is selected)
# * +belongs_to:+ optionaly define name of model, to which edited table is related
# * +html:+ html options (optional)
#   * +height:+ height of embedded object in pixels (1000)
#   * +width:+ width of embedded object in pixels (500)
# 
# Form example:
#    10:
#      name: ar_parts
#      type: belongs_to
#      form_name: ar_part
#      refresh: delay
#      belongs_to: ar_page
#      html:
#        height: 1000
###########################################################################
class BelongsTo < AgileFormField

###########################################################################
# Render belongs_to AgileRails form field code
###########################################################################
def render
  # some HTML5 defaults
  @yaml['html'] ||= {}
  @yaml['html']['width'] ||= '99%'

  @yaml['action'] ||= 'index'
  # defaults both way 
  @yaml['table']     ||= @yaml['form_name'] if @yaml['form_name']
  @yaml['form_name'] ||= @yaml['table'] if @yaml['table']

  if @yaml['name'] == @yaml['table'] || @yaml['table'] == 'ar_memory'
    tables = @yaml['table']
    ids    = @record.id
  else
    tables = @env.tables.inject('') { |r, v| r += "#{v[1]};" } + @yaml['table']
    ids    = (@env.ids.present? ? @env.ids.join(';') + ';' : '') + @record.id.to_s
  end
  # message when new record
  if @record.new_record? && tables != 'ar_temp'
    @yaml['html']['srcdoc'] = %(
<div style='font-family: helvetica; font-size: 1.7rem; font-weight: bold; color: #ddd; padding: 1rem'>
  #{I18n.t('agile.iframe_save_to_view')}
</div>)
  end
  html5 = @yaml['html'].map{ |k, v| %(#{k}="#{v}") }.join(' ')

  # edit enabled belong_to form on a readonly form
  readonly = AgileHelper.dont?(@yaml['readonly']) ? nil : @readonly
  opts = { controller: :agile, action: @yaml['action'],
           ids: ids, table: tables, form_name: @yaml['form_name'], 
           field_name: @yaml['name'], iframe: "if_#{@yaml['name']}", readonly: readonly }
  # additional parameters if specified
  @yaml['params'].each { |k, v| opts[k] = @env.agile_value_for_parameter(v) } if @yaml['params']
         
  @html += "<iframe class='iframe_embedded' id='if_#{@yaml['name']}' name='if_#{@yaml['name']}' #{html5}></iframe>"
  return self if @record.new_record? && tables != 'ar_temp'

  url  = @env.url_for(opts)
  attributes = case @yaml['load']
               when nil?, 'default'
                 "'src', '#{url}'"
               when 'delay'
                 "'data-src-#{@yaml['load']}', '#{url}'"
               else
                 "{'data-src-#{@yaml['load']}': '#{url}', src: '#{url}'}"
               end
  @js += %(
$(document).ready( function() {
  $('#if_#{@yaml['name']}').attr(#{attributes});
});)

  self
end

end

end
