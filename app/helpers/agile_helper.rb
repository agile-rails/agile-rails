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

###########################################################################
# 
# AgileHelper module defines common methods used for AgileRails forms.
#
###########################################################################
module AgileHelper
# javascript part created by form helpers
attr_reader :js
  
############################################################################
# Creates code for script action type.
############################################################################
def agile_script_action(yaml)
  icon = agile_icon_for_link yaml['icon']
  yaml['html'] ||= {}
  yaml['html']['data-url'] = 'script'
  yaml['html']['data-request'] = 'script'
  yaml['html']['data-script'] = (yaml['js'] || yaml['script']).to_s
  yaml['html']['class'] ||= 'ar-link-ajax'
  attributes = yaml['html'].map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
  %(<li><div #{attributes}>#{icon} #{ t(yaml['caption'], yaml['caption']) }</div></li>)
end

############################################################################
# Will return field form definition if field is defined on form. Field definition
# will then be used for creating filter input field.
############################################################################
def self.get_field_form_definition(name, form) #:nodoc:
  return if form['form'].nil?

  found = nil
  if form['form']['tabs']
    form['form']['tabs'].each_value do |data|
      found = data.find { |k, v| k.is_a?(Integer) && v['name'] == name }
      break if found
    end
  elsif form['form']['fields']
    found = form['form']['fields'].find { |k, v| k.is_a?(Integer) && v['name'] == name }
  end
  found&.last
end

############################################################################
# Return field code, label and help text for a field defined on a AgileRails Form.
# 
# Parameters:
# options : Hash : Field definition
# 
# Returns: Array[3]
#   field_html : String : HTML code for field definition
#   label : String : Label text
#   help : String : Help text
############################################################################
def agile_field_label_help(options)
  label, help = agile_label_help(options)
  # create field object from type and call its render method
  if options['type'].present?
    klass_string = options['type'].camelize
    field_html = if AgileFormFields.const_defined?(klass_string) # when field type defined
                   klass = AgileFormFields.const_get(klass_string)
                   field = klass.new(self, @record, options).render
                   @js  += field.js
                   @css += field.css
                   field.html
                 else
                   "Error: Field type #{options['type']} not defined!"
                 end
  else
    'Error: Field type missing!'
  end
  [field_html, label, help]
end

############################################################################
# Return label and help text for a field defined on Form.
#
# Parameters:
# options : Hash : Field definition
#
# Returns:
#   label : String : Label text
#   help : String : Help text
############################################################################
def agile_label_help(options)
  # no label or help in comments
  return [nil, nil] if %w[comment action].include?(options['type'])

  label = options['caption'] || options['text'] || options['label']
  #label = '' if options['type'] == 'check_box'
  if options['name']
    label = if label.to_s.empty?
              t_label_for_field(options['name'], options['name'].capitalize.gsub('_',' ') )
            elsif options['name']
              t(label, label)
            end
  end
  # help text can be defined in form or in translations starting with helpers. or as helpers.help.collection.field
  help = options['help']
  if help.blank?
    help = if options['name']
             # if defined as i18n_prefix replace "label" with "help"
             prefix = @form['i18n_prefix'] ? @form['i18n_prefix'].sub('label', 'help') : "helpers.help.#{@form['table']}"
             "#{prefix}.#{options['name']}"
           end
    help = help.to_s
  end
  help = t(help, ' ') if help.to_s.match(/help\./)

  [label, help]
end

############################################################################
# Return label and help for tab on Form.
#
# Parameters:
# options : String : Tab name on form
#
# Returns:
#   label : String : Label text
#   help : String : Help text
############################################################################
def agile_tab_label_help(tab_name)
  label = @form.dig('form', 'tabs', tab_name, 'caption') || tab_name
  label = t(label, t_label_for_field(label, label))
  help = @form.dig('form', 'tabs', tab_name, 'help') || "helpers.help.#{@form['table']}.#{tab_name}"
  help = t(help, t_label_for_field(help, help))
  help = nil if help.match('helpers.') # help not found in translation

  [label, help]
end

############################################################################
# Creates code for including data entry field in index actions.
############################################################################
def agile_field_action(yaml)
  # assign value if value found in parameters
  if params['record']
    value = params['record'][yaml['name']]
    params["p_#{yaml['name']}"] = value
  end
  # find field definition on form
  if ( field_definition = AgileHelper.get_field_form_definition(yaml['name'], @form) )
    # some options may be redefined
    field_definition['size'] = yaml['size'] if yaml['size']
    field, label, help = agile_field_label_help(field_definition)
  else
    yaml['type'] = yaml['field_type']
    field, label, help = agile_field_label_help(yaml)
  end
  # input field will have label as placeholder
  field = field.sub('input',"input placeholder=\"#{label}\"")
  %(<li class="no-background">#{field}</li>)
end

############################################################################
# Create ex. class="my-class" html code from html options for action
############################################################################
def agile_get_html_data(yaml)
  return '' if yaml.blank?

  yaml.reject{ |k, v| v.nil? }.map{ |k, v| "#{k}=\"#{v}\"" }.join(' ')
end

############################################################################
# There are several options for defining caption (caption,label, text). This method
# will ensure that caption is returned anyhow provided.
############################################################################
def agile_get_caption(yaml)
  yaml['caption'] || yaml['text'] || yaml['label']
end

############################################################################
# Creates code for link, ajax or windows action for index or form actions.
# 
# Parameters:
#   yaml: Hash : Action definition
#   record : Object : Currently selected record if available
#   action_active : Boolean : Is action active or disabled
#   
# Returns:
#   String : HTML code for action
############################################################################
def agile_link_ajax_window_submit_action(yaml, record = nil, action_active = true)
  parms = {}
  caption = agile_get_caption(yaml)
  caption = caption ? t(caption.downcase.to_s, caption) : nil
  icon    = yaml['icon'] ? mi_icon(yaml['icon']).to_s : ''
  # action is not active
  unless agile_is_action_active?(yaml)
    return %(<li><div class="ar-link-no">#{icon} #{caption}</div></li>)
  end
  # set data-confirm when confirm shortcut present
  yaml['html'] ||= {}
  text = yaml['html']['data-confirm'] || yaml['confirm']
  yaml['html']['data-confirm'] = t(text) if text.present?

  text = yaml['html']['title'] || yaml['title']
  yaml['html']['title'] = t(text) if text.present?

  yaml['html']['target'] ||= yaml['target']
  # direct url
  if yaml['url']
    parms['url'] = yaml['url']
    parms['idr'] = record.id if record
  # make url from action controller
  else
    parms['controller'] = yaml['controller'] || :agile
    parms['action']     = yaml['action'] 
    parms['table']      = yaml['table'] || @form['table']
    parms['form_name']  = yaml['form_name']
    parms['control']    = yaml['control'] if yaml['control']
    parms['id']         = record.id if record
  end
  # add current id to parameters
  parms['id'] = record.id if record
  # overwrite with or add additional parameters from environment or record
  yaml['params']&.each { |k, v| parms[k] = agile_value_for_parameter(v, record) }

  parms['table'] = parms['table'].underscore if parms['table'] # might be CamelCase
  # error if controller parameter is missing
  return "<li>#{'Controller not defined'}</li>" if parms['controller'].nil? && parms['url'].nil?

  html_data = agile_get_html_data(yaml['html'])
  url_forward_params(parms)
  url = url_for(parms) rescue 'URL error'
  url = nil if parms['url'] == '#'
  request = yaml['request'] || yaml['method'] || 'get'

  code = case yaml['type']
  # ajax button
  when 'ajax'
    clas = 'ar-link-ajax'
    %(<div class="#{clas}" data-url="#{action_active ? url : ''}" #{html_data}
       data-request="#{request}" title="#{yaml['title']}">#{icon}#{caption}</div>)

  # submit button
  when 'submit'
    # It's dirty hack, but will prevent not authorized message and render index action correctly
    parms[:filter] = 'on'
    url  = url_for(parms) rescue 'URL error'
    clas = 'ar-action-submit'
    %(<div class="#{clas}" data-url="#{action_active ? url : ''}" #{html_data}
       data-request="#{request}" title="#{yaml['title']}">#{icon}#{caption}</div>)

  # link button
  when 'link'
    yaml['html'] = agile_yaml_add_option(yaml['html'], class: 'ar-link')
    link = agile_link_to(caption, yaml['icon'], parms, yaml['html'] )
    (action_active ? link : caption).to_s

  # open window
  when 'window'
    clas = 'ar-link ar-window-open'
    %(<div class="#{clas}" data-url="#{action_active ? url : ''}" #{html_data}>#{icon}#{caption}</div>)

  # popup dialog
  when 'popup'
    clas = 'ar-link ar-popup-open'
    %(<div class="#{clas}" data-url="#{action_active ? url : ''}" #{html_data}>#{icon}#{caption}</div>)

  else
    'Type error!'
  end
  "<li>#{code}</li>"
end

############################################################################
# Add new option to yaml. Subroutine of agile_link_ajax_window_submit_action.
############################################################################
def agile_yaml_add_option(source, options) #nodoc
  options.each do |k, v|
    key = k.to_s
    source[key] ||= ''
    # only if not already present
    source[key] += " #{v}" unless source[key].match(v.to_s)
  end
  source
end

############################################################################
# Log exception to rails log. Usefull for debugging eval errors.
############################################################################
def agile_log_exception(exception, msg = '')
  log  = "\n*** ERROR ***\n"
  log += exception ? "#{msg}: #{exception.message}\n#{exception.backtrace.first.inspect}\n" : msg.to_s
  log += "\nAgileRails Form: #{AgileHelper.form_param(params)}, line: #{session[:form_processing]}\n"

  logger.error log
end

############################################################################
# Will return form id, to be used on each form for simpler css selecting.
############################################################################
def agile_form_id
  %( id=#{AgileHelper.form_param(params) || AgileHelper.table_param(params)} )
end

############################################################################
# Will return form_name from parameter regardless if set as form_name or just f.
############################################################################
def self.form_param(params)
  params[:form_name] || params[:f]
end

############################################################################
# Will return table name from parameter regardless if set as table or just t.
############################################################################
def self.table_param(params)
  params[:table] || params[:t]
end

########################################################################
# Searches forms path for file_name and returns full file name or nil if not found.
#
# @param [String] Form file name. File name can be passed as gem_name.filename. This can
# be useful when you are extending form but want to retain same name as original form
# For example. You are extending agile_user form from AgileRails gem and want to
# retain same agile_user form name, because it is used in AgileRails application menu.
# This can be done by setting agile_rails.agile_user as extend option.
#
# @return [String] Form file name including path or nil if not found.
########################################################################
def self.form_file_find(form_file)
  form_path = nil
  form_path, form_file = form_file.split(/\.|\//) if form_file.match(/\.|\//)

 Agile.paths(:forms).reverse.each do |path|
    f = "#{path}/#{form_file}.yml"
    return f if File.exist?(f) && (form_path.nil? || path.to_s.match(/\/#{form_path}(-|\/)/i))
  end
  raise "Exception: Form file #{form_file}.yml not found!"
end

########################################################################
# Merges two forms when current form extends other form. Subroutine of agile_form_read.
# With a little help of https://www.ruby-forum.com/topic/142809
########################################################################
def self.forms_merge(hash1, hash2)
  target = hash1.dup
  hash2.keys.each do |key|
    if hash2[key].is_a?(Hash) && hash1[key].is_a?(Hash)
      target[key] = AgileHelper.forms_merge(hash1[key], hash2[key])
      next
    end
    target[key] = hash2[key] == '/' ? nil :  hash2[key]
  end
  # delete keys with nil value
  target.delete_if { |k, v| v.nil? }
end

####################################################################
# Wrapper for i18 t method, with some spice added. If translation is not found English
# translation value will be returned. And if still not found default value will be returned if passed.
#
# Parameters:
# [key] String. String to be translated into locale.
# [default] String. Value returned if translation is not found.
#
# Example:
#    t('translate.this','Enter text for ....')
#
# Returns:
# String. Translated text.
####################################################################
def self.t(key, default = nil)
  return default if key.nil?

  c = I18n.t(key)
  if c.class == Hash || c.match(/translation missing/i)
    c = I18n.t(key, locale: 'en')
    # Still not found. Return default if set
    if c.class == Hash || c.match(/translation missing/i)
      c = default.nil? ? key : default
    end
  end
  c
end

###########################################################################
# When select field is used on form options for select can be provided by
# helpers.label.table_name.choices_for_name locale. This is how select
# field options are translated. Method returns selected choice translated
# to current locale.
#
# Parameters:
# [model] String. Table (table) model name (lowercase).
# [field] String. Field name used.
# [value] String. Value of field which translation will be returned.
#
# Example:
#    # usage in program. Choice values for state are 'Deactivated:0,Active:1,Waiting:2'
#    agile_text_for_value('agile_user', 'state', @record.active )
#
#    # usage in form
#    columns:
#      2:
#        name: state
#        eval: agile_text_for_value agile_user, state
#
# Returns:
# String. Descriptive text (translated) for selected choice value.
############################################################################
def self.name_for_value(model, field, value)
  return '' if value.nil?

  choices = t("helpers.label.#{model}.choices_for_#{field}")
  values  = choices.chomp.split(',').map{ _1.split(':') }
  values.each{ |e| return e.first if e.last.to_s == value.to_s }
  '???'
end

############################################################################
# Returns html code for displaying date/time formatted by strftime. Will return '' if value is nil.
#
# Parameters:
# [value] Date/DateTime/Time.
# [format] String. strftime format mask. Defaults to locale's default format.
############################################################################
def self.format_date_time(value, format = nil)
  return '' if value.blank?

  format ||= value.class == Date ? t('date.formats.default') : t('time.formats.default')
  if format.size == 1
    format = format.match(/d/i) ? t('date.formats.default') : t('time.formats.default')
  end
  #value.localtime.strftime(format)
  value.strftime(format)
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
def self.format_number(value = 0, decimals = nil, separator = nil, delimiter = nil, currency = nil)
  decimals  ||=  I18n.t('number.currency.format.precision')
  separator ||= I18n.t('number.currency.format.separator')
  separator   = '' if decimals == 0
  delimiter ||= I18n.t('number.currency.format.delimiter')
  whole, dec = value.to_s.split('.')
  whole = '0' if whole.blank?
  # remove and remember sign
  sign = ''
  if whole[0] == '-'
    whole.delete_prefix!('-')
    sign = '-'
  end
  # format decimals
  dec ||= '0'
  dec = dec.ljust(decimals, '0')[0, decimals]
  # slice whole on chunks of 3
  whole_a = []
  while whole.size > 0 do
    n = whole.size >= 3 ? 3 : whole.size
    whole_a << whole.slice!(n*-1, n)
  end
  # put it all back
  "#{sign}#{whole_a.reverse.join(delimiter)}#{separator}#{dec}"
end

####################################################################
# Returns true if parameter has value of 0, false, no, none or -.
# Returns value of default if parameter has nil value.
#
# Parameters:
# [what] String/boolean/Integer.
# [default] Default value when what has value of nil. False by default.
#
# Example:
#    agile_dont?('none')    # => true
#    agile_dont?('-')       # => true
#    agile_dont?(1)         # => false
#    agile_dont?(nil, true) # => true
####################################################################
def self.dont?(what, default = false)
  return default if what.nil?

  %w(0 n - no none false).include?(what.to_s.downcase.strip)
end

end
