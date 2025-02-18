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
# Implementation of file_select AgileRails form field.
# 
# FileSelect like HtmlField implements redirection for calling document manager edit field code.
# This can be agile_rails_html_editor's elfinder or any other code defined
# by ar_site.settings file_select setting.
#
# Example of ar_site.setting used for agile_rails_html_editor gem.
#   html_editor: ckeditor
#   ckeditor:
#     config_file: /files/ck_config.js
#     css_file: /files/ck_css.css
#   file_select: elfinder
#
# Form example:
#    60:
#      name: picture
#      type: file_select
#      size: 50
###########################################################################
class FileSelect < AgileFormField

###########################################################################
# Render file_select AgileRails form field code
###########################################################################
def render
  return ro_standard if @readonly  
  # retrieve file_select option from site settings
  file_select = @env.agile_get_site.params['file_select'] if @env.agile_get_site
  file_select ||= 'elfinder'
  klas_string = file_select.camelize

  if AgileFormFields.const_defined?(klas_string)
    klas = AgileFormFields::const_get(klas_string)
    o = klas.new(@env, @record, @yaml).render
    @js += o.js
    @html += o.html
  else
    @html += 'File select component not defined. Check site.settings or include agile_rails_html_editor gem.'
  end
  self
end

end
end
