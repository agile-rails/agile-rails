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
# Default menu renderer from ar_menus table. Renderer produces output for
# rendering menu with (theoretically) infinite level of sub menus. In practice 
# reasonable maximum level of 4 is advised.
# 
# Example (as used in design):
#    agile_render(:ar_menu, name: 'my_menu')
#    # when :name option is omitted it will use site document's field menu_name.
#    agile_render(:ar_menu)
########################################################################
class ArMenuRenderer

include AgileApplicationHelper
include AgileCommonHelper

########################################################################
# Object initialization. Will also prepare menu record.
########################################################################
def initialize( env, opts ) #:nodoc:
  @env  = env
  @menu = opts[:name] ? ArMenu.find_by(name: opts[:name].to_s) : ArMenu.find(@env.site.menu_id)
  @opts = opts
  self
end

########################################################################
# Return selected topmenu level.
########################################################################
def find_selected
  if @env.page.menu_id
    top_menu_id = @env.page.menu_id
    top_menu_id = @env.page.menu_id.split(';')[1] if @env.page.menu_id.match(';')
    ret = @menu.ar_menu_items.find(top_menu_id)
  end
  # return first if not found (something is wrong)
  ret || @menu.ar_menu_items[0]
end

########################################################################
# Creates edit link if in edit mode.
########################################################################
def link_for_edit(opts) #:nodoc:
  return '' unless @opts[:edit_mode] > 1

  opts.merge!( { controller: :agile, action: :edit } )
  title = "#{t('agile.edit')}: "
  opts[:title] = "#{title} #{opts[:title]}"

  "<li>#{agile_link_for_edit(opts)}</li>\n"
end

########################################################################
# Returns html code required to create single link in a menu. Subroutine of do_menu_level.
########################################################################
def link_4menu(item, prepend)
  link = if item.link_to.present?
              item.link_to
            else
              '/' + (prepend + [item.link.delete_prefix('/')]).join('/')
            end
  target = item.target.blank? ? nil : item.target
  # - in first place won't write caption text
  caption   = item.caption[0] == '-' ? '' : @env.t(item.caption)
  img_title = item.caption.to_s.sub('-', '')
  # add picture if picture is not blank
  html = ''
  if item.picture.present?
    if item.picture[0, 3] == 'mi-'
      # position is delimited with comma
      icon, position = item.picture.split(',')
      caption = if position.to_s == 'right'
                  caption + @env.mi_icon(icon[3..])
                else
                  @env.mi_icon(icon[3..]) + caption
                end
    else
      return @env.link_to( @env.image_tag(item.picture), link, { title: img_title, target: target } ) rescue 'ERROR!'
    end
  end
  html = html + @env.link_to(caption.html_safe, link, { target: target} ) if caption.present?
  html
end

########################################################################
# Creates HTML code required for submenu on single level. Subroutine of default.
########################################################################
def submenu_do(items, env, prepend)
  html = '<ul>'
  items.sort_by(&:order).each do |item|
    next if item.hidden

    can_view, msg = agile_user_can_view(@env, item)
    next unless can_view

    if @opts[:edit_mode] > 1
      options = { table: 'ar_menu;ar_menu_item', form_name: :ar_menu_item, id: item.id, ids: "#{@menu.id};#{env.id}" }
      html += link_for_edit(options)
    end

    prepend_path = item.prepend_path ? prepend + [env.link] : []
    html += %(<li>#{link_4menu(item, prepend_path)}\n)
    if sub_menus = @menu_items[item.id]
      html += submenu_do(sub_menus, item, prepend_path)
    end
    html += '</li>'
  end
  html += '</ul>'
end

########################################################################
# Creates HTML code required for submenu on single level. Subroutine of default.
########################################################################
def menu_do
  html = '<ul>'
  if @opts[:edit_mode] > 1
    options = { table: :ar_menu, title: @menu.name, id: @menu.id }
    html += link_for_edit(options)
  end
  # read menu into hash
  @menu_items  = {}
  ArMenuItem.where(ar_menu_id: @menu.id, active: :true).each do |item|
    @menu_items[item.parent_id] ||= []
    @menu_items[item.parent_id] << item
  end
  return '' if @menu_items.size == 0

  @menu_items[0].sort_by(&:order).each do |item|
    next if item.hidden

    # menu can be hidden from user
    can_view, msg = agile_user_can_view(@env, item)
    next unless can_view

    selected = 'selected' if @opts[:path]&.first == item.link
    html += %(<li class="#{selected}">#{link_4menu(item, [])}\n)

    # SUBMENUS
    if sub_menus = @menu_items[item.id]
      html += submenu_do(sub_menus, item, [])
    end
    html += '</li>'
  end
  html += '</ul>'
end

########################################################################
# Creates default menu.
########################################################################
def default
  return "(#{@opts[:name]}) menu not found!" if @menu.nil?

  #@selected = find_selected
  div_name = @menu.div_name.blank? ? 'ar-menu' : @menu.div_name
  %(<nav class="#{div_name}">\n#{menu_do()}\n</nav>)
end

########################################################################
# Renderer dispatcher. Method returns HTML part of code.
########################################################################
def render_html
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "Error ArMenu: Method #{method} doesn't exist!"
end

########################################################################
# Return CSS part of code.
########################################################################
def render_css
  @menu.css if @menu
end

end
