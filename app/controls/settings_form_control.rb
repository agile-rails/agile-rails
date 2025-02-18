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
# AgileRails controls for editing settings saved in a document.
#
# Parameters to settings call:
# :location - model_name where settings document is located. Typically ar_page or ar_site.
# :field_name - name of the field where settings are saved
# :element - element name as defined on design 
# :id - document id
######################################################################
module SettingsFormControl

######################################################################
# Check if settings control document exists and return document and 
# settings values as yaml string.
# 
# Return:
#   [record, data] : record, yaml as String
######################################################################
def get_settings
  # On save. Set required variables
  if params[:record]
    params[:location]   = params[:record][:ar_location]
    params[:field_name] = params[:record][:ar_field_name]
    params[:element]    = params[:record][:ar_element]
    params[:id]         = params[:record][:ar_record_id]
  end

  # Check if table exists
  begin
    model = params[:location].classify.constantize
  rescue 
    flash[:error] = "Invalid or undefined model name! #{params[:location]}"
    return false
  end

  # Check if field_name exists
  begin
    document = model.find(params[:id])
    params[:field_name] ||= (params[:location] == 'ar_site' ? 'settings' : 'params')
    # field not defined
    raise unless document.respond_to?(params[:field_name])

    yaml = document[params[:field_name]] || ''
  rescue 
    flash[:error] = 'Invalid or undefined field name!'
    return false
  end

  # Check data
  begin
    data = YAML.load(yaml) || {}
  rescue 
    flash[:error] = 'Invalid configuration data found!'
    return false
  end
  [document, data]
end

######################################################################
# Called before edit.
#
# Load fields on form with values from settings document.
######################################################################
def new_record
  document, data = get_settings
  return false if document.instance_of?(FalseClass) && data.nil?

  # fill values with settings values
  if data['settings'] && data['settings'][ params[:element] ]
    data['settings'][ params[:element] ].each { |key, value| @record.send("#{key}=", value) }
  end
  # add some fields required at post as hidden fields to form
  form = @form['form']['tabs'] ? @form['form']['tabs'].to_a.last : @form['form']['fields']
  form[9999] = { 'type' => 'hidden_field', 'name' => 'ar_location', 'html' => { 'value' => params[:location] } }
  form[9998] = { 'type' => 'hidden_field', 'name' => 'ar_field_name' }
  @record[:ar_field_name] = params[:field_name]
  form[9997] = { 'type' => 'hidden_field', 'name' => 'ar_element' }
  @record.ar_element = params[:element]
  form[9996] = { 'type' => 'hidden_field', 'name' => 'ar_record_id', 'html' => { 'value' => params[:id] } }
end

######################################################################
# Called before save. 
#
# Convert data from fields on form to yaml and save it to document settings field.
######################################################################
def before_save
  document, data = get_settings
  return false if document.instance_of?(FalseClass) && data.nil?

  fields_on_form.each do |v|
    session[:form_processing] = v['name'] # for debugging
    next if v['type'].nil? || v['readonly']

    # return value from form field definition
    value = AgileFormFields.const_get(v['type'].camelize).get_data(params, v['name'])
    value = value.map(&:to_s) if value.instance_of?(Array)
    # set to nil if blank
    value = nil if value.blank?
    data['settings'] ||= {}
    data['settings'][params[:element]] ||= {}
    data['settings'][params[:element]][v['name']] = value
  end
  # remove nil elements
  data['settings'][ params[:element] ].compact!
  # save data to document field
  document.send("#{params[:field_name]}=", data.to_yaml)
  document.save
  # to re-set form again
  new_record
  false # must be
end

end
