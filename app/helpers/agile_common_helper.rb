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


####################################################################
# Common methods which may also come handy in controllers or models or any
# other module of program.
# 
# Usage: include AgileCommonHelper
####################################################################
module AgileCommonHelper
  
####################################################################
def t(key, default = nil) #:nodoc
  AgileHelper.t(key, default)
end

####################################################################
# Returns table (table) name translation for usage in dialog title. Tablename 
# title is provided by helpers.label.table_name.table_title locale.
# 
# Parameters:
# [tablename] String. Table (table) name to be translated.
# [default] String. Value returned if translation is not found.
# 
# Returns: 
# String. Translated text. 
####################################################################
def t_table_name(table_name, default = nil)
  t('helpers.label.' + table_name + '.table_title', default || table_name)
end

############################################################################
# Returns label for field translated to current locale for usage on data entry form.
# Translation is provided by lang.helpers.label.table_name.field_name locale. If
# translation is not found method will capitalize field_name and replace '_' with ' '.
############################################################################
def t_label_for_field(field_name, default = '')
  c = (@form['i18n_prefix'] || "helpers.label.#{@form['table']}") + ".#{field_name}"
  c = field_name if field_name.match(/helpers\./)

  label = t(c, default)
  label = field_name.capitalize.gsub('_', ' ') if c.match( /translation missing/i )
  label
end

############################################################################
# Returns label for field translated to current locale for usage in browser header.
# Translation is provided by lang.helpers.label.table_name.field_name locale. If
# not found method will look in standard agile translations.
############################################################################
def t_label_for_column(options)
  label = options['caption'] || options['label']
  return ' ' if label == false

  if label.blank?
    label = if options['name']
              prefix = @form['i18n_prefix'] || "helpers.label.#{@form['table']}"
              "#{prefix}.#{options['name']}"
            end
    label = label.to_s
  end
  label = t(label) if label.match(/\./)
  label = t("agile.#{options['name']}") if label.match('helpers.') # standard field names like created_by, updated_at
  label = options['name'].capitalize if label.match('agile.')  # still no translation. Just capitalize
  label
end

############################################################################
def agile_text_for_value(model, field, value)
  AgileHelper.name_for_value(model, field, value)
end

############################################################################
# Return choices for field in model if choices are defined in localization text.
# 
# Parameters:
# [model] String. Table (table) model name (lowercase).
# [field] String. Field name used.
# 
# Example:
#    agile_choices_for_field('ar_user', 'state' )
#        
# Returns: 
# Array. Choices for select input field
############################################################################
def self.agile_choices_for_field(model, field)
  c = AgileCommonHelper.t("helpers.label.#{model}.choices_for_#{field}")
  return ['error'] if c.match(/translation missing/i)

  c.chomp.split(',').map{ _1.split(':') }
end

############################################################################
# Will return descriptive text for id key when field in one table (table) has belongs_to 
# relation to other table.
# 
# Parameters:
# [model] String. Table (table) model name (lowercase).
# [field] String. Field name holding the value of descriptive text.
# [field_name] String. ID field name. This is by default id, but can be any other 
# (preferred unique) field.
# [value] Value of id_field. Usually an id key but can be any other data type.
# 
# Example:
#    # usage in program.
#    agile_name_for_id('ar_user', 'name', nil, ar_page.created_by)
#
#    # usage in form
#    columns:
#      2: 
#        name: site_id
#        eval: agile_name_for_id,site,name
#    # username is saved to document instead of user.id field
#      5: 
#        name: user
#        eval: agile_name_for_id,ar_user,name,username
# 
# Returns: 
# String. Name (descriptive value) for specified key in table.
############################################################################
def agile_name_for_id(model, field, field_name, id = nil)
  return '' if id.nil?

  field_name = (field_name || 'id').strip.to_sym
  field = field.strip.to_sym
  model = model.strip.classify.constantize if model.class == String
  record = model.find_by(field_name => id)
  record.nil? ? '' : (record.send(field) rescue '?? not defined')
end

############################################################################
# Return html code for icon presenting boolean value. Icon is a picture of checked or unchecked box.
# If second parameter (fiel_name) is ommited value is supplied as first parameter.
# 
# Parameters:
# [value] Boolean.  
# 
# Example:
#    # usage from program
#   agile_icon_for_boolean(document, field_name)
#
#    # usage from form description
#    columns:
#      10: 
#        name: active
#        eval:agile_icon_for_boolean
############################################################################
def agile_icon_for_boolean(document = false, field_name = nil)
  value = field_name.nil? ? document : document[field_name]
  agile_dont?(value, true) ? mi_icon('check_box_outline_blank md-18') : mi_icon('check_box-o md-18')
end

############################################################################
# Returns html code for displaying date/time formatted by strftime. Will return '' if value is nil.
#
# Parameters:
# [value] Date/DateTime/Time.
# [format] String. strftime format mask. Defaults to locale's default format.
############################################################################
def agile_format_date_time(value, format=nil) #:nodoc:
  AgileHelper.format_date_time(value, format)
end

############################################################################
# Returns html code for displaying formatted number.
#
# Parameters:
# [value] Numeric number.
# [decimals] Integer. Number of decimals
# [separator] String. Decimals separator
# [delimiter] String. Thousands delimiter.
# [currency] String. Currency symbol if applied to result string.
############################################################################
def agile_format_number(value=0, decimals=nil, separator=nil, delimiter=nil, currency=nil) #:nodoc:
  AgileHelper.format_number(value, decimals, separator, delimiter, currency)
end

############################################################################
# Create help text for fields on single tab
############################################################################
def agile_help_for_tab(tab)
  return '' if tab.nil?

  html = ''
  if tab.class == Array
    tab_name = tab.last['caption'] || tab.first
    tab_label, tab_help = agile_tab_label_help(tab_name)
    html += %(<div class="help-tab">#{tab_label}</div><div class="help-tab-help">#{tab_help}</div>)

    tab = tab.last
  end

  tab.each do |field|
    label, help = agile_label_help(field.last)
    next if help.blank?

    html += %(<div class="help-field"><div class="help-label">#{label}</div><div class="help-text">#{help.gsub("\n",'<br>')}</div></div>)
  end
  html
end

############################################################################
# Will scoop fields and help text associated with them to create basic help text.
############################################################################
def agile_help_fields
  return '' if @form['form'].nil?

  html = '<a id="fields"></a>'
  if @form['form']['tabs']
    @form['form']['tabs'].each { |tab| html += agile_help_for_tab(tab) }
  else
    html += agile_help_for_tab(@form['form']['fields'])
  end
  html.html_safe
end

############################################################################
# Will return text from help files
############################################################################
def agile_help_body
  (params[:type] == 'index' ? @help['index'] : @help['form']).html_safe
end

############################################################################
# Will return code for help button if there is any help text available for the form.
############################################################################
def agile_help_button(data_set)
  type = data_set.nil? ? 'form' : 'index'
  form_name = AgileHelper.form_param(params) || AgileHelper.table_param(params)
  url = url_for(controller: :agile_common, action: :help, type: type, f: form_name)
  html = %(<div class="ar-help-icon ar-link-ajax" data-url=#{url}>#{mi_icon('question-circle')}</div>)
  return html if type == 'form'

  # check if index has any help available
  help_file_name = @form['help'] || @form['extend'] || form_name
  help_file_name = AgileApplicationController.find_help_file(help_file_name)
  if help_file_name
    help = YAML.load_file(help_file_name)
    return html if help['index']
  end
  ''
end

############################################################################
# Will return html code for steps menu when form with steps is processed.
############################################################################
def agile_steps_menu_get(parent)
  yaml = @form['form']['steps']
  return '' unless yaml

  html = %(<ul id="ar-steps-menu"><h2>#{t('agile.steps')}</h2>)
  control = @form['control'] ? @form['control'] : @form['table']
  parms = { controller: :agile, action: 'run', control: "#{control}.steps",
            table: AgileHelper.table_param(params),
            form_name: AgileHelper.form_param(params),
            id: @record.id }

  yaml.sort.each_with_index do |data, i|
    n = i + 1
    step = data.last # it's an array
    url = case params[:step].to_i
          when n + 1 then url_for(parms.merge({ step: n + 1, next_step: n}))
          when n then url_for(parms.merge({ step: n, next_step: n}))
          when n - 1 then url_for(parms.merge({ step: n - 1, next_step: n}))
          else
            ''
          end
    _class = url.present? ? 'ar-link-ajax' : ''
    _class += (params[:step].to_i == n ? ' active' : '')
    html += %(<li class="#{_class}" data-url="#{url}">#{step['title']}</li>)
  end
  html += '</ul>'
end

############################################################################
# Adds additional parameters to url parameters hash. If url is nil then
# additional parameters are the return value of method.
#
# @param [Array] url : URL parameters as array. Values will be added to array.
############################################################################
def url_forward_params(parms)
  if params[:belongs_to]
    parms[:belongs_to]    = params[:belongs_to]
    parms[:belongs_to_id] = params[:belongs_to_id]
  end
end
end