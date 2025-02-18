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
# Table name: ar_menu_item : Menu items
#
#  id                   Integer         id
#  created_at           Time            created_at
#  updated_at           Time            updated_at
#  caption              String          Caption of menu item
#  picture              String          Picture for the menu
#  link                 String          Link called when menu is chosen
#  link_prepend         String          Link field usually holds direct link to document. Prepand field holds data, that has to be prepanded to the link.
#  target               String          Target window for the link. Leave empty when same window.
#  page_id              Integer         Page link
#  order                Integer         Order on which menu item is shown. Lower number means prior position.
#  hidden               Boolean         Is hidden
#  active               Boolean         Is active
#  policy_id            Integer         Menu item will be diplayed according to this policy
#  parent_id            Integer         Parent menu item. 0 if top level
#  created_by           Integer         created_by
#  updated_by           Integer         updated_by
#
# ArMenuItems model is used to save items of a menu.
#########################################################################
class ArMenuItem < ApplicationRecord

belongs_to :ar_menu

validates :order, presence: true

before_save :do_before_save
after_save :cache_delete
after_destroy :cache_delete
  
#######################################################################
# Will return menu path for the item as array of id-s. Method can be used
# to determine all parents of current item.
# 
# Returns:
# Array. Of parent items ids.
#######################################################################
def menu_path
  path, parent = [], self
  while parent
    path << parent.id
    parent = parent._parent
  end 
  path.reverse
end

#######################################################################
# Will return top menu item id. Used for detecting which top-level menu 
# was last selected.
# 
# Returns:
#   Integer: Top menu level id
#######################################################################
def top_menu_id
  menu_path[1]
end

######################################################################
# Implementation of before_save callback.
######################################################################
def do_before_save
  self.link = ArPage.clear_link(caption.downcase.strip) if link.blank?
end  

######################################################################
# Clear parent record from cache
######################################################################
def cache_delete
  ArMenu.find(ar_menu_id).cache_delete
end

######################################################################
# Dummy method
######################################################################
def top_menu_id
  menu_path[1]
end
  
end
