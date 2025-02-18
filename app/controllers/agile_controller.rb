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
# This is main controller for processing actions by  AgileRails forms. It provides
# CRUD actions for editing database records. AgileRails does not require controller
# to be made for every table model but implements all actions in single
# controller. Logic required to control data entry is provided within AgileRails 
# forms which are loaded dynamically for every action.
# 
# Data entry validations must therefore reside in document models definitions or can be implemented in forms.
# There are always validations that cannot be done in models. Like validations
# which include url parameters or accessing session variables. This is hard to be done
# in model therefore AgileRails controls had to be invented. AgileRails controls are
# modules with methods that are injected into agile controller and act in runtime like
# they are part of Agile controller.
# 
# Since Ruby and Rails provide some "automagic" loading of modules  AgileRails controls must be saved
# into app/controls folder. Every model can have its own controls file.
# ar_page model's controls live in ar_page_controls.rb file. By convention module names
# are declared in camel case, so our ar_page_controls.rb declares ArPageControls module.
# 
# Controls (among other) may contain 8 callback methods.
# These methods are:
# - before_new
# - new_record
# - dup_record
# - before_edit
# - before_save
# - after_save
# - before_delete
# - after_delete
#
# Methods before_new, before_edit, before_save or before_delete may also effect flow of the application. If
# method return false (not nil but FalseClass) normal flow of the program is interrupted and last operation
# is canceled. 
#
# Second control methods that can be declared in  AgileRails controls are filters for
# viewing and sorting documents. It is often required that dynamic filters are 
# applied to data_set documents. 
#
#    data_set:
#      filter: current_users_documents
#
# Example implemented controls method:
#
#    def current_users_documents
#      if agile_user_can(ArPermission::CAN_READ)
#        ArPage.where(created_by: session[:user_id])
#      else
#        flash[:error] = 'User can not perform this operation!'
#        false
#      end
#    end
#
# If filter method returns false user will be presented with flash error.
########################################################################
class AgileController < AgileApplicationController
before_action :authorization_check, :except => [:login, :logout, :test, :run]
protect_from_forgery with: :null_session, only: Proc.new { _1.request.format.json? }

layout 'agile'

########################################################################
# Index action 
########################################################################
def index
  @form['index']['data_set'] ||= {}
  redirected = (@form['table'] == 'ar_memory' ? process_in_memory : process_data_set)
  return if redirected

  callback_method_call(@form.dig('index', 'data_set', 'footer') || 'update_footer')
  respond_to do |format|
    format.html { render action:  :index }
    format.js   { render partial: :result }
  end
end

########################################################################
# Filter action. 
########################################################################
def _filter
  index
end

########################################################################
# Show displays record in readonly mode.
########################################################################
def show
  find_record
  # before_show callback
  if (m = callback_method('before_show') )
    ret = callback_method_call(m)
    if ret.class == FalseClass
      @form['readonly'] = nil # must be
      return index 
    end
  end  

  render action: 'edit'
end

########################################################################
# Login action. Used to login direct to CMS. It is mostly used when first time
# creating site and when something goes so wrong, that common login procedure
# is not available.
# 
# Login can be called directly with url http://site.com/agile/login
########################################################################
def login
  return set_development_site if params[:id] == 'test'

  session[:edit_mode] = 0 unless params[:ok]
  render action: 'login'
end

########################################################################
# Logout action. Used to logout direct from CMS.
# 
# Logout can be called directly with url http://site.com/agile/logout
########################################################################
def logout 
  session[:edit_mode]   = 0
  session[:user_id]     = nil
  session[:user_roles]  = nil
  render action: 'login'
end

########################################################################
# Shortcut for setting currently selected site in development. Will search
# for  ar_site document with site name 'development' and set alias_for to site
# url parameter.
########################################################################
def set_development_site
  # only in development
  return  agile_render_404 unless Rails.env.development?

  alias_site = ArSite.find_by(name: params[:site])
  return agile_render_404 unless alias_site

  # update alias for  
  site = ArSite.find_by(name: 'development')
  site.alias_for = params[:site]
  site.save
  redirect_to '/'
end

########################################################################
# New action.
########################################################################
def new
  flash[:error] = flash[:warning] = flash[:info] = nil
  # not authorized
  unless agile_user_can(ArPermission::CAN_CREATE)
    flash[:error] = t('agile.not_authorized')
    return index
  end
  create_new_empty_record()

  if (m = callback_method('before_new') )
    ret = callback_method_call(m)
    return index if ret.class == FalseClass
  end
  load_initial_values()

  # new_record callback. Set default values for new record
  if (m = callback_method('new_record') ) then callback_method_call(m)  end
  @form_params['action'] = 'create'
end

########################################################################
# Will duplicate source document into new record. This method is used for
# duplicating record and is subroutine of create action.
########################################################################
def duplicate_record(source)
  duplicates = params['dup_fields'].split(',').map(&:strip)
  dest = {}
  source.attribute_names.each do |attribute_name|
    next if attribute_name == 'id' # don't duplicate _id

    dest[attribute_name] = source[attribute_name]
    # if duplicate, string dup is added. For unique fields
    dest[attribute_name] += ' dup' if duplicates.include?(attribute_name)
  end
  dest['created_at'] = Time.now if dest['created_at']
  dest['updated_at'] = Time.now if dest['updated_at']
  dest
end

########################################################################
# Create (or duplicate) action.
########################################################################
def create
  # not authorized
  unless agile_user_can(ArPermission::CAN_CREATE)
    flash[:error] = t('agile.not_authorized')
    return index
  end

  # create document
  if params['id'].nil?
    # Prevent double form submit
    return index if double_form_submit?

    create_new_empty_record
    if save_data
      flash[:info] = t('agile.record_saved')
      params[:return_to] = 'index' if params[:commit] == t('agile.save&back') # save & back
      return process_return_to(params[:return_to]) if params[:return_to]

      @form_params['id'] = @record.id # must be set, for proper update link
      params[:id] = @record.id # must be set, for find_record
      edit
    else # error
      return process_return_to(params[:return_to]) if params[:return_to]

      render action: :new
    end
  else # duplicate record
    find_record
    new_record = duplicate_record(@record)
    create_new_empty_record(new_record)
    if (m = callback_method('dup_record')) then callback_method_call(m) end
    update_standards
    @record.save!
    index
  end
end

########################################################################
# Edit action.
########################################################################
def edit
  find_record
  if (m = callback_method('before_edit') )
    ret = callback_method_call(m)
    # don't do anything if return is false
    return index if ret.class == FalseClass
  end
  @form_params['action'] = 'update'
  render action: :edit
end

########################################################################
# Update action.
########################################################################
def update
  find_record
  # check if record was not updated in mean time
  if @record.respond_to?(:updated_at)
    if params[:last_updated_at].to_i != @record.updated_at.to_i
      flash[:error] = t('agile.updated_by_other')
      return render(action: :edit)
    end
  end

  if agile_user_can(ArPermission::CAN_EDIT_ALL) ||
    (@record.respond_to?('created_by') && @record.created_by == session[:user_id] && agile_user_can(ArPermission::CAN_EDIT))

    if save_data
      params[:return_to] = 'index' if params[:commit] == t('agile.save&back') # save & back
      @form_params['action'] = 'update'
      # Process return_to
      return process_return_to(params[:return_to]) if params[:return_to]
    else
      # do not forget before_edit callback
      if m = callback_method('before_edit') then callback_method_call(m) end
      return render action: :edit
    end
  else
    flash[:error] = t('agile.not_authorized')
  end
  edit
end

########################################################################
# Destroy action. Used also for enabling and disabling record.
########################################################################
def destroy
  find_record
  # check permission required to delete
  permission = if params['operation'].nil?
    if @record.respond_to?('created_by') # needs can_delete_all if created_by is present and not owner
      (@record.created_by == session[:user_id]) ? ArPermission::CAN_DELETE : ArPermission::CAN_DELETE_ALL
    else
      ArPermission::CAN_DELETE    # by default
    end
  else # enable or disable record
    if @record.respond_to?('created_by')
      (@record.created_by == session[:user_id]) ? ArPermission::CAN_EDIT : ArPermission::CAN_EDIT_ALL
    else
      ArPermission::CAN_EDIT      # by default
    end
  end
  ok2delete = agile_user_can(permission)

  case
  # not authorized
  when !ok2delete then
    flash[:error] = t('agile.not_authorized')
    return index

  # delete document
  when params['operation'].nil? then
    # before_delete callback
    if (m = callback_method('before_delete') )
      ret = callback_method_call(m)
      # don't do anything if return is false
      return index if ret.class == FalseClass
    end

    # take care of transaction
    begin
      transaction_begin()
      if @record.destroy
        save_journal(:delete)
        flash[:info] = t('agile.record_deleted')
        # after_delete callback
        if (m = callback_method('after_delete') )
          callback_method_call(m)
        elsif params['after-delete'].to_s.match('return_to')
          params[:return_to] = params['after-delete']
        end
        # Process return_to link
        if params[:return_to]
          transaction_end()
          return process_return_to(params[:return_to])
        end
      else
        flash[:error] = agile_error_messages_for(@record)
        transaction_abort('')
      end
    rescue Exception => e
      transaction_abort()
      transaction_end()
      logger.error(%(#{e.message}\n\n#{e.backtrace.join("\n")}))
      return if Rails.env.test? # or test will fail

      raise
    end
    # end transaction normaly
    transaction_end()
    return index
    
  # deactivate document
  when params['operation'] == 'disable' then
    if @record.respond_to?('active')
      @record.active = false
      save_journal(:update, @record.changes)
      update_standards()
      @record.save
      flash[:info] = t('agile.record_disabled')
    end
    
  # reactivate document
  when params['operation'] == 'enable' then
    if @record.respond_to?('active')
      @record.active = true
      update_standards()
      save_journal(:update, @record.changes)
      @record.save
      flash[:info] = t('agile.record_enabled')
    end

  #TODO reorder documents
  when params['operation'] == 'reorder' then

  end

  @form_params['action'] = 'update'
  render action: :edit
end

########################################################################
# Run action
########################################################################
def run
  # determine control file name and method
  control_name, method_name = params[:control].split('.')
  if method_name.nil?
    method_name  = control_name
    control_name = AgileHelper.table_param(params)
  end
  # extend with control methods
  extend_with_control_module(control_name)
  if respond_to?(method_name)
    # can it be called
    return return_run_error t('agile.not_authorized') unless can_process_run
    # call method
    respond_to do |format|
      format.json { send method_name }
      format.html { send method_name }
    end    
  else # Error message
    return_run_error "Method #{method_name} not defined in #{control_name}_control"
  end
end

protected

########################################################################
# Respond with error on run action
########################################################################
def return_run_error(text)
  respond_to do |format|
    format.json { render json: { msg_error: text } }
    format.html { render plain: text }
  end
end

########################################################################
# Can run call be processed
########################################################################
def can_process_run
  if respond_to?( :can_process?)
    response = send( :can_process?)
    return response unless response.class == Array
  else
    response = [ArPermission::CAN_VIEW, AgileHelper.table_param(params) || 'ar_memory']
  end
  agile_user_can *response
end

########################################################################
# Checks if user has permissions to perform operation on table and if not
# prepares response for not authorized message.
#
# @param [Integer] permission : Permission level defined in ArPermission constants eg. ArPermission::CAN_EDIT
# @param [String] collection_name : Table name on which user must have permission
#
# @return [Boolean] true when user has required permission otherwise false
########################################################################
def user_has_permission?(permission, collection_name)
  unless agile_user_can(permission, collection_name.to_s)
    respond_to do |format|
      format.json { render json: { msg_error: t('agile.not_authorized') } }
      format.html { render plain: t('agile.not_authorized') }
    end
    return true
  end
  true
end

############################################################################
# Load module if available. Try not to mask errors in control module
############################################################################
def controls_module_load(controls_string)
  begin
    controls_string.classify.constantize
  rescue NameError => e
    return if e.message.match('uninitialized constant') || e.message.match('wrong constant name')
    # report errors when loading existing module
    raise e
  end
end

############################################################################
# Dynamically extend ra controller class with methods defined in controls module.
############################################################################
def extend_with_control_module(control_name = @form['controls'] || @form['control'])
  # May include embedded forms so ; => _
  control_name ||= AgileHelper.table_param(params).gsub(';', '_')
  control_name += '_control' unless control_name.match(/control$|report$/i)

  controls = controls_module_load(control_name)
  if controls
    # extend first with agile_report when report
    if control_name.match(/report$/i)
      extend AgileReport
      report_init(control_name)
    end
    extend controls
    # Form may be dynamically updated before processed
    send(:update_form) if respond_to?(:update_form)
  end
end

############################################################################
# Check if user is authorized for the action. If authorization is in order it will also
# load AgileRails form.
############################################################################
def authorization_check
  params[:table] ||= params[:t] || AgileHelper.form_param(params)
  # Only show menu
  return login if params[:id].in?(%w[login logout test])

  table = params[:table].to_s.strip.downcase
  set_default_guest_user_role if session[:user_roles].nil?
  # request shouldn't pass
  if table != 'ar_memory' &&
     (table.size < 3 || !agile_user_can(ArPermission::CAN_VIEW))
     return render(action: 'error', locals: { error: t('agile.not_authorized')} )
  end
  agile_form_read

  # Permissions can be also defined on form
  #TODO So far only can_view is used. Think about if using other permissions has sense
  can_view = @form.dig('permissions', 'can_view')
  if can_view.nil? || can_view.split(',').find{ agile_user_has_role?(_1) }
    extend_with_control_module
  else
    render(action: 'error', locals: { error: t('agile.not_authorized')} )
  end  
end

########################################################################
# Find current record for edit, update or delete.
########################################################################
def find_record #:nodoc:
  @record = @tables.last[0].find(params[:id])
end

########################################################################
# Creates new empty record for new and create action.
########################################################################
def create_new_empty_record(initial_data = nil) #:nodoc:
  if @tables.size == 1
    @record = @tables.first[0].new(initial_data)
  else
    rec = @tables.first[0].find(@ids.first)     # top most record
    1.upto(@tables.size - 2) { |i| rec = rec.send(@tables[i][1].pluralize).find(@ids[i]) }  # find embedded children by ids
    @record = @tables.last[0].new(initial_data) # new record
  end
end

########################################################################
# Update standard fields like updated_by, created_by, site_id
########################################################################
def update_standards(record = @record)
  record.updated_by = session[:user_id] if record.respond_to?('updated_by')
  if record.new_record?
    record.created_by = session[:user_id] if record.respond_to?('created_by')
    # set this only initially. Allow to be set to nil on updates. Record can then belong to all sites
    # and will be directly visible only to admins
    record.ar_site_id = agile_get_site.id if record.respond_to?('ar_site_id') && record.ar_site_id.nil?
  end
  record.send(:set_history, self) if record.respond_to?(:set_history)
end

########################################################################
# Save record's changes to journal table. Saves all parameters to retrieve record if needed.
# 
# [Parameters:]
# [operation] 'delete' or 'update'.
# [changes] Current record's changed fields.
########################################################################
def save_journal(operation, changes = {})
  if operation == :delete
    @record.attributes.each { |k, v| changes[k] = v }
  end
  changes.except!('created_at', 'updated_at', 'created_by', 'updated_by')

  if (operation != :update) || changes.size > 0
    # determine site_id
    site_id = @record.site_id if @record.respond_to?('site_id')
    site_id = site_id || agile_get_site&.id
    ArJournal.create(site_id: site_id,
                     operation: operation,
                     user_id:   session[:user_id],
                     tables:    @form['table'],
                     ids:       params[:ids],
                     record_id: params[:id],
                     ip:        request.remote_ip,
                     time:      Time.now,
                     diff:      changes.to_json)
  end
end

########################################################################
# Determines if callback method is defined in parameters or in control module. 
# Returns callback method name or nil if not defined.
########################################################################
def callback_method(key) #:nodoc:
  data_key = key.gsub('_', '-') # convert _ to -
  callback = case
    when params['data'] && params['data'][data_key] then params['data'][data_key]
    # method is present then call it automatically
    when @form.dig('form', key) then @form['form'][key]
    when respond_to?(key) then key
    when params[data_key] then params[data_key]
    else nil
  end

  ret = case
    when callback.nil? then callback # otherwise there will be errors in next lines
    when callback.match('eval ') then callback.sub('eval ', '')
    when callback.match('return_to ')
      params[:return_to] = callback.sub('return_to ', '')
      return nil
    else callback
  end
  ret
end

########################################################################
# Calls callback method.
########################################################################
def callback_method_call(m) #:nodoc:
  send(m) if respond_to?(m)  
end

########################################################################
# Same as javascript_tag helper. Ajax form actions may results in javascript code to be returned.
# This will add javascript tag to code.
########################################################################
def js_tag(script) #:nodoc:
  "<script>#{script}</script>"
end

########################################################################
# Process return_to parameter when defined on form or set by controls methods. 
# params['return_to'] may contain 'index', 'reload' or 'parent.reload' or any valid url to
# return to, after successful controls method call.
########################################################################
def process_return_to(return_to)
  script = case
    when return_to == 'index' then return index
    when return_to.match(/eval=/i) then return_to.sub('eval=', '')
    when return_to.match(/parent\.reload/i) then 'parent.location.href=parent.location.href;'
    when return_to.match(/reload/i) then 'location.href=location.href;'
    when return_to.match(/window\.close/i) then 'window.close();'
    when return_to.match(/none/i) then return
    else "location.href='#{return_to}'"
  end
  render html: js_tag(script).html_safe, layout: false
end

########################################################################
# Since tabs have been introduced on form it is a little more complicated
# to collect all edit fields on form. This method does it. Subroutine of save_data.
########################################################################
def fields_on_form #:nodoc:
  form_fields = []
  if @form['form']['fields']
    # read only field elements (key is Integer)
    @form['form']['fields'].each { |key, options| form_fields << options if key.class == Integer }
  else
    @form['form']['tabs'].keys.each do |tab|
      @form['form']['tabs'][tab].each { |key, options| form_fields << options if key.class == Integer }
    end  
  end
  form_fields
end

########################################################################
# Save edited data. Take care that only fields defined on form are affected. 
# It also saves journal data and calls before_save and after_save callbacks.
########################################################################
def save_data
  form_fields = fields_on_form()
  return true if form_fields.size == 0

  form_fields.each do |v|
    session[:form_processing] = v['name'] # for debuging
    next if v['type'].nil? or v['name'].nil? or
            v['type'].match('belongs_to') or # don't wipe embedded types
            (params[:edit_only] and params[:edit_only] != v['name']) or # otherwise other fields would be wiped
            v['readonly'] or # fields with readonly option don't return value and would be wiped
            !@record.respond_to?(v['name']) # there are temporary fields on the form
    # return value from form field definition
    value = AgileFormFields.const_get(v['type'].camelize).get_data(params, v['name'])
    @record.send("#{v['name']}=", value)
  end

  # before_save callback
  if (m = callback_method('before_save') )
    ret = callback_method_call(m)
    # don't save if callback returns false
    return false if ret.class == FalseClass
  end

  # save data. Take care for active transaction and end it properly
  begin
    changes = @record.changes
    transaction_begin()
    update_standards() if changes.size > 0  # update only if there has been some changes
    operation = @record.new_record? ? :new : :update
    if (saved = @record.save)
      save_journal(operation, @record.previous_changes)
      # after_save callback
      if (m = callback_method('after_save') ) then callback_method_call(m) end
    else
      transaction_abort()
    end
  rescue Exception => e
    transaction_abort()
    transaction_end()
    logger.error(%(\n#{e.message}\n\n#{e.backtrace.join("\n")}))
    return if Rails.env.test?

    raise
  end
  transaction_end()
  saved
end

########################################################################
# Begins database transaction if requested
########################################################################
def transaction_begin
  return unless %w[1 yes true].include?(@form['transaction'].to_s.downcase)

  manager = ActiveRecord::Base.connection.transaction_manager
  manager.begin_transaction
  @transaction = 'OK'
end

########################################################################
# Aborts database transaction. It will rollback in transaction_end
########################################################################
def transaction_abort(message = 'Transaction aborted')
  return if @transaction.nil?

  @transaction = @transaction == 'OK' ? message : "#{@transaction}; #{message}"
end

########################################################################
# Commits or rollbacks the transaction. Operation depend on the value of
# @transaction variable. If value is OK, then transaction is commited, otherwise
# transaction is aborted with the message added
########################################################################
def transaction_end
  return if @transaction.nil?

  manager = ActiveRecord::Base.connection.transaction_manager
  if @transaction == 'OK'
    manager.commit_transaction
  else
    manager.rollback_transaction
    flash[:error] = (flash[:error].present? ? flash[:error].to_s + "<br>" : '') + @transaction
    flash[:info]  = nil # must be
  end
end
########################################################################
# Will return comma separated data (field names) as array of symbols. For usage
# in select_fields and deny_fields
########################################################################
def separated_to_symbols(data)
  data.chomp.split(',').map { _1.strip.downcase.to_sym }
end
  
########################################################################
# Will process data_set['select'] option
# @TODO drops No route matches error, for no apparent reason
########################################################################
def process_select_options(model) #:nodoc:
  data_set = @form['index']['data_set']
  return model unless data_set['select']

  model.select(*data_set['select'].chomp.split(',').map(&:to_sym))
end

########################################################################
# Will check and set sorting options for current dataset. Subroutine of index method.
########################################################################
def check_sort_options #:nodoc:
  table_name = @tables.first[1]
  sort_data = session.dig(:filters, table_name, :sort)
  return unless sort_data && @records.kind_of?(ActiveRecord::Relation)

  sort, direction = sort_data.split(' ')
  @records = @records.order(sort => direction.to_sym)
end

########################################################################
# Return currently defined  filter on a table.
#
# Use in custom form filter: agile_filter_options(ArPage).and(ar_site_id: params[:site_id])
########################################################################
def agile_filter_options(model)
  table_name = @tables.first[1]
  filter_data = session.dig(:filters, table_name)
  ArFilter.get_filter(filter_data) || model.all
end

########################################################################
# Return current sort options for model (table)
########################################################################
def agile_sort_options(model) #:nodoc:
  table_name = model.to_s.underscore
  sort_data = session.dig(:filters, table_name, :sort)
  return if sort_data.nil?

  field, direction = sort_data.split(' ')
  { field.to_sym => direction.to_sym }
end

########################################################################
# Will check and set current filter options for data_set. Subroutine of index method.
########################################################################
def check_filter_options #:nodoc:
  table_name = AgileHelper.table_param(params).strip.split(';').first.underscore
  model      = table_name.classify.constantize
  save_filter_value(params[:page], table_name, :page) if params[:page]
  # if data model has field ar_site_id ensure that only records which belong to the site are selected.
  site_id = agile_get_site.id if agile_get_site

  # don't filter site if no  ar_site_id field or user is ADMIN
  site_id = nil if !model.method_defined?('ar_site_id') || agile_user_can(ArPermission::CAN_ADMIN)
  site_id = nil if session.dig(:filters, table_name, 'filter').to_s.match('ar_site_id')

  if @records = ArFilter.get_filter(session.dig(:filters, table_name))
    @records = @records.where(ar_site_id: site_id) if site_id
  else
    @records = site_id ? model.where(ar_site_id: site_id) : model.all
  end
  # pagination if required
  per_page = (@form['index']['data_set']['per_page'] || 25).to_i
  current_page = session.dig(:filters, table_name, :page) || 1
  @records = @records.page(current_page).per(per_page) if per_page > 0
end

######################################################################
# Save specified filter value to session
######################################################################
def save_filter_value(value, table_name, *parms)
  session[:filters] ||= {}
  session[:filters][table_name] ||= {}
  case parms.size
  when 0 then session[:filters][table_name] = value
  when 1 then session[:filters][table_name][parms[0]] = value
  when 2 then
    session[:filters][table_name][parms[0]] ||= {}
    session[:filters][table_name][parms[0]][parms[1]] = value
  end
  session[:filters][table_name][:updated] = Time.now
end

######################################################################
# Save specified filter value to session
######################################################################
def read_filter_value(table_name, *parms)
  case parms.size
  when 0 then session.dig(:filters, table_name)
  when 1 then session.dig(:filters, table_name, parms[0])
  when 2 then session.dig(:filters, table_name, parms[0], parms[1])
  end
end

########################################################################
# Select data from table for index action
########################################################################
def process_data_set #:nodoc
  # If data_set is not defined on form, then it will fail. :return_to should know where to go
  data_set = @form['index']['data_set']
  if data_set.nil?
    process_return_to(params[:return_to] || 'reload')
    return true
  end
  # when data_set is evaluated as Rails helper
  data_set['type'] ||= 'default'
  return unless data_set['type'] == 'default'

  # for now enable only filtering of top level records
  if @tables.size == 1 
    check_filter_options()
    check_sort_options()
  end  
  # dataset is defined by filter method in control object
  form_filter = data_set['filter'] || 'default_filter'
  if respond_to?(form_filter)
    @records = send(form_filter)
    # something went wrong. flash[:error] should have explanation.
    if @records.class == FalseClass
      @records = []
      render(action: :index)
      return true
    end
    # process_select_options
    # pagination but only if not already set
    unless (@form['table'] == 'ar_memory') #TODO || @records.options[:limit])
      per_page = (data_set['per_page'] || 25).to_i
      @records = @records.page(params[:page]).per(per_page) if per_page > 0
    end
  elsif form_filter != 'default_filter'
     Rails.logger.error "Error: data_set:filter: #{data_set['filter']} not found in controls!"
  end
  false
end

########################################################################
# Process index action for in memory data. default_filter method must fill @records array
# with data, that will be displayed in the browser object.
########################################################################
def process_in_memory #:nodoc
  @records = []
  # dataset is defined by filter method in control object
  if (method = @form['index']['data_set']['filter'] || default_filter)
    send(method) if respond_to?(method)    
  end
  # ensure that record has id field
  if @records.size > 0
    raise "Exception: id field must be set in ar_memory record!" unless @records.first.id
  end
  false
end

########################################################################
# Prevent double form submit
#
# Program will save form_time_stamp to session. If form is saved with
# the same form_time_stamp, program will block create action.
########################################################################
def double_form_submit?
  form_name = AgileHelper.form_param(params) || AgileHelper.table_param(params)
  session[:dfs] ||= {}
  params[:form_time_stamp] = params[:form_time_stamp].to_i
  if params[:form_time_stamp] <= update_dfs_time(form_name)  && !Rails.env.test? # test must be excluded
    flash[:error] = I18n.t('agile.dfs')
    return true
  end

  update_dfs_time(form_name, params[:form_time_stamp])
  false
end

########################################################################
# Updates double_form_submit timings.
########################################################################
def update_dfs_time(form_name, time = nil)
  if time.nil?
    session[:dfs][form_name] || 0
  else
    session[:dfs][form_name] = time
    if session[:dfs].size > 3
      oldest = session[:dfs].invert.min
      session[:dfs].delete(oldest.last)
    end
  end
end

########################################################################
# Loads initial values for new action from cookie or params. Initial values
# are provided in cookies[:record] or in params as table_name.field_name=value
########################################################################
def load_initial_values
  table = @tables.last[1] + '.'
  # initial values set on page
  if cookies[:record].present?
    Marshal.load(cookies[:record]).each do |k, v|
      k = k.to_s
      if k.match(table + '.')
        field = k.split('.').last
        @record.send("#{field}=", v) if @record.respond_to?(field)
      end
    end
  end
  # initial values set in url (params)
  params.each do |k, v|
    if k.match(table + '.')
      field = k.split('.').last
      @record.send("#{field}=", v) if @record.respond_to?(field)
    end
  end
end

end
