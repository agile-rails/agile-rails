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
# Implementation of select AgileRails form field.
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ select (required)
# * +choices:+ Values for choices separated by comma. Values can also be specified like description:value.
# In the example description will be shown to user, but value will be saved to document.
#    choices: 'OK:0,Ready:1,Error:2'
#    choices: Ruby,Pyton,PHP
# * +eval:+ Choices will be provided by evaluating expression
#   * eval: agile_choices_for('model_name','description_field_name','_id'); agile_choices_for helper will provide data for select field.
#   * eval: ModelName.choices_for_field; ModelName class will define method choices_for_field which 
#   will provide data for select field.
#   * collection_name.search_field_name.method_name; When searching is more complex custom search
#   method may be defined in CollectionName model which will provide dataset for search.
# * If choices or eval is not defined choices will be provided from translation helpers. For example: 
#   Collection has field status choices for field may be provided by en.helpers.model_name.choices_for_status 
#   entry of english translation. English is of course default translation. If you provide translations in
#   your local language then select choices will be localized.
#    en.helpers.model_name.choices_for_status: 'OK:0,Ready:1,Error:2'
#    sl.helpers.model_name.choices_for_status: 'V redu:0,Pripravljen:1,Napaka:2'
# * +depend:+ Select options may depend on a value in some other field. If depend option is specified
#   then chices must be provided by class method and defined in eval option.
# * +html:+ html options which apply to select field (optional)
#      
# Form example:
#    30:
#      name: type
#      type: select
#    40:
#      name: env
#      type: select
#      choices: eval ArCategory.values_for_env
#      include_blank: true
#    50:
#      name: company
#      type: select
#      choices: Audi,BMW,Mercedes
#        or
#      choices: helpers.label.model.choices_for_field
#    60:
#      name: type
#      type: select
#      choices:
#        eval: Cars.choices_for_type
#      depend: company
###########################################################################
class Select < AgileFormField
  
###########################################################################
# Choices are defined in locales as:
# lang.choices_for_tablename_fieldname: One,Two,Three
# or by default as
# lang:
#   helpers:
#     label:
#       table_name:
#         choices_for_fieldname: One:1, two:2
###########################################################################
def choices_in_locales(locales = nil)
  locales ||= "helpers.label.#{@form['table']}.choices_for_#{@yaml['name']}"
  c = t(locales)
  if c.match(/translation missing/i)
    locales = "choices_for_#{@form['table']}_#{@yaml['name']}"
    return "Error. Locale #{locales} not defined" if c.match(/translation missing/i)
  end
  c
end

###########################################################################
# Choices are defined by evaluating an expression. This is most common class
# method defined in a class. eg. SomeClass.get_choices_for
###########################################################################
def choices_in_eval(e)
  e = e.sub('eval ', '').strip
  method = e.split(/\ |\(/).first
  if @yaml['depend'].present?
    # add event listener to depend field(s)
    depend_value = ''
    @js += "\n$(document).ready(function() {\n"
    @yaml['depend'].split(',') do |depend|
      depend.strip!
      depend_value += ',' if depend_value.present?
      # depend field might be virtual field. It's value should be set in params
      depend_value += (depend[0] == '_' ? @env.params["p_#{depend}"] : @record[depend]).to_s
      next if depend == @yaml['name'] # self may be sent, but don't listen to change event

      @js += %(
$('#record_#{depend}').change( function(e) { update_select_depend('record_#{@yaml['name']}', '#{@yaml['depend']}', '#{e}');});
$('#_record_#{depend}').change( function(e) { update_select_depend('record_#{@yaml['name']}', '#{@yaml['depend']}', '#{e}');});
)
    end
    @js +=  + "});\n"
    e += " '#{depend_value}'"
  end

  return eval(e) if respond_to?(method) # is method defined here
  return eval("@env.#{e}") if @env.respond_to?(method) # is method defined in helper methods

  # eval whatever is there
  eval e
end

def choices_in_eval(e)

  e = e.sub('eval ', '').strip
  if @yaml['depend'].nil?
    method = e.split(/\ |\(/).first
    return eval(e) if respond_to?(method) # is method defined here
    return eval("@env.#{e}") if @env.respond_to?(method) # is method defined in helper methods
    # eval whatever it is there
    return eval e
  end

  # add event listener to depend field(s)
  depend_value = ''
  @js += "\n$(document).ready(function() {\n"
  @yaml['depend'].split(',') do |depend|
    depend.strip!
    depend_value += ',' if depend_value.present?
    # depend field might be virtual field. It's value should be set in params
    if depend[0] == '_'
      depend_value += @env.params["p_#{depend}"].to_s
    else
      next if @record.nil? # used as filter field

      depend_value += @record[depend].to_s
    end
    next if depend == @yaml['name'] # self may be sent, but don't listen to change event

    @js += %(
$('#record_#{depend}').change( function(e) { update_select_depend('record_#{@yaml['name']}', '#{@yaml['depend']}', '#{e}');});
$('#_record_#{depend}').change( function(e) { update_select_depend('record_#{@yaml['name']}', '#{@yaml['depend']}', '#{e}');});
)
  end
  @js += "});\n"
  e += " '#{depend_value}'"
  eval e
end

###########################################################################
# Get choices for select field.
###########################################################################
def get_choices
  begin
    choices = case @yaml['choices']
              when nil
                @yaml['eval'] ? choices_in_eval(@yaml['eval']) : choices_in_locales()
              when /^eval /i
                choices_in_eval(@yaml['choices'])
              when /^helpers/
                choices_in_locales(@yaml['choices'])
              else
                if @yaml['choices'].is_a?(String)
                  @yaml['choices']
                else
                  choices_in_eval(@yaml['choices']['eval'])
                end
              end
    return choices unless choices.is_a?(String)

    choices.chomp.split(',').map{ |e| e.match(':') ? e.split(':') : e }
  rescue Exception => e
    Rails.logger.debug "\nError in select eval. #{e.message}\n"
    Rails.logger.debug(e.backtrace.join($/)) if Rails.env.development?
    ['error'] # return empty array when error occures
  end
end

###########################################################################
# Will add code to view data record behind selected option in a popup window
###########################################################################
def add_view_code
  return '' if (data = @record.send(@yaml['name'])).blank?

  table, form_name = @yaml['view'].split(/[ ,]/).delete_if(&:blank?)
  url  = @env.url_for(controller: :agile, id: data, action: :edit, table: table, form_name: form_name, readonly: true, window_close: 1 )
  icon = @env.mi_icon('eye-o md-18')
  %(<span class="ar-window-open" data-url="#{url}"> #{icon}</span>)
end

###########################################################################
# Return value when readonly is required
###########################################################################
def ro_standard
  value = @record.respond_to?(@yaml['name']) ? @record.send(@yaml['name']) : nil
  return self if value.blank?

  html = ''
  choices = get_choices()
  if value.class == Array   # multiple choices
    value.each do |element|
      choices.each do |choice|
        if choice.to_s == element.to_s
          html += '<br>' if html.size > 0
          html += "#{element.to_s}"
        end
      end       
    end
  else
    choices.each do |choice|
      if choice.class == Array
        (html = choice.first; break) if choice.last.to_s == value.to_s
      else
        (html = choice; break) if choice.to_s == value.to_s
      end 
    end
    html += add_view_code if @yaml['view']
  end
  super(html)
end

###########################################################################
# Render select field html code
###########################################################################
def render
  return ro_standard if @readonly

  set_initial_value('html','selected')
  # options can be all around
  options = {}
  %w[selected include_blank].each do |key|
    options[key.to_sym] = (@yaml['html'].delete(key) if @yaml.dig('html', key)) ||
                          (@yaml['options'].delete(key) if @yaml.dig('options', key)) ||
                          (@yaml[key] if @yaml[key])
  end
  options.compact!
  @yaml['html']['multiple'] = true if @yaml['multiple']

  record = record_text_for(@yaml['name'])
  if @yaml['html']['multiple']
    @yaml['html']['class'] = "#{@yaml['html']['class']} select-multiple"
    @html += @env.select(record, @yaml['name'], get_choices, options, @yaml['html'])
    @js   += "$('##{record}_#{@yaml['name']}').selectMultiple();"
  else
    @html += @env.select(record, @yaml['name'], get_choices, options, @yaml['html'])
    # add code for view more data
    @html += view_code_add() if @yaml['with_view']
    @html += edit_code_add() if @yaml['with_edit'] && !@readonly
  end
  self
end

###########################################################################
# Return value. 
###########################################################################
def self.get_data(params, name)
  if params['record'][name].class == Array # remove blanks if array
    return params['record'][name].select(&:present?)
  end

  params['record'][name]
end
end

end
