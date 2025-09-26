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
# AgileIndexHelper module defines helper methods used by AgileRails actions. Output is controlled by
# data found in 3 major sections of AgileRails form: index, data_set and form sections.
#
###########################################################################
module AgileIndexHelper

############################################################################
# Creates action div for AgileRails index action.
############################################################################
def agile_actions_for_index
  @js  = @form['script'] || @form['js'] || ''
  @css = @form['css'] || ''
  return '' if @form['index'].nil?

  actions = @form['index']['actions']
  return '' if actions.nil?

  std_actions = Agile.config(:index_standard_actions)
  if actions.instance_of?(String)
    actions = process_standard_actions(actions, std_actions)
  elsif actions['standard']
    actions.merge!(std_actions)
    actions.delete('standard')
  end
  # remove new if readonly
  actions_remove_action(actions, 'new') if @form['readonly']

  html_left, html_right = '', ''
  # Remove actions settings and sort
  only_actions = actions.select{ |k, v| k.instance_of?(Integer) }.sort_by(&:first).map(&:last)
  only_actions.each do |options|
    next if options.nil? # must be

    url    = @form_params.clone
    yaml   = options.instance_of?(String) ? { 'type' => options } : options # if single definition simulate type parameter
    action = yaml['type'].to_s.downcase
    # if return_to is present link directly to URL
    if action == 'link' && yaml['url']
      url = yaml['url']
    else
      url['controller'] = yaml['controller'] if yaml['controller']
      url['action']     = yaml['action'] || action
      url['table']      = yaml['table']  if yaml['table']
      url['form_name']  = yaml['form_name'] if yaml['form_name']
      url['control']    = yaml['control'] if yaml['control']
    end
    # html link options
    html_options = yaml['html'] || {}
    html_options['title'] = yaml['title'] if yaml['title']
    html = case action
           # new
           when 'new'
             caption = yaml['caption'] || 'agile.new'
             html_options['class'] = 'ar-link'
             "<li>#{agile_link_to(caption, 'add', url, html_options)}</li>"

           # filter
           when 'filter'
             # filter off is not present
             no_off = session.dig(:filters, @form['table'], :filter, :no_off)
             next if no_off

             url = ''
             if session.dig(:filters, @form['table'], :filter)
               url = url_for(controller: :agile, action: :run, control: 'agile.filter_off', t: @form['table'], f: AgileHelper.form_param(params))
             end
             yaml['position'] ||= 'right'
             %(
<li>
  <div class="ar-filter" title="#{ArFilter.title_for_filter_off(session.dig(:filters, @form['table']))}" data-url="#{url.html_safe}">
    #{mi_icon(url.blank? ? 'search' : 'filter_alt_off') }#{ArFilter.filter_menu(self).html_safe}
  </div>
</li>#{ArFilter.get_filter_input_field(self)}).html_safe

           # close
           when 'close'
             %(<li><div class="ar-link" onclick="window.close();"'>#{mi_icon('close')} #{t('agile.close')}</div></li>)

           # back
           when 'back'
             %(<li><div class="ar-link" onclick="history.back();"'>#{mi_icon('arrow_back')} #{t('agile.back')}</div></li>)

           # menu
           when 'menu'
             code = if options['caption']
                      caption = "#{t(options['caption'], options['caption'])}&nbsp;#{mi_icon('caret-down')}"
                      caption + agile_process_eval(options['eval'], self)
                    else # when caption is false, provide own actions
                      agile_process_eval(options['eval'], self)
                    end
             %(<li><div class="ar-link">#{code}</div></li>)
=begin
# reorder      
    when action == 'reorder' then  
      caption = t('agile.reorder')
      parms = @form_params.clone
      parms['operation'] = v
      parms['id']       = params[:ids]
      parms['table']     = @form['table']
      agile_link_to( caption, 'reorder', parms, method: :delete )              
=end

           when 'script'
             agile_script_action(options)

           when 'field'
             yaml['position'] ||= 'right'
             agile_field_action(yaml)

           when 'ajax', 'link', 'window', 'popup', 'submit'
             agile_link_ajax_window_submit_action(options, nil)

           # sort
           when 'sort'
             yaml['position'] ||= 'right'
             choices = [%w[id id]]
             @form['index']['sort']&.split(',')&.each do |e|
               e.strip!
               choices << [t("helpers.label.#{@form['table']}.#{e}"), e]
             end
             data = mi_icon('sort') + select('sort', 'sort', choices, { include_blank: true },
                                             { class: 'ar-sort-select', 'data-table' => @form['table'],
                                               'data-form' => AgileHelper.form_param(params)})
             %(<li title="#{t('agile.sort')}"><div class="ar-sort">#{data}</li>)

           # link
           else
             caption = agile_get_caption(yaml) || t("agile.#{action}")
             icon    = yaml['icon'] || action
             html_options['class'] = 'ar-link'
             code = agile_link_to(caption, icon, url, html_options)
             html_left += %(<li>#{code}</li>)
           end
    yaml['position'] ||= 'left'
    if yaml['position'] == 'left'
      html_left += html
    else
      html_right += html
    end
  end

  %(
<form id="ar-action-menu">
  <span class="ar-spinner">#{mi_icon('settings-o spin')}</span>

  <div class="ar-action-menu">
    <ul class="ar-left">#{html_left}</ul>
    <ul class="ar-right">#{html_right}</ul>
  </div>
<div style="clear: both;"></div>
</form>
  ).html_safe
end

############################################################################
# Paints div for set filter popup
############################################################################
def agile_div_filter
  choices = []
  filter = (@form.dig('index', 'filter') || '').split(',').delete_if { _1 == 'id' }.map(&:strip)
  filter << 'id as text_field' # filter for id is added by default
  filter.each do |f|
    f = f.strip
    name = f.match(' as ') ? f.split(' ').first : f
    # like another field on the form
    choices << [t("helpers.label.#{@form['table']}.#{name}", name), f]
  end
  choices_for_operators = t('agile.choices_for_filter_operators').chomp.split(',').map do |v|
    v.match(':') ? v.split(':') : v
  end
  # currently selected options
  field_name, operators_value = nil, nil
  filter = session.dig(:filters, @form['table'], :filter)
  if filter
    field_name = filter[:field]
    operators_value = filter[:value]
  end
  url_on  = url_for(controller: :agile, action: :run, control: 'agile.filter_on' ,
                    t: AgileHelper.table_param(params), f: AgileHelper.form_param(params), filter_input: 1)
  url_off = url_for(controller: :agile, action: :run, control: 'agile.filter_off',
                    t: AgileHelper.table_param(params), f: AgileHelper.form_param(params))
  %(
  <div id="ar_filter" class="div-hidden">
    <h1>#{t('agile.filter_set')}</h1>

    #{ select(nil, 'filter_field1', options_for_select(choices, field_name), { include_blank: true }) }
    #{ select(nil, 'filter_oper', options_for_select(choices_for_operators, operators_value)) }
    <div class="ar-edit-menu">
      <div class="ar-link ar-filter-set" data-url="#{url_on}">#{mi_icon('done')} #{t('agile.filter_on')}</div>
      <div class="ar-link-ajax" data-url="#{url_off}">
         #{mi_icon('close')}#{t('agile.filter_off')}
      </div>
    </div>
  </div>).html_safe
end

############################################################################
# Creates popup div for setting filter on dataset header.
############################################################################
def agile_filter_popup
  html = %(<div class="filter-popup" style="display: none;"><div>#{t('agile.filter_set')}</div><ul>)
  url  = url_for(controller: :agile, action: :run, control: 'agile.filter_on',
                 t: @form['table'], f: params['form_name'], filter_input: 1)

  t('agile.choices_for_filter_operators').chomp.split(',').each do |operator_choice|
    caption, choice = operator_choice.split(':')
    html += %(<li data-operator="#{choice}" data-url="#{url}">#{caption}</li>)
  end 
  "#{html}</ul></div>".html_safe
end

############################################################################
# Will return title based on @form['title']
############################################################################
def agile_form_title
  return t("helpers.label.#{@form['table']}.table_title", @form['table'])  if @form['title'].nil?
  return t(@form['title'], @form['title']) if @form['title'].instance_of?(String)

  # Hash
  agile_process_eval(@form['title']['eval'], [@form['title']['caption'] || @form['title']['text'], params])
end

############################################################################
# Creates title div for index action. Title div also includes paging options
# and help link
############################################################################
def agile_title_for_index(result = nil)
  agile_dialog_title(agile_form_title(), result)
end

############################################################################
# Determines actions and width of actions column
############################################################################
def agile_dataset_actions
  actions = @form['index']['data_set']['actions']
  return [{}, 0, false] if actions.nil? || agile_dont?(actions)

  std_actions = Agile.config(:dataset_standard_actions)
  if actions.instance_of?(String)
    actions = process_standard_actions(actions, std_actions)
  elsif actions['standard']
    actions.merge!(std_actions)
    actions.delete('standard')
  end

  # check must be 0 action
  has_check = actions[0] && actions[0] == 'check'
  width = actions.size == 1 ? 22 : 44
  width = 22 if actions.size > 2 && !has_check
  [actions, width, has_check]
end

############################################################################
# Calculates (blank) space required for actions when @footer_record is rendered
############################################################################
def agile_dataset_actions_for_footer
  return '' unless @form['index']['data_set']['actions']

  ignore, width, ignore2 = agile_dataset_actions()
  %(<div class="ar-result-actions" style="width: #{width}px;"></div>).html_safe
end

############################################################################
# Creates actions that could be performed on single row of dataset.
############################################################################
def agile_actions_for_dataset(record)
  actions = @form['index']['data_set']['actions']
  return '' if actions.nil? || @form['readonly']

  actions, width, has_check = agile_dataset_actions()
  has_sub_menu = actions.size > 2 || (has_check && actions.size > 1)

  main_menu, sub_menu = '', ''
  actions.sort_by(&:first).each do |num, action|
    session[:form_processing] = "data_set:actions: #{num}=#{action}"
    parms = @form_params.clone

    # if single definition simulate type parameter
    yaml = action.instance_of?(String) ? { 'type' => action } : action

    if %w[ajax link window popup submit].include?(yaml['type'])
      @record = record # otherwise record fields can't be used as parameters
      html = agile_link_ajax_window_submit_action(yaml, record)
    else
      caption = agile_get_caption(yaml) || "agile.#{yaml['type']}"
      title   = t(yaml['help'] || caption, '')
      caption = has_sub_menu ? t(caption, '') : nil
      html = '<li>'
      html += case yaml['type']
      when 'check'
        main_menu += "<li>#{check_box_tag("check-#{record.id}", false, false, { class: 'ar-check' })}</li>"
        next

      when 'edit'
        parms['action'] = 'edit'
        parms['id'] = record.id
        agile_link_to( caption, 'edit-o', parms, title: title )

      when 'show'
        parms['action'] = 'show'
        parms['id'] = record.id
        parms['readonly'] = true
        agile_link_to( caption, 'eye', parms, title: title )

      when 'duplicate'
        parms['id'] = record.id
        # duplicate string will be added to these fields.
        parms['dup_fields'] = yaml['dup_fields'] 
        parms['action'] = 'create'
        agile_link_to( caption, 'content_copy-o', parms, data: { confirm: t('agile.confirm_dup') }, method: :post, title: title )

      when 'delete'
        parms['action'] = 'destroy'
        parms['id'] = record.id
        agile_link_to( caption, 'delete-o', parms, data: { confirm: t('agile.confirm_delete') }, method: :delete, title: title )

      else # error.
        yaml['type'].to_s
      end
      html += '</li>'
    end

    if has_sub_menu
      sub_menu += html
    else
      main_menu += html
    end
  end

  if has_sub_menu
    %(
<ul class="ar-result-actions" style="width: #{width}px;">#{main_menu}
  <li><div class="ar-result-submenu">#{mi_icon('more_vert')}
    <ul id="menu-#{record.id}">#{sub_menu}</ul>
  </div></li>
</ul>)
  else
    %(<ul class="ar-result-actions" style="width: #{width}px;">#{main_menu}</ul>)
  end.html_safe
end

############################################################################
# Creates header div for dataset.
############################################################################
def agile_header_for_dataset
  html = '<div class="ar-result-header">'
  if @form['index']['data_set']['actions'] && !@form['readonly']
    ignore, width, has_check = agile_dataset_actions()
    check_all = mi_icon('check-box-o', class: 'ar-check-all') if has_check
    html += %(<div class="ar-result-actions" style="width:#{width}px;">#{check_all}</div>)
  end
  # preparation for sort icon  
  sort_data = session.dig(:filters, @form['table'], :sort)
  sort_field, sort_direction = sort_data.to_s.split(' ')
  filter_fields = (@form.dig('index', 'filter') || '').split(',').map(&:strip)
  if (columns = @form['index']['data_set']['columns'])
    columns.sort.each do |key, options|
      session[:form_processing] = "data_set:columns: #{key}=#{options}"
      next if options['width'].to_s.match(/hidden|none/i)

      th = %(<div class="th" style="width:#{options['width'] || '15%'};text-align:#{options['align'] || 'left'};" data-name="#{options['name']}")
      label = t_label_for_column(options)
      # no sorting when embedded records or custom filter is active
      sort_ok = !agile_dont?(@form['index']['data_set']['sort'], false)
      sort_ok ||= @form['index'] && @form['index']['sort']
      sort_ok &&= !agile_dont?(options['sort'], false)
      if sort_ok
        icon = 'sort_unset md-18'
        # add filter helper only if field name exists in filter option and field is defined in form
        filter_class =  can_include_filter_shortcut?(options['name']) ? nil : 'no-filter'
        if options['name'] == sort_field
          icon = sort_direction == 'desc' ? 'sort_down md-18' : 'sort_up md-18'
        else
          # no icon if filter can not be set
          icon = nil if filter_class || session.dig(:filters, @form['table'], :filter, :no_off)
        end
        # sort and filter icon
        icon = mi_icon(icon, class: filter_class) if icon
        url = url_for(controller: :agile, action: :run, control: 'agile.sort', sort: options['name'],
                      t: AgileHelper.table_param(params), f: AgileHelper.form_param(params))
        th += %(><span data-url="#{url}">#{label}</span>#{icon}</div>)
      else
        th += ">#{label}</div>"
      end
      html += "<div class=\"spacer\"></div>#{th}"
    end
  end
  "#{html}</div>".html_safe
end

############################################################################
# Creates link for single or double click on dataset column
############################################################################
def dblclick_on_dataset_action(record)
  html = ''
  if @form['index']['data_set']['dblclick']
    yaml = @form['index']['data_set']['dblclick']
    opts = { id: record.id }
    opts[:controller] = yaml['controller'] || :agile
    opts[:action]     = yaml['action']
    opts[:table]      = yaml['table'] || AgileHelper.table_param(params)
    opts[:form_name]  = yaml['form_name'] || AgileHelper.form_param(params) || opts[:table]
    opts[:method]     = yaml['method'] || 'get'
    opts[:readonly]   = yaml['readonly'] if yaml['readonly']
    opts[:window_close] = yaml['window_close'] if yaml['window_close']
    url_forward_params(opts)

    html += " data-dblclick=#{url_for(opts)}"
  else
    opts = { action: :show,
             controller: :agile,
             id: record.id,
             ids: params[:ids],
             readonly: (params[:readonly] ? 2 : 1),
             table: AgileHelper.table_param(params),
             form_name: AgileHelper.form_param(params) }
    url_forward_params(opts)
     html += " data-dblclick=#{url_for(opts)}" if @form['form']
  end
  html
end

############################################################################
# Formats value according to format supplied or data type. There is lots of things missing here.
############################################################################
def agile_format_value(value, format = nil)
  return '' if value.blank?

  klass = value.class.to_s
  return AgileHelper.format_date_time(value, format) if klass.match(/time|date/i)

  format = format.to_s.upcase
  if format[0] == 'N'
    return '' if value.to_f == 0.0 && format.match('Z')

    format.gsub!('Z', '')
    dec = format[1].blank? ? nil : format[1].to_i
    sep = format[2].blank? ? nil : format[2]
    del = format[3].blank? ? nil : format[3]
    cur = format[4].blank? ? nil : format[4]
    agile_format_number(value, dec, sep, del, cur)
  else
    value.to_s
  end
end

############################################################################
# Creates tr code for each row of dataset.
############################################################################
def agile_row_for_dataset(record)
  clas  = "ar-#{cycle('odd','even')} " + agile_style_or_class(nil, @form['index']['data_set']['tr_class'], nil, record)
  style = agile_style_or_class('style', @form['index']['data_set']['tr_style'], nil, record)
  %(<div  id="#{record.id}" class="ar-result-data #{clas}" #{dblclick_on_dataset_action(record)} #{style}>).html_safe
end

############################################################################
# Creates column for each field of dataset record.
############################################################################
def agile_columns_for_dataset(record)
  data_set = @form['index']['data_set']
  return '' unless data_set['columns']

  html, index = '', 0
  data_set['columns'].sort.each do |k, v|
    session[:form_processing] = "data_set:columns: #{k}=#{v}"
    next if v['width'].to_s.match(/hidden|none/i)

    # convert shortcut to hash 
    v = { 'name' => v } if v.instance_of?(String)
    begin
              # as Array (footer)
      value = if record.instance_of?(Array)
                agile_format_value(record[index], v['format']) if record[index]
              # as Hash (ar_memory)
              elsif record.instance_of?(Hash)
                agile_format_value(record[ v['name'] ], v['format'])
              # eval
              elsif v['eval']
                agile_process_column_eval(v, record)
              # as field
              elsif record.respond_to?(v['name'])
                agile_format_value(record.send( v['name'] ), v['format'])
              else
                "??? #{v['name']}"
              end
    rescue Exception => e
      agile_log_exception(e, 'agile_columns_for_dataset')
      value = '!!!Error'
    end
    html += '<div class="spacer"></div>'
    # set column class
    class_ = agile_style_or_class(nil, v['td_class'], value, record)
    # set width and align an additional style
    style = agile_style_or_class(nil, v['td_style'] || v['style'], value, record)
    flex_align  = v['align'].to_s == 'right' ? 'flex-direction:row-reverse;' : ''
    width_align = "width:#{v['width'] || '15%'};#{flex_align}"
    style = %(style="#{width_align}#{style}" )

    html += %(<div class="td #{class_}" #{style}>#{value}</div>)
    index += 1
  end
  html.html_safe
end

############################################################################
# Split eval expression to array by parameters.
# Ex. Will split agile_text_for_value(one ,"two") => ['agile_text_for_value', 'one', 'two']
############################################################################
def agile_eval_to_array(expression)
  expression.split(/[ ,()]/).select(&:present?).map { _1.gsub(/['"]/, '').strip }
end

private

############################################################################
# Process eval. Breaks eval option and calls with send method.
# Parameters:
#   evaluate : String : Expression to be evaluated
#   parameters : Array : array of parameters which will be send to method
############################################################################
def agile_process_eval(evaluate, parameters)
  # evaluate by calling send method
  clas, method = evaluate.split('.')
  return send(clas, *parameters) if method.nil? && respond_to?(clas)

  if method
    klass = clas.camelize.constantize rescue nil
    return klass.send(method, *parameters) if klass&.respond_to?(method)
  end
  agile_log_exception(nil, "#{evaluate} not defined!")
  '???'
end

############################################################################
# Process eval option for data_set field or form head field.
############################################################################
def agile_process_column_eval(yaml, document)
  if yaml['params'].blank?
    parms  = agile_eval_to_array(yaml['eval'])
    method = parms.shift

    # prepare parameters for agile_name_for_* methods
    parms << 'id' if method == 'agile_name_for_id' && parms.size == 2
    parms = [@form['table'], yaml['name']] if method == 'agile_text_for_value' && parms.size < 2

    parms << document[yaml['name']]
    parms.map! { %w[record document].include?(_1.to_s) ? document : _1 }
    if method.match(/^agile_/)
      send(method, *parms)
    elsif respond_to?(method)
      parms = [document] + parms
      send(method, *parms)
      # model method
    elsif document.respond_to?(method)
      document.send(method)
      # some class method
    elsif method.match('.')
      klass, method = method.split('.')
      klass.classify.constantize.send(method, *parms)
    else
      '?????'
    end
    # eval with params
  else
    parms = {}
    if yaml['params'].instance_of?(String)
      parms = agile_value_for_parameter(yaml['params'], document)
    elsif yaml['params'].instance_of?(Hash)
      yaml['params'].each { |k, v| parms[k] = agile_value_for_parameter(v) }
    else
      parms = document[ yaml['name'] ]
    end
    agile_process_eval(yaml['eval'], parms)
  end
end

############################################################################
# Defines style or class for row (tr) or column (td) on data_set.
############################################################################
def agile_style_or_class(selector, yaml, value, record)
  return '' if yaml.nil?

  field    = value # alias value as field so both names can be used in eval
  document = record
  html     = selector ? "#{selector}=\"" : ''
  begin
    html += if yaml.instance_of?(String)
              yaml
            elsif yaml['eval']
              eval(yaml['eval'])
            elsif yaml['method']
              agile_process_eval(yaml['method'], record)
            end
  rescue Exception => e
    agile_log_exception(e, 'agile_style_or_class')
  end
  html += '"' if selector
  html
end

############################################################################
# Get standard actions when actions directive contains single line.
# Subroutine of agile_actions_for_index
# 
# Allows for actions: new, filter, standard syntax
############################################################################
def process_standard_actions(actions_params, std_actions)
  actions, index = {}, 1

  actions_params.split(',').map(&:strip).each do |an_action|
    if an_action == 'standard'
      actions.merge!(std_actions)
      index += 2 * std_actions.size
    else
      actions[index] = an_action
      index += 2
    end
  end
  actions
end

############################################################################
# Removes action from list of actions
############################################################################
def actions_remove_action(actions, *what)
  what.each do |action_to_remove|
    index = actions.find { |k, v| v == action_to_remove }
    actions.delete(index.first) if index
  end
end


############################################################################
# When dataset is to be drawn by Rails helper method.
############################################################################
def agile_process_data_set_method
  data_set = @form['index']['data_set']
  return render partial: data_set['view'] if data_set['view']

  method = data_set['eval'] || 'data_set_eval_misssing'
  return send method if respond_to?(method)

  I18n.t('agile.no_method', method: method)
end

############################################################################
# Check if form has defined input field for field_name and that is not redefined as as
############################################################################
def can_include_filter_shortcut?(field_name)
  field = AgileHelper.get_field_form_definition(field_name, @form)
  return unless field

  filters = @form.dig('index', 'filter')
  return if filters.nil?

  filters.split(',').map(&:strip).find { _1 == field_name }
end

end
