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

#########################################################################
# == Schema information
#
# Table name: ArMenu : AgileRail menu system
#
# Default menu system for AgileRails. Model recursively embeds ArMenuItem documents
# which (theoretically) results in infinite level of sub menus. In practice 
# reasonable maximum level of 4 is advised.
#########################################################################
class ArMenu < ApplicationRecord

belongs_to :ar_site
has_many   :ar_menu_items

validates  :name, :length => { :minimum => 4 }
validates  :name, uniqueness: true
validates_length_of :description, minimum: 10

after_save :cache_delete
after_destroy :cache_delete
  
######################################################################
# Clear menu cache
######################################################################
def cache_delete
  Agile.cache_clear(name)
end

#######################################################################
# Will return list of menu items of specified menu. Used in ArPage document for
# selecting top level selected menu.
# 
# Called from AgileApplicationHelper :agile_choices_for_menu: method.
# 
# Parameters: 
# [Site] ArSite document. Site for which menu belongs to. If site is not specified
# all current menus in ar_menus collection will be returned.
# 
# Returns:
# Array. Of choices prepared for select input field.
#######################################################################
def self.choices_for_menu(site)
  rez = []
  menus = (site.menu_name.blank? ? all : where(name: site.menu_name)).to_a
  menus.each do |menu|
    rez << [menu.name, nil]
    menu.ozs_menu_items.where(active: true).order(:order).each do |menu_item|
      rez << ['-- ' + menu_item.caption, menu_item._id]
    end
  end
  rez
end
  
#######################################################################
# Subroutine of choices_for_menu_as_tree
#######################################################################
def self.do_sub_menu(menus, parent, ids) #:nodoc:
  result = []
  menus.each do |item|
    long_id = "#{ids};#{item.id}"
    result << [item.caption, long_id, parent, item.order]
    sub_menus = ArMenuItem.where(parent_id: item.id).order(:order).to_a
    result += do_sub_menu(sub_menus, long_id, long_id) if sub_menus.size > 0
  end
  result
end

#######################################################################
# Will return menu structure for menus belonging to the site.
# 
# Parameters: 
# [Site] ArSite document. Site for which menu belongs to. If site is not specified
# all current menus in collection will be returned.
# 
# Returns:
# Array. Of choices prepared for tree:select input field.
#######################################################################
def self.choices_for_menu_as_tree(site_id = nil)
  return [] if site_id == nil

  id = site_id.class == Integer ? site_id : site_id.id
  where(ar_site_id: [nil, id], active: true).order(:name).inject([]) do |r, menu|
    r << [menu.name, menu.id, nil, 0]
    sub_menus = ArMenuItem.where(ar_menu_id: menu.id, parent_id: 0).order(:order).to_a
    r += do_sub_menu(sub_menus, menu.id, menu.id.to_s) if sub_menus.size > 0
    r
  end
end

#######################################################################
# Will update link value of selected menu_item
# 
# Parameters: 
# [record] Array. Data of saved document.
#######################################################################
def self.menu_item_link_update(record)
  return if record.try(:menu_id).blank?    # not set

  ar = record.menu_id.split(';')
  menu = ArMenuItem.find(ar.last.to_i)
  menu.page_id = record.id
  menu.save  
end

######################################################################
# Return all pages belonging to site ready for select input field. Used
# by ar_menu* forms, for selecting page which will be linked by menu option.
# 
# Parameters:
# [site] Site document.
######################################################################
def self.all_pages_for_site(parms)
  menu_id = parms[:ids].split(';').first    # get menu id from params[:ids]
  site_id = ArMenu.only(:site_id).find(menu_id).ar_site_id
  site  = ArSite.only(:page_class, :id).find(site_id)  # find site
  pages = site.page_class.constantize       # pages collection name
  pages.only(:subject, :id).where(ar_site_id: site.id, active: true).order(:subject)
       .map { |page| [ page.subject, page.id] }
end

end
