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
# AgileEditHelper module defines helper methods used by AgileRails form edit action. Output is controlled by
# data found in 3 major sections of AgileRails form: index, data_set and form sections. 
#
###########################################################################
module AgileEditHelper

############################################################################
# Will return value when internal or additional parameters are defined in action
# Subroutine of agile_actions_for_form.
############################################################################
def agile_value_for_parameter(param, current_document = nil)#:nodoc:
  if param.class == Hash
    agile_internal_var(param['object'] ||= 'record', param['method'], current_document)
  elsif param.to_s.match(/record|document/)
    current_document ? current_document : @record
  else
    param
  end
end

############################################################################
# Creates actions div for edit form.
# 
# Displaying readonly form turned out to be challenge. For now when readonly parameter
# has value 2, back link will force readonly form. Value 1 or not set will result in
# normal link.
############################################################################
def agile_is_action_active?(options)
  return true unless options['active']

  # alias record and document so both can be used in eval
  record = document = @record
  option = options['active']
  case 
  # usually only for test
  when option.class == TrueClass || option['eval'].class == TrueClass then true

  when option.class == String then
    if option.match(/new_record/i)
      (@record.new_record? && option == 'new_record') || (!@record.new_record? && option == 'not_new_record')
    elsif option.match(/\./)
      # shortcut for method and eval option
      agile_process_eval(option, self)
    else
      eval(option['eval'])
    end

  # direct evaluate expression
  when option['eval'] then
    eval(option['eval'])

  # if record present send record otherwise send self as parameter
  when option['method'] then
    agile_process_eval(option['method'], self)

  else
    false
  end  
end

############################################################################
# Creates actions div for edit form.
# 
# Displaying readonly form turned out to be challenge. For now when readonly parameter
# has value 2, back link will force readonly form. Value 1 or not set will result in
# normal link.
############################################################################
def agile_actions_for_form(position)
  actions_pos = agile_check_and_default(@form['form']['actions_position'], Agile.config(:default_actions_position), %w[top bottom both])
  return '' if actions_pos != 'both' && (position != actions_pos)# == 'bottom') || (position == 'bottom' && actions_pos == 'top')

  # create standard actions
  actions = @form['form']['actions'] || {}
  std_actions = Agile.config(:form_standard_actions)
  std_actions = { 1 => 'back' } if @form['readonly']   # readonly
  if actions.class == String
    actions = process_standard_actions(actions, std_actions)
  elsif actions['standard']
    actions.merge!(std_actions)
    actions.delete('standard')
  end

  # some actions have meaning only when editing
  if @record.try(:id).nil?
    actions_remove_action(actions, 'new', 'enable', 'refresh')
    # enable disable if active field is present
  elsif @record.has_attribute?(:active)
    index = actions.find { |k, v| v.is_a?(String) && v == 'enable' }
    actions[index.first] = (@record.active ? 'disable' : 'enable') if index
  else
    actions_remove_action(actions, 'enable')
  end
  # Actions are strictly forbidden
  if @form['form']['actions'] && agile_dont?(@form['form']['actions'])
    actions = []
  end

  # request for close window button present
  if actions.kind_of?(Hash) && params[:window_close].present?
    case params[:window_close].to_i
    when 0
      actions[1] = 'close'
      actions_remove_action(actions, 'new')

    when 1, 2
      actions = { 1 => 'close' }
    end
    # if save & back present with close action change it to save
    index = actions.find { |k, v| v.is_a?(String) && v == 'save&back' }
    actions[index.first] = 'save' if index
  end

  # select only integer keys and sort
  actions = actions.to_a.select{ _1.first.is_a?(Integer) }.sort{ |x, y| x[0] <=> y[0] }
  # Add spinner to the beginning
  html = %(<span class="ar-spinner">#{mi_icon('settings-o spin')}</span><ul class="ar-edit-menu #{position}">)

  actions.each do |key, options|
    session[:form_processing] = "form:actions: #{key} #{options}"
    next if options.nil?  # yes it happens

    parms = @form_params.clone
    if options.class == String
      next if @form['readonly'] && !options.match(/back|close/)

      partial =
        case options

        when 'save&back', 'save'
          html += form_submit_action(options) # already comes with li tags
          next

        when 'back', 'cancel'
          # If return_to is present link directly to URL
          if parms['xreturn_to'] # disabled for now
            agile_link_to( 'agile.back', 'arrow_back', parms['return_to'], class: 'ar-link' )
          else
            parms['action']   = 'index'
            parms['readonly'] = parms['readonly'].to_s.to_i < 2 ? nil : 1

            agile_link_to( 'agile.back', 'arrow_back', parms, class: 'ar-link' )
          end

        when 'new'
          parms['action'] = options
          agile_link_to( 'agile.new', 'add', parms, class: 'ar-link')

        when 'enable', 'disable'
          parms['operation'] = options
          parms['id']        = @record.id
          icon = (options == 'enable' ? 'check_box-o' : 'check_box_outline_blank')
          agile_link_to( "agile.#{options}",icon, parms, method: :delete, class: 'ar-link' )

        when 'refresh'
          %(<div class="ar-link refresh">#{mi_icon('refresh')} #{t('agile.refresh')}</div>)
          
        when 'close'
          close = params[:window_close].to_i
          if close < 2
            %(<div class="ar-link close">#{mi_icon('close')} #{t('agile.close')}</div>)
          else
            %(<div class="ar-link back">#{mi_icon('close')} #{t('agile.close')}</div>)
          end

        else
          "err1 #{key}=>#{options}"
        end
      html += "<li>#{partial}</li>"

    # non standard actions      
    else
      # action will be displayed when show: always or readonly option is declared and form is readonly
      next if @form['readonly'] && !%w[readonly always].include?(options['show'].to_s)

      options['title'] = t("#{options['title'].downcase}", options['title']) if options['title']
      html +=
        case
        # submit button
        when options['type'] == 'submit'
          form_submit_action(options)

        # ajax or link button
        when %w(ajax link window popup).include?(options['type'])
          agile_link_ajax_window_submit_action(options, @record)

        # Javascript action
        when options['type'] == 'script'
          agile_script_action(options)
        else
          '<li>err2</li>'
        end
    end

  end
  (html += '</ul>').html_safe
end

############################################################################
# Create background div and table definitions for dataset.
############################################################################
def agile_background_for_dataset(start)
  if start == :start
    style = @form.dig('index', 'data_set', 'table_style')
    html  = '<div class="ar-result-div" '
    html += (style ? 'style="overflow-x: scroll;" >' : '>')

    html += "\n<div class=\"ar-result #{@form['index']['data_set']['table_class']}\" "
    html += ( style ? "style=\"#{style}\" >" : '>')
  else
    html = '</div></div>'
  end
  html.html_safe
end

############################################################################
# Checks if value is defined and sets default. If values are sent it also checks
# if value is found in values. If not it will report error and set value to default.
# Subroutine of agile_fields_for_tab.
############################################################################
def agile_check_and_default(value, default, values = nil) # :nodoc:
  return default if value.nil?

  # check if value is within allowed values
  if values && !values.index(value)
    # parameters should be in downcase
    if n = values.index(value.downcase)
      return values[n]
    else
      logger.error("AgileRails Forms: Value #{value} not within values [#{values.join(',')}]. Default #{default} used!")
      return default
    end
  end
  value
end

############################################################################
# Creates input fields defined in form options
############################################################################
def agile_fields_for_form
  html = '<div id="data_fields" ' + (@form['form']['height'] ? "style=\"height: #{@form['form']['height']}px;\">" : '>')
  @js  ||= ''
  @css ||= ''
  # fields
  if (form_fields = @form['form']['fields'])
    html += "#{agile_input_form(form_fields)}</div>"
  elsif @form['form']['tabs'] #tabs
    html = agile_tabs_form()
  end
  # add last_updated_at hidden field so controller can check if record was updated in db during editing
  html += hidden_field(nil, :last_updated_at, value: @record.updated_at.to_i) if @record.respond_to?(:updated_at)
  # add form time stamp to prevent double form submit
  html += hidden_field(nil, :form_time_stamp, value: Time.now.to_i)
  # add javascript code if defined by form
  @js  += "\n#{@form['script']} #{@form['js']}"
  @css += "\n#{@form['css']}\n#{@form['form']['css']}"
  html.html_safe
end

############################################################################
# Creates head form div. Head form div is used to display header data useful
# to be seen even when tabs are switched.
############################################################################
def agile_head_for_form
  @css ||= ''
  head = @form['form']['head']
  return '' if head.nil?

  html    = %(<div class="ar-head #{head['class']}">\n<div class="ar-row">)
  split   = head['split'] || 4
  percent = 100/split
  current = 0
  head_fields = head.select {|field| field.class == Integer }
  head_fields.to_a.sort.each do |number, options|
    session[:form_processing] = "form: head: #{number}=#{options}"
    # Label
    caption = options['caption']
    span    = options['span'] || 1
    @css += "\n#{options['css']}" unless options['css'].blank?
    label = if caption.blank?
      ''
    elsif options['name'] == caption
      t_label_for_field(options['name'], options['name'].capitalize.gsub('_',' ') )
    else
      t(caption, caption)
    end
    # Field value
    begin
      field = if options['eval']
        agile_process_column_eval(options, @record)
      else
        @record.send(options['name'])
      end
    rescue Exception => e
      agile_log_exception(e, 'agile_head_for_form')
      field = '!!!Error'
    end
    #
    klass = agile_style_or_class(nil, options['class'], field, @record)
    style = agile_style_or_class(nil, options['style'], field, @record)
    html += %(<div class="ar-column #{klass}" style="width:#{percent*span}%;#{style}">
  #{label.blank? ? '' : "<span class=\"label\">#{label}</span>"}
  <span id="head-#{options['name']}" class="field">#{field}</span>
</div>)
    current += span
    if current == split
      html += %(</div>\n<div class="ar-row">)
      current = 0
    end
  end
  html += '</div></div>'
  html.html_safe
end

############################################################################
# Returns username for id. Subroutine of agile_document_statistics
###########################################################################
def agile_document_user_for(field_name) #:nodoc:
  return if @record[field_name].nil?

  user = ArUser.find(@record[field_name])
  user ? user.name : @record[field_name]
end

############################################################################
# Creates current document statistics div (created_by, created_at, ....) at the bottom of edit form.
# + lots of more. At the moment also adds icon for dumping current record as json text.
############################################################################
def agile_document_statistics
  return '' if @record.id.nil? || agile_dont?(@form['form']['info'])

  html =  %(<div id="ar-document-info">#{mi_icon('info md-18')}</div> <div id="ar-document-info-popup" class="div-hidden">)
  u = agile_document_user_for('created_by')
  html += %(<div><span>#{t('agile.created_by', 'Created by')}: </span><span>#{u}</span></div>) if u
  u = agile_document_user_for('updated_by')
  html += %(<div><span>#{t('agile.updated_by', 'Updated by')}: </span><span>#{u}</span></div>) if u

  html += %(<div><span>#{t('agile.created_at', 'Created at')}: </span><span>#{agile_format_value(@record.created_at)}</span></div>) if @record['created_at']
  html += %(<div><span>#{t('agile.updated_at', 'Updated at')}: </span><span>#{agile_format_value(@record.updated_at)}</span></div>) if @record['updated_at']
  # copy to clipboard icon
  parms = params.clone
  parms[:controller] = :agile_common
  parms[:action]     = :copy_clipboard
  url = url_for(parms.permit!)
  html += '<div>'
  html += mi_icon('content_copy-o md-18', class: 'ar-link-img ar-link-ajax',
                  'data-url' => url, 'data-request' => 'get', title: t('agile.copy_clipboard') )

  url = url_for(controller: :agile, action: :run, table: 'ar_journal', control: 'agile.filter_on',
                filter_oper: 'eq', filter_field: 'id', filter_value: "#{@form['table']};#{@record.id}")

  html += mi_icon('history md-18', class: 'ar-link-img ar-window-open',
                  'data-url' => url, title: t('helpers.label.ar_journal.table_title') )
  html += %(<span>ID: </span>
            <span id="record-id" class="hover" onclick="agile_copy_to_clipboard('record-id');" title="Copy document ID to clipboard">#{@record.id}
            </span>)

  (html += '</div></div>').html_safe
end

############################################################################
# Updates form prior to processing form
############################################################################
def agile_update_form
  # update form for steps options
  if @form.dig('form', 'steps')
    agile_update_form_steps
  end
end

############################################################################
# If form is divided into two parts, this method gathers html to be painted
# on right side of the form pane.
############################################################################
def agile_form_left
  yaml = @form.dig('form', 'form_left')
  return '' unless yaml

  html = ''
  html += agile_process_eval(yaml['eval'], self) if yaml['eval']

  html.html_safe
end

private

############################################################################
# Creates top or bottom horizontal line on form.
#
# @param [String] location (top or bottom)
# @param [Object] options yaml field definition
#
# @return [String] html code for drawing a line
############################################################################
def agile_top_bottom_line(location, options)
  if options["#{location}-line"] || options['line'].to_s == location.to_s
    '</div><div class="ar-form-section"><div class="ar-separator"></div>'
  else
    ''
  end
end

############################################################################
# Creates submit action on form. Subroutine of agile_actions_for_form.
############################################################################
def form_submit_action(options) #:nodoc:
  if options.is_a?(String)
    options = { 'type' => 'submit', 'caption' => t("agile.#{options}"), 'params' => {} }
  end
  caption = options['caption'] || 'agile.save'
  icon    = options['icon'] || 'save'
  parameters = {}
  options['params'].each { |k, v| parameters[k] = agile_value_for_parameter(v) } if options['params']
  if agile_is_action_active?(options)
    '<li>' +
      agile_submit_tag(caption, icon, { data: parameters, title: options['title'] }) +
      '</li>'
  else
    %(<li><div class="ar-link-no">#{mi_icon(icon)} #{caption}</div></li>)
  end
end

############################################################################
# Creates input fields for one tab. Subroutine of agile_fields_for_form.
############################################################################
def agile_input_form(fields_on_tab) #:nodoc:
  html = '<div class="ar-form"><div class="ar-form-section">'
  labels_pos = agile_check_and_default(@form['form']['labels_position'], Agile.config(:default_labels_position), %w[top left])
  hidden_fields = ''
  group_option, group_count = 0, 0
  # Select form fields and sort them by key
  form_fields = fields_on_tab.select { |field| field.is_a?(Integer) }
  form_fields.to_a.sort.each do |number, options|
    session[:form_processing] = "form:fields: #{number}=#{options}"
    # ignore if edit_only singe field is required
    next if params[:edit_only] && params[:edit_only] != options['name']
    next if options.nil?

    # hidden_fields. Add them at the end
    if options['type'] == 'hidden_field'
      hidden_fields << AgileFormFields::HiddenField.new(self, @record, options).render
      next
    end
    # label
    field_html, label, help = agile_field_label_help(options)
    no_help = help.blank? ? ' no-help' : ''
    label = nil if agile_dont?(options['caption'])
    # Line separator
    html += agile_top_bottom_line(:top, options)
    # Beginning of new row
    if group_count == 0
      html += '<div class="row-div">'
      group_count  = options['group'] || 1
      group_option = options['group'] || 1
    end
    html += if labels_pos == 'top'
              data_width = case group_option
                           when 2 then (group_count == 2 ? 40 : 70)
                           when 3 then [30, 30, 40][group_count - 1]
                           else 100
                           end
              label = label.nil? ? '' : %(<label for="record_#{options['name']}">#{label} </label>)
              %(
<div class="ar-form-label-top ar-align-left ar-width-#{data_width}#{no_help}" title="#{help}">
  #{label}
  <div id="td_record_#{options['name']}">#{field_html}</div>
</div> )
            else
              # no label
              if label.nil?
                label = ''
                label_width = 0
                data_width  = 100
              elsif group_option > 1
                label_width = group_option != group_count ? 10 : 14
                data_width  = 21
              else
                label_width = 14
                data_width  = 85
              end
              help.gsub!('<br>',"\n") if help.present?
              %(
<div class="ar-form-label ar-align-right ar-width-#{label_width}#{no_help}" title="#{help}">
  <label for="record_#{options['name']}">#{label} </label>
</div>
<div id="td_record_#{options['name']}" class="ar-form-field ar-width-#{data_width}">#{field_html}</div>
)
            end
    # check if group end
    if (group_count -= 1) == 0
      html += '</div>'
      # insert dummy div when only two fields in group
      html += '<div></div>' if group_option == 2
    end

    html += agile_top_bottom_line(:bottom, options)
  end
  html += '</div></div>' + hidden_fields
end

############################################################################
# Will create html code required for input form with steps defined
############################################################################
def agile_steps_one_element(element, tab_name = nil)
  def add_one_step(key, tab_name, key_number)
    fields = tab_name ? @form['form']['tabs'][tab_name] :  @form['form']['fields']
    { key_number => fields[key] }
  end

  key_number, fields = 0, {}
  element.to_s.split(',').each do |particle|
    if particle.match('-')
      tabs_fields = tab_name ? @form['form']['tabs'][tab_name] : @form['form']['fields']
      next if tabs_fields.nil?

      start, to_end = particle.split('-').map(&:to_i)
      tabs_fields.each_key { |key| fields.merge!(add_one_step(key, tab_name, key_number += 10)) if (start..to_end).include?(key) }
    else
      fields.merge!(add_one_step(particle.to_i, tab_name, key_number += 10))
    end
  end
  fields
end

############################################################################
# Will create html code required for input form with steps defined and update
# actions.
############################################################################
def agile_update_form_steps
  def add_step_to_form(index, step, next_step)
    @form['form']['actions'][index]['params']['step'] = step
    @form['form']['actions'][index]['params']['next_step'] = next_step
  end

  form = {}
  step = params[:step].to_i
  step_data = @form['form']['steps'].to_a[step - 1]

  step_data.last.each do |element|
    if element.first == 'fields'
      form.merge!(agile_steps_one_element(element.second))
    elsif element.first == 'tabs'
      element.last.each do |tab_name, data|
        form.merge!(agile_steps_one_element(data, tab_name))
      end
    end
  end
  # fraction updates of newly created form
  form.deep_merge!(step_data.last['update']) if step_data.last['update']
  # update steps data on form
  add_step_to_form(10, step, step - 1)
  add_step_to_form(20, step, step + 1)
  add_step_to_form(100, step, step + 1)
  # remove not needed steps
  if step < 2
    @form['form']['actions'].delete(10)
  elsif step == @form['form']['steps'].size
    @form['form']['actions'].delete(20)
  end
  @form['form']['actions'].delete(100) unless step == @form['form']['steps'].size
  # update form_name and control name if defined
  %w[1 10 20 100].each do |i|
    next unless @form['form']['actions'][i.to_i]

    @form['form']['actions'][i.to_i]['form_name'] = AgileHelper.form_param(params)
    control = @form['control'] ? @form['control'] : @form['table']
    @form['form']['actions'][i.to_i]['control'].sub!('x.', "#{control}.")
  end

  @form['form']['form_left'] ||= { 'eval' => 'agile_steps_menu_get'}
  @form['form']['fields'] = form
end

############################################################################
# Will create html code required for input form with tabs
############################################################################
def agile_tabs_form
  html, tabs, tab_data = '', [], ''
  first_tab = true # first tab
  tab_type  = @form['form']['type'] || 'default'
  tab_class = @form['form']['class'] || ''
  tab_style = @form['form']['style'] || ''

  @form['form']['tabs'].keys.sort.each do |tab_name|
    next if tab_name.match('options')

    # Tricky when editing single field. If field is not present on the tab skip to next tab
    if params[:edit_only]
      is_on_tab = false
      @form['form']['tabs'][tab_name].each_value { |v| is_on_tab = true if params[:edit_only] == v['name'] }
      next unless is_on_tab
    end
    tab_index = tab_name.delete("\s\n")
    tab_label, tab_title = agile_tab_label_help(tab_name)
    tabs << [tab_name, tab_label, tab_title, tab_index]

    klass = "#{tab_type == 'accordion' ? 'ar-accordion' : ''} ar-form-accordion #{first_tab ? 'open' : ''} #{tab_class}"
    tab_data += %(<div id="acc_#{tab_index}" class="#{klass}" title="#{tab_title}">#{tab_label}</div>)
    tab_data += %(<div id="data_#{tab_index}")
    tab_data += ' class="div-hidden"' unless first_tab
    tab_data += (@form['form']['style'] ? %( style="#{tab_style};">) : '>')
    tab_data += "#{agile_input_form(@form['form']['tabs'][tab_name])}</div>"
    first_tab = false
  end

  if tab_type != 'accordion' #
    # make it all work together
    html += '<ul class="ar-form-ul" >'
    first = true # first tab must be selected
    tabs.each do |tab_name, tab_label, tab_title, tab_index|
      html += %(<li id="li_#{tab_index}" data-div="#{tab_index}" title="#{tab_title}" class="ar-form-li)
      html += ' ar-form-li-selected' if first
      html += "\">#{tab_label}</li>"
      first = false
    end
    html += '</ul>'
  end
  html + tab_data
end

end
