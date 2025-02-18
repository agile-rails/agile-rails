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
# == Schema information
#
# Table name: ar_design : Designs
#
#  id                  Integer     id
#  created_at           Time        created_at
#  updated_at           Time        updated_at
#  description          String      Short description of design
#  body                 String      Body of design which will be rendered like any Rails view
#  params               String      Parameters used by design
#  css                  String      CSS for design
#  rails_view           String      Rails view (file) name which will be used to render design
#  code                 String      Ruby code evaluated when processing page
#  author               String      Creater if design
#  active               Boolean     Is the design active
#  created_by           Integer     created_by
#  updated_by           Integer     Last updated by
#  site_id              Integer     Select site name if this design belongs to singe site
#
# Designs are essential parts of AgileRails. Every ArPage document must have its design document defined.
# If ArPage documents are anchors for url addresses, ArDesign documents define how
# will page data be rendered in browser. 
# 
# ArDesign documents define what would normally be written into Rails view file. The code
# is saved in the body field of ArDesign document. If you prefere Rails way, enter view
# file name into rails_view field and put your code into file into views directory 
# (ex. designs/home_page for ../views/designs/home_page.html.erb file). 
# 
# If you choose to save code to Rails view file you must add one top and bottom line to every source file.
# Top line will provide CMS edit menu, bottom line will provide additional CSS and javascript code
# scooped when renderers are called.
# 
# Example (as written in body of ar_design):
#    <div id="site">
#      <div id="site-top-bg">
#        <div id="site-top"><div id="logo"><%= agile_render(:ar_piece, name: 'site-top') %></div>
#          <div id="login"><%= agile_render(:common, method: 'login') %></div>
#       </div>
#        <%= agile_render(:ar_menu, name: 'test-menu') %>
#      </div>
#
#      <div id="page"><%= agile_render(:ar_page) %></div>
#    </div>
#    <div id="site-bottom"><%= agile_render(:ar_piece, name: 'site-bottom') %></div>
#    
# Example (as written in Rails view file):
# 
#    <!-- Pay attention on lines added at the top and bottom of file -->
#    <%= render partial: 'ra/edit_stuff' if session[:edit_mode] > 0 %>
#    
#    <div id="site">
#      <div id="site-top-bg">
#        <div id="site-top"><div id="logo"><%= agile_render(:ar_piece, name: 'site-top') %></div>
#          <div id="login"><%= agile_render(:common, method: 'login') %></div>
#       </div>
#        <%= agile_render(:ar_menu, name: 'test-menu') %>
#      </div>
#
#      <div id="page"><%= agile_render(:ar_page) %></div>
#    </div>
#    <div id="site-bottom"><%= agile_render(:ar_piece, name: 'site-bottom') %></div>
#    
#    <style type="text/css"><%= @css.html_safe %></style><%= javascript_tag @js %>
########################################################################
class ArDesign < ApplicationRecord

validates_length_of :description, minimum: 5

after_save :cache_clear
after_destroy :cache_clear

####################################################################
# Clear cache if cache is configured
####################################################################
def cache_clear
  Agile.cache_clear(:ar_design)
end
  
########################################################################
# Return choices for select for design_id. 
# 
# If site is passed as parameter, only designs which belong to site or do not
# have site assigned will be selected. Too much designs to select often confuses
# end user.
########################################################################
def self.choices_for_designs(site = nil)
  site.nil? ? where(active: true) : where(site_id: [nil, site.id], active: true)
    .sort { |w1, w2| w1.description.casecmp(w2.description) }
    .map  { |design| [design.description, design.id] }
end
  
end
