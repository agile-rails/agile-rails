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
#++

module Agile
module Generators

# rails g agile_rails:new_form MODEL
class NewFormGenerator < Rails::Generators::NamedBase # :nodoc:

source_root File.expand_path('../templates', __FILE__)

class_option :tabs,  type: :boolean, default: false, description: "Create tabbed form"
class_option :extra, type: :boolean, default: false, description: "Add some extra commented code to the form"

def self.banner #:nodoc:
  <<-BANNER.chomp
  rails g agile_rails:new_form MODEL [options]

    Generates Agile Rails form for specified Rails model

      - options: --tabs will create form entry fields with tabs (default: --no-tabs) 
                 --extra will create some extra commented code for help (default: --no-extra) 
BANNER
end

###########################################################################
# Will create output and save it to form filename.
###########################################################################
def create_form_file
  @file_name = file_name.underscore
  @tabs  = options[:tabs]
  pp options
  @extra = options[:extra]
  begin
    @model = @file_name.classify.constantize
  rescue Exception => e
    pp ([e.message] + e.backtrace).join($/)
    @model = nil
  end
  return (pp "Error loading #{file_name.classify} model! Aborting.") if @model.nil?

  form = top_level_options +
         index_options +
         data_set_options +
         form_top_options +
         form_fields_options +
         localize_options
  create_file "app/forms/#{@file_name}.yml", form
end

private
###########################################################################
#
###########################################################################
def top_level_options
  extra = <<EOT
#title: Alternative title
#extend: extend
#controls: controls_file
#readonly: true
#permissions:
#  can_view: role_name
EOT

  <<EOT 
# Form for #{file_name}
table: #{file_name}
#{extra if @extra}
EOT
end
  
###########################################################################
#
###########################################################################
def index_options
  extra = <<EOT

#  actions:
#    10: 
#      type: link
#      controller: controller_name
#      action: action_name
#      table: table_name
#      form_name: form_name
EOT

  <<EOT 
index:
  filter: some_id as text_field
  actions: standard  
  #{extra if @extra}
EOT
end

###########################################################################
#
###########################################################################
def data_set_options
  extra = <<EOT
#    filter: controls_filter
#    per_page: 10
  
#    actions: 
#      10:
#        type: link
#        controller: controller_name
#        action: action_name
#        table: table_name
#        form_name: form_name
#        target: target      
#        method: (get),put,post      

EOT

  <<EOT 
  data_set:
    actions: standard
#{extra if @extra}
# 
# Choose columns from
# #{@model.attribute_names.join(',')}
    columns:
      10:  
        name: #{@model.attribute_names[1]}
      20:  
        name: #{@model.attribute_names[2]}
      30:  
        name: #{@model.attribute_names[3]}
      40:  
        name: #{@model.attribute_names[4]}

#       style: 'color: red'
#       width: 10%
#       align: right
#       format: '%d.%m.%Y'
#       format: N2
#       sort: n
#       eval: agile_name_for_id,ar_user,name
#       eval: agile_icon_for_boolean

EOT
end

###########################################################################
#
###########################################################################
def form_top_options
  extra = <<EOT

#  title:
#    field: name
#    edit: Title for edit
#    show: Title for show

#
#  actions: 
#    1: 
#      type: ajax
#      controller: ppk
#      action: prepare_document
#      method: (get),put,post
#      caption: Prepare document
#    2: 
#      type: script
#      caption: Cancle 
#      js: parent.reload();
#    3:
#      type: submit
#      caption: Send
#      params:
#        before-save: send_mail
#        after-save: return_to parent.reload

EOT

  <<EOT
form:
  actions: standard
#{extra if @extra}
EOT
end

###########################################################################
#
###########################################################################
def form_field(attribute, index, offset)
  field, value = attribute
  helper = I18n.t("helpers.label.#{@file_name}.choices4_#{field}")
  type, eval = 'select', ''
  if helper.match( /Translation missing/i )
    if field[-3, 3] == '_id'
      eval = "choices: eval agile_choices_for('#{field[0, field.size - 3]}','description_field_name','id')\n"
    else
      type = if value.is_a?(TrueClass) || value.is_a?(FalseClass)
               'check_box'
             else
               'text_field'
             end
    end
  end
  yml = ' '*offset
  yml << "#{index}:\n"
  offset += 2

  yml << ' '*offset + "name: #{field}\n"
  yml << ' '*offset + "type: #{type}\n"
  yml << ' '*offset + eval if eval.size > 0
  yml << ' '*offset + "size: 50\n" if type == 'text_field'
  if type == 'select'
    yml << ' '*offset + "html:\n"
    offset += 2
    yml << ' '*offset + "include_blank: true\n"
  end 
  yml
end

###########################################################################
#
###########################################################################
def embedded_form_field(offset)
  yml = ''
  field_index = 10
  @model.embedded_relations.keys.each do |embedded_name|
    yml << ' '*offset + "#{field_index}:\n"
    yml << ' '*(offset + 2) + "name: #{embedded_name}\n"
    yml << ' '*(offset + 2) + "type: embedded\n"
    yml << ' '*(offset + 2) + "form_name: #{embedded_name[0,embedded_name.size - 1]}\n"
    yml << '#' + ' '*(offset + 2) + "html:\n"
    field_index += 10
  end
  yml
end

###########################################################################
#
###########################################################################
def form_fields_options
  extra = <<EOT

#      group: 2
#      line: top bottom
#      readonly: yes 1 true
#      default: 10
#        eval: some_method, session[:], params[:],@site.name

#      type: comment
#      text: myapp.comment_text
#      caption: false
#      html:
#        style: 'color: red'
#        class: some_class 

#      type: datetime_picker
#      type: date_picker
#      options: 'step: 60, inline: true'
#      options: 'inline: true' 

#      type: text_autocomplete
#      search: model_name.field_name
#      search: model_name..method_name
#      is_id: no

#      type: select
#      choices:
#        eval: ModelClass.method_name
#      depend: field1, field2
#      include_blank: true

#      type: text_area
#      size: 90x10
#      type: check_box

#      type: number_field
#      size: 10
#      format: N2

#      type: radio_button
#      choices: 'Marantz:1,Sony:2,Bose:3,Pioneer:4'
#      inline: true

#      type: readonly
#      name: user_id
#      eval: agile_name_for_id,model_name,field_name
 
#      type: hidden_field
#      type: file_field
#      type: file_select
#      size: 50 
#      html:
#        type: email
#        required: true
 

EOT

  forbidden = %w[id created_by updated_by created_at updated_at]
  tab_index = 1
  field_index = 0
  if @tabs
    yml = "  tabs:\n"
    @model.new.attributes.each do |attribute|
      next if forbidden.include?(attribute.first)

      if field_index%100 == 0
        yml << "\n    tab#{tab_index}:\n"
        field_index = 0
        tab_index += 1
      end
      yml << form_field(attribute, field_index += 10, 6)
    end
  else
    yml = "  fields:\n"
    @model.new.attributes.each do |attribute|
      next if forbidden.include?(attribute.first)

      yml << form_field(attribute, field_index += 10, 4)
    end
  end
  yml + (@extra ? extra : '')
end

###########################################################################
#
###########################################################################
def localize_options
  forbidden = %w[id created_by updated_by created_at updated_at]
  yml =<<EOT
  
#################################################################
# Localization
en:
  helpers:
    label:
      #{file_name}:
        table_title: 
        choices_for_: 

EOT
  @model.attribute_names.each do |attr_name|
    next if forbidden.include?(attr_name)

    yml << "        #{attr_name}: \n"
  end
  yml
end  
    
end
end
end
