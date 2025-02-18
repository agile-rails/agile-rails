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


####################################################################
# Helpers needed by some form fields on ar_image form
####################################################################
module ArImageHelper

############################################################################
# Will return code for previewing image on top of ar_image entry form
############################################################################
def ar_image_preview(document, *parms)
  src = "/#{agile_get_site.params.dig('ar_image', 'location')}/#{document.first_available_image}"
  %(<span class="ar-image-preview ar-image-preview-1"><img src="#{src}"></img></span>).html_safe
end

############################################################################
# Will return code for previewing resized images on ar_image entry form
############################################################################
def ar_image_preview_resized(document, yaml, ignore)
  size = yaml['name'].last
  return '' if document["size_#{size}"].blank?

  src = "/#{agile_get_site.params.dig('ar_image', 'location')}/#{document.id}-#{size}.#{document.img_type}?#{Time.now.to_i}"
  %(<span class="ar-image-preview"><img src="#{src}"></img></span><div id="ar-image-preview"></div>).html_safe
end

############################################################################
# Will return choices for preset image sizes
############################################################################
def ar_image_choices_for_image_size
  sizes = agile_get_site.params.dig('ar_image', 'sizes')
  return ['300x200'] if sizes.blank?

  sizes.split(",").map(&:strip)
end

############################################################################
# Will return code for invoking ar_image_search form to select image select on an AgileRails Form.
#
# @param [String] field_name : Field name to which selected image value will be saved.
###########################################################################
def ar_image_invoke(field_name)
  return '' unless agile_get_site.params.dig('ar_image', 'location')

  url = url_for(controller: :cmsedit, form_name: :ar_image_search, table: :ar_image, field_name: field_name)
  %(<span class="ar-window-open" data-url="#{url}" title="#{t('agile.ar_image.invoke')}">#{mi_icon('image-o')}</span>).html_safe
end

############################################################################
# Will return code for previewing image on top of ar_image entry form
############################################################################
def first_ar_image(document, *parms)
  src = "/#{agile_get_site.params.dig('ar_image', 'location')}/#{document.first_available_image}"
  %(<span class="ar-image-preview"><img src="#{src}"></img></span><span id="ar-image-preview">).html_safe
end

######################################################################
# Will format qry result as html code for selecting image
######################################################################
def select_links_for_ar_image(doc, *parms)
  %w[o s m l].map { |size| ar_image_link_for_select(doc, size) }.join.html_safe
end

######################################################################
# Will return HTML code for selecting image
######################################################################
def ar_image_link_for_select(doc, what)
  field = "size_#{what}"
  value = doc.send(field)
  return '' if value.blank?

  value = value.split(/\+/).first
  src = "/#{agile_get_site.params.dig('ar_image', 'location')}/#{doc.id}-#{what}.#{doc.img_type}"
  %(
<div class="img-link"><div>
 #{value}<br>
  <i class="mi-o mi-preview" onclick="ar_image_preview('#{src}');" title="#{t('agile.ar_image.preview')}"></i>
  <i class="mi-o mi-check_circle" onclick="ar_image_select('#{src}');" title="#{t('agile.ar_image.select')}"></i>
</div></div>)
end

######################################################################
# Will return image file for requested size.
#
# @param [String] file_name : Image file name
# @param [String] size : Preferred image size
#
# @return [String] : Image file name if requested size is found. Otherwise first available image.
######################################################################
def ar_image_get_by_size(file_name, size)
  id = file_name[file_name.rindex('/') + 1, 24]
  return 'error: ID not valid' unless BSON::ObjectId.legal?(id)

  image = ArImage.find(id)
  return 'error: ID not found' unless image

  what = %w[o s m l].inject('l') do |r, e|
    field_name = "size_#{e}".to_sym
    break e if doc.send(field_name) == size

    e
  end
  "/#{agile_get_site.params.dig('ar_image', 'location')}/#{doc.id}-#{what}.#{doc.img_type}"
end

end
