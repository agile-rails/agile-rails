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

##########################################################################
# Model and collection for filtering and sorting data.
# For now it is just an idea. Not yet implemented although data filtering implementation
# code is here, but should probably be moved into some helper.
##########################################################################
class ArFilter < ApplicationRecord

  #  field :ar_user_id,  type: Integer
  #  field :table,       type: String
  #  field :description, type: String
  #  field 'filter',      type: String,       default: ''
  #  field :public,      type: Boolean
  #  field :active,      type: Boolean,      default: true

validates :description, presence: true
before_save :do_before_save

######################################################################
# Implementation of before_save callback.
######################################################################
def do_before_save
  self.ar_user_id = nil if self.public
end

######################################################################
# Will return model with filter query set
######################################################################
def self.get_filter(table_filter)
  return if table_filter.nil?

  filter = table_filter[:filter]
  return if filter.nil? || filter[:table].nil?

  model = filter[:table].classify.constantize
  field = filter[:field]
  # evaluate
  if filter[:operation] == 'eval'
    return eval(filter[:value]) if filter.dig(:value).to_s != '#NIL' # evaluated as string
    return model.send(field) if model.respond_to?(field) # defined as scope or method in the model
  end
  # empty
  return model.where(field => [nil, '']) if filter[:operation] == 'empty'

  value = case filter[:value].to_s
          when '#NIL' then return   # #NIL. Filter is not active
          when 'true' then true     # boolean true
          when 'false' then false   # boolean false
          else                      # is it a date or time. This can be improved
            if filter[:value].to_s.split(/[\.|\/|\-]/).size < 3
              filter[:value]
            else
              (Date.parse(filter[:value]) rescue nil) || filter[:value]
            end
          end

  case filter[:operation]
  when 'like'
    #TODO get_like_clause(field, value)
    value = sanitize_sql(value)
    model.where("lower(#{field}) like ?", "%#{value.downcase}%")
  when 'gt'
    model.where("#{field} > ?", value)
  when 'lt'
    model.where("#{field} < ?", value)
  when 'eq'
    model.where("#{field} = ?", value)
  end
end

############################################################################
# Return filter input field for entering filter data on index action
############################################################################
def self.get_filter_input_field(env)
  form   = env.form
  filter = env.session.dig(:filters, form['table'], :filter)
  return '' if filter.nil? || filter[:operation] == 'eval'

  field = AgileHelper.get_field_form_definition(filter[:field], form)
  return '' if field.nil? && filter[:input].nil?

  saved_readonly = form['readonly']
  form['readonly'] = false # must be
  field ||= {}
  # If field has choices available in labels, use them. This is most likely select input field.
  if field['name']
    choices = env.t('helpers.label.' + form['table'] + '.choices_for_' + field['name'] )
    unless choices.match(/translation missing/i) || choices.match('helpers.label')
      field['choices'] = choices
    end
  end
  # field redefined with input keyword. Name must start with _
  field['name']  = '_filter_field'
  field['type']  = filter[:input] if filter[:input].to_s.size > 5
  field['type'] ||= 'text_field'
  field['readonly'] = false   # must be
  # let text fields size be no more then 20
  field['size']  = 20 if field['type'].match('text') && field['size'].to_i > 20
  field['html'] ||= {}
  # Start with last entered value
  field['html']['value']    = filter[:value] unless filter[:value] == '#NIL'
  field['html']['selected'] = field['html']['value'] # for select field
  # url for filter ON action
  field['html']['data-url'] = env.url_for(controller: :agile, action: :run, control: 'agile.filter_on',
                                          t: AgileHelper.table_param(env.params), f: AgileHelper.form_param(env.params))
  url = field['html']['data-url']
  # remove if present
  field['with_new'] = nil if field['with_new']
  # create input field
  html = ''
  klass_string = field['type'].camelize
  klass = AgileFormFields::const_get(klass_string) rescue nil
  if klass
    if (agile_field = klass.new(env, nil, field).render rescue nil)
      js = agile_field.js.blank? ? '' : env.javascript_tag(agile_field.js)
      html = %(<li class="no-background">
<span class="filter_field" data-url="#{url}">#{agile_field.html}
#{env.mi_icon('search', class: 'record_filter_field_icon')}
#{js}</span></li>)
    else
      # Error. Forget filter
      env.session[:filters][form['table']][:filter] = nil
    end
  end
  form['readonly'] = saved_readonly
  html.html_safe
end

######################################################################
# Create popup menu for filter options.
######################################################################
def self.filter_menu(env)
  html = '<div><ul class="menu-filter">'
  table = env.form['table']
  documents = self.where(table: table, active: true).to_a
  documents.each do |document|
    description = document.description.match('.') ? I18n.t(document.description) : document.description
    html += "<li data-filter=\"#{document.id}\">#{description}</li>"
  end

  # add filters defined in model
  model   = table.classify.constantize
  filters = model.agile_filters if model.respond_to?(:agile_filters)
  if filters
    # only single defined. Convert to array.
    filters = [filters] if filters.class == Hash
    filters.each do |filter|
      url = env.url_for(controller: :agile, action: :run, t: table, f:  AgileHelper.form_param(env.params),
                        control: 'agile.filter_on',
                        filter_field: filter[:field],
                        filter_oper:  filter[:operation],
                        filter_value: filter[:value])
      html += %(<li class="ar-link-ajax in-menu" data-url="#{url}">#{filter[:title]}</li>)
    end
  end
  # divide standard and custom filter options
  html += '<hr>' if html.size > 30 #
  html += %(<li class="ar-link in-menu" id="open_ar_filter">#{I18n.t('agile.filter_set')}</li></ul></div>)
  html.html_safe
end

######################################################################
# Creates title for turn filter off, which consists of displaying curently
# active filter and text to turn it off.
######################################################################
def self.title_for_filter_off(filter_data)
  filter = filter_data&.dig(:filter)
  return '' if filter.nil?
  return I18n.t('agile.filter_off') if filter[:operation] == 'eval'

  operations = I18n.t('agile.choices_for_filter_operators').split(',').map { _1.split(':') }
  operation  = operations.find { _1.last == filter[:operation] }.first

  '[ ' + I18n.t("helpers.label.#{filter[:table]}.#{filter[:field]}") +
    " ] #{operation} [ #{filter[:value]} ] : #{I18n.t('agile.filter_off')}"
end

end
