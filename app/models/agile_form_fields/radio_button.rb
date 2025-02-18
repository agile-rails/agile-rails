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
# Implementation of radio_button AgileRails form field. Field provides radio_button input field.
# structure.
# Form options are mostly same as in select field. 
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ radio_button (required)
# * +choices:+ Values for choices separated by comma. Values can also be specified like description:value.
# In this case description will be shown to user, but value will be saved to document.
#   choices: 'OK:0,Ready:1,Error:2'
#   choices: Ruby,Pyton,PHP
# * +eval:+ Choices will be provided by evaluating expression
#   eval: agile_choices_for('model_name','description_field_name','_id'); agile_choices_for helper will provide data for select field.
#   eval: ModelName.choices_for_field; ModelName class will define method choices_for_field which 
#   will provide data for select field. Since expression is evaluated in the context of Form Field object
# Even session session variables can be accessed. 
#   eval: 'MyClass.method(@env.session[:user_id])'
# When searching is more complex custom search method may be defined in CollectionName 
# model which will provide dataset for search.
#   eval: collection_name.search_field_name.method_name; 
# If choices or eval is not defined choices will be provided from translation helpers. For example: 
# Collection has field status. Choices for field will be provided by en.helpers.model_name.choices_for_status 
# entry of english translation. English is of course default translation. If you provide translations in
# your local language then select choices will be localized.
#   en.helpers.model_name.choices_for_status: 'OK:0,Ready:1,Error:2'
#   sl.helpers.model_name.choices_for_status: 'V redu:0,Pripravljen:1,Napaka:2'
# * +inline:+ radio buttons will be presented inline instead of stacked on each other.
# 
# Form example:
#    10:
#      name: hifi
#      type: radio_button
#      choices: 'Marantz:1,Sony:2,Bose:3,Pioneer:4'
#      inline: true
###########################################################################
class RadioButton < Select

###########################################################################
# Render radio_button AgileRails Form field
###########################################################################
def render
  return ro_standard if @readonly

  set_initial_value('html','value')
  record = record_text_for(@yaml['name'])
  @yaml['html'].symbolize_keys!
  clas = 'ar-radio' + ( @yaml['in_line'] ? ' ar-in-line' : '')
  @html += %(<div class="#{clas}">)
  choices = get_choices
  value = @record.send(@yaml['name'])
  if value.blank?
    # Should select first button if no value provided
    value = choices.first.is_a?(String) ? choices.first : choices.first.last
  end
  choices.each do |choice|
    choice = [choice, choice] if choice.is_a?(String)
    @html += <<~EOT
    <div>
      #{@env.radio_button_tag("#{record}[#{@yaml['name']}]", choice.last, choice.last.to_s == value.to_s)}
      #{choice.first}
    </div>
EOT
  end
  @html += "</div>\n"

  self
end

end
end
