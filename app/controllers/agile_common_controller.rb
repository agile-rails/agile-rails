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

########################################################################
# AgileCommonController holds some common actions used by AgileRails.
########################################################################
class AgileCommonController < AgileApplicationController
layout false

########################################################################
# This action is called on ajax autocomplete call. It checks if user has rights to
# view data. 
# 
# URL parameters:
# [table] Table (table) model name in lower case indicating table which will be searched.
# [id] Name of id key field that will be returned. Default is '_id'
# [input] Search data entered in input field.
# [search] when passed without dot it defines field name on which search 
# will be performed. When passed with dot class_method.method_name is assumed. Method name will
# be parsed and any class with class method name can be evaluated. Class method must accept
# input parameter and return array [ [_id, value],.. ] which will be used in autocomplete field.
# 
# Return:
# JSON array [label, value, id] of first 20 documents that confirm to query.
########################################################################
def autocomplete
  # table parameter must be defined. If not, get it from search parameter
  if params['table'].nil? && params['search'].match(/\./)
    name = params['search'].split('.').first
    params['table'] = name.underscore
  end
  if params['table'].match('_control')
    # depends on ar_memory permissions. Should probably be logged on.
    return render json: { label: t('agile.not_authorized') } unless agile_user_can(ArPermission::CAN_VIEW, 'ar_memory')
  else
    return render json: { label: t('agile.not_authorized') } unless agile_user_can(ArPermission::CAN_VIEW)
  end

  table = params['table'].classify.constantize
  input = params['input'].gsub(/\(|\)|\[|\]|\{|\|\.|\,|\}|\%|\*|\:|\;/, '') # remove special characters
  # call method in class. if search parameter contains . search is defined in a method
  result = if params['search'].match(/\./)
             name, method = params['search'].split('.')
             table.send(method, input).map do |e|
               { label: e[0], value: e[0], id: (e[1] || e[0]).to_s }
             end
           # standard search in table by field_name
           else
             table.where("lower(#{params['search']}) like ?", "%#{input.downcase}%").
             limit(20).map do |e|
               { label: e[params['search']], value: e[params['search']], id: e.id }
             end
           end
  render json: result
end

##########################################################################
# Toggle CMS edit mode.This action is called when user clicks CMS icon on
# top left corner of the browser.
##########################################################################
def toggle_edit_mode
  session[:edit_mode] ||= 0
  return agile_render_404 if session[:edit_mode] < 1 # called without logged in

  session[:edit_mode] = (session[:edit_mode] == 1) ? 2 : 1
  redirect_to (params[:return_to] || '/')
end

####################################################################
# Default user login action.
####################################################################
def process_login
  # Somebody is probably playing
  return agile_render_404 unless ( params[:record] && params[:record][:username] && params[:record][:password] )

  if params[:record][:password].present? # must not be empty
    user  = ArUser.find_by(username: params[:record][:username], active: true)
    if user&.authenticate(params[:record][:password])
      set_login_data(user, params[:record][:remember_me].to_i == 1)
      return redirect_to(params[:return_to] || '/', allow_other_host: true)
    else
      clear_login_data # on the safe side
    end
  end
  flash[:error] = t('agile.invalid_username')
  redirect_to(params[:return_to] ||  '/', allow_other_host: true)
end

####################################################################
# Default user logout action.
####################################################################
def logout
  clear_login_data
  redirect_to(params[:return_to] || '/', allow_other_host: true)
end

####################################################################
# Action for restoring document data from journal document.
####################################################################
def restore_from_journal
  # Only administrators can perform this operation
  unless agile_user_has_role?('admin')
    return render plain: { 'msg_info' => (t ('agile.not_authorized')) }.to_json
  end
  # selected fields to hash
  restore = {} 
  params[:select].each { |k, v| restore[k] = v if v == '1' }
  result = if restore.size == 0
    { 'msg_error' => (t ('agile.ar_journal.zero_selected')) }
  else
    journal_rec = ArJournal.find(params[:id])
    # update hash with data to be restored
    JSON.parse(journal_rec.diff).each { |k, v| restore[k] = v.first if restore[k] }
    # table model and document id
    table = journal_rec.tables.classify.constantize
    id    = journal_rec.ids
    record = table.find(id)
    # restore and save values
    restore.each { |field, value| record.send("#{field}=",value) }
    record.save
    # TODO Error checking
    { 'msg_info' => (t ('agile.ar_journal.restored')) }
  end
  render plain: result.to_json
end

########################################################################
# Copy current record to clipboard as json text. It will actually ouput an 
# window with data formatted as json.
########################################################################
def copy_clipboard
  # Only administrators can perform this operation
  return render(plain: t('agile.not_authorized') ) unless agile_user_has_role?('admin')

  respond_to do |format|
    # just open new window to same url and come back with html request
    format.json {  agile_render_ajax(operation: 'window', url: request.url ) }
    
    format.html do
      table  = AgileHelper.table_param(params).split(';').last
      record = agile_document_find(table, params[:id])
      text   = %(<style>body {font-family: monospace;}</style><pre>
                 JSON:<br>[#{table},#{params[:id]},#{params[:ids]}]<br>#{record.to_json}<br><br>
                 YAML:<br>#{record.attributes.to_yaml.gsub("\n", '<br>')}</pre>)
      render plain: text

    end
  end  
end

########################################################################
# Paste data from clipboard into text_area and update documents in destination database.
# This action is called twice. First time for displaying text_area field and second time 
# ajax call for processing data.
########################################################################
def paste_clipboard
  # Only administrators can perform this operation
  return render(plain: t('agile.not_authorized') ) unless agile_user_has_role?('admin')

  result = ''
  respond_to do |format|
    # just open new window to same url and come back with html request
    format.html { return render('paste_clipboard', layout: ' agile') }
    format.json {
      table, id, ids = nil
      params[:data].split("\n").each do |line|
        line.chomp!
        next if line.size < 5                 # empty line. Skip

        begin
          if line[0] == '['                   #  id(s)
            result += "<br>#{line}"
            line = line[/\[(.*?)\]/, 1]       # just what is between []
            table, id, ids = line.split(',')
          elsif line[0] == '{'                # document data
            result += paste_document_process(line, table, id, ids)
          end
        rescue Exception => e 
          result += " Runtime error. #{e.message}\n"
          break
        end
      end
    }
  end
  agile_render_ajax(div: 'result', value: result )
end

########################################################################
# Will add new json_ld element with blank structure into ar_json_ld field on a
# document.
########################################################################
def add_json_ld_schema
  edited_document = ArJsonLd.find_document_by_ids(AgileHelper.table_param(params), params[:ids])
  yaml = YAML.load_file( AgileHelper.form_file_find('json_ld_schema') )
  schema_data = yaml[params[:schema]]
  # Existing document
  if edited_document.ar_json_lds.find_by(type: "@#{params[:schema]}")
    return render json: {'msg_error' => t('helpers.help.ar_json_ld.add_error', schema: params[:schema] ) }
  else
    add_empty_json_ld_schema(edited_document, schema_data, params[:schema], params[:schema], yaml)
  end
  render json: {'reload_' => 1}
end

########################################################################
# Will provide help data
########################################################################
def help
  agile_form_read
  form_name = AgileHelper.form_param(params) || AgileHelper.table_param(params)
  help_file_name = @form['help'] || @form['extend'] || form_name
  help_file_name = AgileApplicationController.find_help_file(help_file_name)
  @help = YAML.load_file(help_file_name) if help_file_name
  # no auto generated help on index action
  return render json: {} if params[:type] == 'index' && @help.nil?

  render json: { popup_help: render_to_string(partial: 'help') }
end

##########################################################################
# Save poll results to ar_poll_results table
##########################################################################
def poll_submit
  record = params[:record]
  poll   = ArPoll.find(params[:poll_id]) || ArPoll.find_by(name: params[:poll_id])
  result = poll.save_results(record)
  # call additional service
  run = params[:record][:run] || params[:run]
  redirect_to(params[:return_to] || '/') and return if run.blank?

  service_response = send(run, result)
  respond_to do |format|
    format.html do # submit
      # return on poll-top
      params[:return_to] += '#poll-top' unless params[:return_to].match('#poll-top')
      # response should be in same format as ajax response. Extract error and info
      service_response = {} unless service_response.class == Hash
      flash[:error] = service_response['msg_error']
      flash[:info] = service_response['msg_info']
      redirect_to params[:return_to]
    end

    format.js do # ajax submit
      render json: service_response || { ok: 1 }
    end
  end

end
protected

########################################################################
# Subroutine of add_json_ld_schema for adding one element
########################################################################
def add_empty_json_ld_schema(edited_document, schema, schema_name, schema_type, yaml) #:nodoc
  data = {}
  doc  = ArJsonLd.new
  doc.name = schema_name
  doc.type = schema_type
 
  edited_document.ar_json_lds << doc
  schema.each do |element_name, element|
    next if element_name == 'level' # skip level element

    if yaml[element['type']]
      if element['n'].to_s == '1'
        # single element
        doc_1 = yaml[element['type'] ]
        data[element_name] = doc_1
      else
        # array
        add_empty_json_ld_schema(doc, yaml[element['type']], element_name, element['type'], yaml)
      end
    else
      data[element_name] = element['text']
    end
  end
  doc.data = data.to_yaml
  doc.save
end

########################################################################
# Update some anomalies in json data on paste_clipboard action.
########################################################################
def update_json(json, is_update=false) #:nodoc:
  result = {}
  json.each do |k,v|
    if v.class == Hash
      result[k] = v['$oid'] unless is_update
      # TODO Double check if unless works as expected
    elsif v.class == Array
      result[k] = []
      v.each { |e| result[k] << update_json(e, is_update)}
    else
      result[k] = v
    end
  end 
  result
end

########################################################################
# Processes one document. Subroutine of paste_clipboard.
########################################################################
def paste_document_process(line, table, id, ids)
  if params[:do_update] == '1' 
    doc = agile_document_find(table, id)
    # document found. Update it and return
    if doc
      doc.update( update_json(ActiveSupport::JSON.decode(line), true) )
      msg = agilecheck_model(doc)
      return (msg ? " ERROR! #{msg}" : " UPDATE. OK.")
    end
  end
  # document will be added to collection
  if ids.to_s.size > 5
    #TODO Add embedded document
    " NOT SUPPORTED YET!"
  else
    doc = table.classify.constantize.new( update_json(ActiveSupport::JSON.decode(line)) )
    doc.save
  end
  msg = Agile.model_check(doc)
  msg ? " ERROR! #{msg}" : " NEW. OK." 
end

end
