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

######################################################################
# AgileRails controls for ArPage model.
######################################################################
module ArPageControl

######################################################################
# Called when new empty record is created
######################################################################
def new_record
  # Called from menu. Fill in values, that could be obtained from menu
  if params[:from_menu]
    menu_item_klass = (agile_get_site.menu_klass.to_s + 'Item').classify.constantize
    menu = menu_item_klass.find(params[:id])
    # Fill values for form
    @record.subject = menu.caption
    @record.ar_site_id = agile_get_site.id
    @record.menu_id = params[:id]
    # set update_menu on save parameter
    params['p__update_menu'] = '1'
  else
    @record.design_id = params[:design_id] if params[:design_id]
    return unless params[:page_id]
    # inherit some values from currently active page
    if page = ArPage.find(params[:page_id])
      @record.design_id  = page.design_id
      @record.menu       = page.menu
      @record.ar_site_id = page.ar_site_id
    end
  end
end

######################################################################
# Called just after record is saved to DB.
######################################################################
def after_save
  if params.dig(:_record,:_update_menu).to_s == '1'
    agile_get_site.menu_klass.menu_item_link_update(@record)
  end
end

end 
