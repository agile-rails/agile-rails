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
# ArGalleryRenderer renders data for displaying picture gallery on the web page.
# 
# Example:
#    <div id="page">
#      <%= agile_render(:ar_gallery) if document.gallery %>
#    </div>
#
########################################################################
class ArGalleryRenderer

include AgileApplicationHelper
include  AgileCommonHelper

########################################################################
# Object initialization.
########################################################################
def initialize( env, opts = {} ) #:nodoc:
  @env  = env
  @opts = opts
  @css  = ''
end

#########################################################################
# Default ArGallery render method. It will simply put thumbnail pictures side by side and
# open big picture when clicked on thumbnail.
#########################################################################
def default
  html = '<div class="picture-gallery"><ul>' + new_menu()
  ArGallery.where(doc_id: @opts[:doc_id], doc_type: @opts[:doc_type], active: true).order(:order).each do |picture|
    html += "<li>" + edit_menu(picture)
    html += @env.link_to(@env.image_tag(picture.thumbnail, title: picture.title), picture.picture)
    html += '</li>'
  end
  html += '</ul></div>'
end

#########################################################################
# Renderer dispatcher. Method returns HTML part of code.
########################################################################
def render_html
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "Error ArGalleryRenderer: Method #{method} doesn't exist!"
end

########################################################################
# Return CSS part of code.
########################################################################
def render_css
  @css
end

private

########################################################################
# 
########################################################################
def edit_menu(picture)
  return '' if @opts[:edit_mode] < 2

  opts = { action: :edit,
           title: "#{t('agile.edit')}: #{picture.title}",
           id: picture.id,
           table: 'ar_gallery'
  }
  "<li>#{@env.agile_link_for_edit(opts)}</li>\n"
end

########################################################################
#
########################################################################
def new_menu
  return '' if @opts[:edit_mode] < 2

  opts = { action: :new,
           title: "#{t('agile.new')}: Picture",
           p_doc_id: @opts[:doc_id],
           p_doc_type: @opts[:doc_type],
           table: 'ar_gallery'
  }
  "<li>#{@env.agile_link_for_create(opts)}</li>\n"
end

end
