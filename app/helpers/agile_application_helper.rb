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

###########################################################################

# AgileApplicationHelper defines common helper methods for using with AgileRails.
#
###########################################################################
module AgileApplicationHelper
# page document
attr_reader :page
# design document
attr_reader :design
# site document
attr_reader :site
# menu document
attr_reader :menu
# selected menu_item document
attr_reader :menu_item
# tables url parameter
attr_reader :tables
#  ids url parameter
attr_reader :ids
# form object
attr_reader :form
# options object
attr_reader :options
# part
attr_reader :part

# page title
attr_accessor :page_title
# all parts read from page, design, ...
attr_accessor :parts
#
attr_accessor :record
#
attr_accessor :footer_record
# json_ld
attr_reader :json_ld

############################################################################
# When @env is present then helper methods are called from @env object otherwise
# from self.
############################################################################
def _origin #:nodoc:
  @env || self
end

############################################################################
# Writes out deprication msg. It also adds site_name to message, so it is easier to
# find where the message is comming from.
############################################################################
def agile_deprecate(msg)
  ActiveSupport::Deprecation.warn("#{agile_get_site.name}: #{msg}")
end

############################################################################
# This is main method used for render parts of design into final HTML document.
#
# Parameters:
# [renderer] String or Symbol. Class name (in lowercase) that will be used to render final HTML code.
# If class name is provided without '_renderer' suffix it will be added automatically.
#
# When renderer has value :part, it is a shortcut for agile_render_part method which
# is used to draw parts of layout on design.
#
# [opts] Hash. Additional options that are passed to method. Options are merged with
# options set on site, design, page and passed to renderer object.
#
# Example:
#    <%= agile_render(:ar_page, method: 'view', category: 'news') %>
############################################################################
def agile_render(renderer, opts = {})
  return agile_render_part(renderer[:part]) if renderer.instance_of?(Hash)

  opts[:edit_mode]   = session[:edit_mode]
  opts[:edit_params] = {}

  opts = @options.merge(opts) # merge options with parameters passed on site, page, design ...
  opts.symbolize_keys!        # this makes lots of things easier
  # Create renderer object
  klass = renderer.to_s.downcase
  klass += '_renderer' unless klass.match('_renderer')
  begin
    renderer_object = Kernel.const_get(klass.classify, Class.new).new(self, opts)
  rescue Exception => e
    Agile.dump_exception(e)
    # obj = nil
  end

  if renderer_object
    html  = renderer_object.render_html.to_s
    @css += renderer_object.render_css.to_s
    html.html_safe
  else
    I18n.t 'agile.no_class', class: klass
  end
end

########################################################################
# Used for designs with lots of common code and one (or more) part which differs.
# Point is to define design once and replace some parts of design dynamically.
# Design may be defined in site and design doc defines only parts that vary
# from page to page.
#
# Example: As used in design.
#    <%= agile_render_part(@main) %>
#
#    main variable is defined in design body for example:
#
#    @main = Proc.new { render partial: 'parts/home' }
########################################################################
def agile_render_part(part)
  case
  when part.nil?
    logger.error('ERROR agile_render_part! part is NIL !'); ''
  # Send as array. Part may be defined with options on page. First element has
  # name of element which defines what to do. If not defined default behaviour is
  # called. That is what is defined in second part of array.
  when part.instance_of?(Array)
    if @options.dig(:settings, part.first)
      #TODO to be defined
    else
      result = part.last.call
      result.instance_of?(Array) ? result.first : result
    end
  when part.instance_of?(Proc)
    result = part.call
    result.instance_of?(Array) ? result.first : result
  # Send as string. Evaluate content of string
  when part.instance_of?(String)
    eval part
  # For future maybe. Just call objects to_s method.
  else
    part.to_s
  end.html_safe
end

########################################################################
# Helper for rendering top CMS menu when in editing mode
########################################################################
def agile_page_top
  # Evaluate some code if defined in design
  eval(@design.code) if @design&.code.present?

  session[:edit_mode] > 0 ? render(partial: 'agile/edit_stuff') : ''
end

########################################################################
# Helper for adding additional css and javascript code added by documents
# and renderers during page rendering.
########################################################################
def agile_page_bottom
  %(<style>#{@css}</style>#{javascript_tag @js}).html_safe
end

############################################################################
# Creates title div for AgileRails dialogs. Title may also contain pagination section on right side if
# data_set is provided as parameter.
#
# Parameters:
# [text] String. Title caption.
# [data_set=nil] Document collection. If data_set is passed pagination links will be created.

# Returns:
# String. HTML code for title.
############################################################################
def agile_dialog_title(text, data_set = nil)
  c = %(<div class="ar-title">#{text})
  c += agile_help_button(data_set)

  if data_set&.respond_to?(:current_page)
    c += %(<div class="ar-paginate">#{paginate(data_set, params: { action: 'index', clear: 'no', filter: nil })}</div>)
  end
  c += '<div style="clear: both;"></div></div>'
  c.html_safe
end

############################################################################
# Creates title for AgileRails forms edit dialog
#
# Returns:
# String. HTML code for title.
############################################################################
def agile_edit_title
  session[:form_processing] = 'form:title:'
  title = @form['form']['title']
  # defined as form:title:edit
  if title && title['edit'] && !@form['readonly']
    t( title['edit'], title['edit'] )
  elsif title && title['show'] && @form['readonly']
    t( title['show'], title['show'] )
  else
    # concatenate title
    c = "#{@form['readonly'] ? t('agile.show') : t('agile.edit')} : "
    c += (@form['title'].instance_of?(String) ? t( @form['title'], @form['title'] ) : t_table_name(@form['table']))
    title = title.try('field')

    c += "#{@record[title]}" if title && @record.respond_to?(title)
    c
  end
end

############################################################################
# Creates title for AgileRails new dialog
#
# Returns:
# String. HTML code for title.
############################################################################
def agile_new_title
  session[:form_processing] = 'form:title:'
  title = @form.dig('form', 'title')
  if title.is_a?(String) # defined as form:title
    t(title, title)
  elsif title&.dig('new') # defined as form:title:new
    t(title['new'], title['new'])
  else
    # in memory structures
    if @form['table'] == 'agile_memory'
      return t( @form['title'], @form['title'] ) if @form['title']

      t("#{@form['i18n_prefix']}.table_title", '')
    else
      "#{t('agile.new')} : #{t_table_name(@form['table'])}"
    end
  end
end

############################################################################
# Similar to rails submit_tag, but also takes care of link icon, translation, ...
############################################################################
def agile_submit_tag(caption, icon, parms, rest = {})
  icon_image = agile_icon_for_link(icon, nil)
  %(<button type="submit" class="ar-submit" name="commit" value="#{t(caption, caption)}">#{icon_image} #{t(caption, caption)}</button>).html_safe
end

############################################################################
# Returns icon code if icon is specified
############################################################################
def agile_icon_for_link(icon, clas = 'ar-link-img')
  return '' if icon.blank?

  if icon.match(/\./)
    _origin.image_tag(icon, class: clas)
  elsif icon.match('<i')
    icon
  else
    _origin.mi_icon(icon)
  end
end

############################################################################
# Similar to rails link_to, but also takes care of link icon, translation, ...
#
# Parameters:
# [String] caption : Caption or text created on link
# [String] icon : Icon used with the caption
# [Hash] parms : Standard parameters for link_to method (controller, action, id, table, form_name, ...)
# [Hash] rest : Standard rest parameters for link_to method (target, class, confirm ...)
############################################################################
def agile_link_to(caption, icon, parms, rest = {})
  url, body, parms, rest = _agile_link_to(caption, icon, parms, rest)
  url ? _origin.link_to(body, url, rest) : _origin.link_to(body, parms, rest)
end

############################################################################
# Creates link that will respond to json data returned by invoked action
#
# Parameters:
# [String] caption : Caption or text created on link
# [String] icon : Icon used with the caption
# [Hash] parms : Standard parameters for link_to method (controller, action, id, table, form_name, ...)
# [Hash] rest : Standard rest parameters for link_to method (target, class, confirm ...)
############################################################################
def agile_ajax_link_to(caption, icon, parms, rest = {})
  url, body, parms, rest = _agile_link_to(caption, icon, parms, rest)
  url ||= _origin.url_for(parms)
  clas = "ar-link-ajax #{rest.delete('class')}"
  rest['data-confirm'] ||= rest.delete('confirm')
  rest_data = rest.map { "#{_1}=\"#{_2}\"" }.join(', ')

  %(<span class="#{clas}" data-url="#{url}" #{rest_data}>#{body}</span>).html_safe
end

############################################################################
# Will use some default values and return data for previous link_to methods
############################################################################
def _agile_link_to(caption, icon, parms, rest) # :nodoc:
  icon_pos = 'first'
  if parms.instance_of?(Hash)
    parms.stringify_keys!
    rest.stringify_keys!
    url = parms.delete('url')
    rest['target'] ||= parms.delete('target')
    parms['controller'] ||= 'agile'
    icon_pos = parms.delete('icon_pos') || 'first'
  end

  icon_image = agile_icon_for_link(icon)
  if caption
    caption     = t(caption, caption)
    icon_image += ' ' if icon_image
  end
  body = (%w[first left].include?(icon_pos) ? "#{icon_image}#{caption}" : "#{caption} #{icon_image}").html_safe
  [url, body, parms, rest]
end

####################################################################
# Returns flash messages formatted for display on message div.
#
# Returns:
# String. HTML code formatted for display.
####################################################################
def agile_flash_messages()
  err    = _origin.flash[:error]
  war    = _origin.flash[:warning]
  inf    = _origin.flash[:info]
  note   = _origin.flash[:note]
  html   = ''
  unless err.nil? and war.nil? and inf.nil? and note.nil?
    html += "<div class=\"ar-form-error\">#{err}</div>" if err
    html += "<div class=\"ar-form-warning\">#{war}</div>" if war
    html += "<div class=\"ar-form-info\">#{inf}</div>" if inf
    html += note if note
    _origin.flash[:error]   = nil
    _origin.flash[:warning] = nil
    _origin.flash[:info]    = nil
    _origin.flash[:note]    = nil
  end
  # Update fields on the form
  if _origin.flash[:update]
    html += "<div class=\"ar-form-updates\">\n"
    _origin.flash[:update].each do |field, value|
      html += %(<div data-field="#{field}" data-value="#{value}"></div>\n)
    end
    html += '</div>'
    _origin.flash[:update] = nil
  end
  html.html_safe
end

########################################################################
# Decamelizes string. This probably doesn't work very good with non ascii chars.
# Therefore it is very unwise to use non ascii chars for table (table) names.
#
# Parameters:
# [Object] model_string. String or model to be converted into decamelized string.
#
# Returns:
# String. Decamelized string.
########################################################################
def decamelize_type(model_string)
  model_string&.to_s&.underscore
end

####################################################################
# Returns validation error messages for the document (record) formatted for
# display on message div.
#
# Parameters:
# [doc] Document. Document record which will be checked for errors.
#
# Returns:
# String. HTML code formatted for display.
####################################################################
def agile_error_messages_for(doc)
  return '' unless doc&.errors.any?

  msgs = doc.errors.inject('') do |r, error|
    label = t("helpers.label.#{decamelize_type(doc.class)}.#{error.attribute}", error.attribute)
    "#{r}<li>#{label} : #{error.message}</li>"
  end

  %(
<div class="ar-form-error">
  <h2>#{t('agile.errors_no')} #{doc.errors.size}</h2>
  <ul>#{msgs}</ul>
</div>).html_safe
end

####################################################################
# Returns warning messages if any set in a model.
#
# When warnings array is added to model its content can be written on top of the form.
#
# Parameters:
# [doc] Document. Document record which will be checked for errors.
#
# Returns:
# String. HTML code formatted for display.
####################################################################
def agile_warning_messages_for(doc)
  return '' # NOT WORKING
  return '' unless doc&.respond_to?(:warnings)

  msgs = doc.warnings.inject('') do |r, error|
    label = t("helpers.label.#{decamelize_type(doc.class)}.#{error.attribute}", error.attribute)
    "#{r}<li>#{label} : #{error.message}</li>"
  end

  %(
<div class="ar-form-warning">
  <h2>#{t('agile.warnings_no')} #{doc.warnings.size}</h2>
  <ul>#{msgs}</ul>
</div>).html_safe
end

####################################################################
# Checks if CMS is in edit mode (CMS menu bar is visible).
#
# Returns:
# Boolean. True if in edit mode
####################################################################
def agile_edit_mode?
  _origin.session[:edit_mode] > 1
end

####################################################################
# Will create HTML code required to create new document.
#
# Parameters:
# [opts] Hash. Optional parameters for url_for helper. These options must provide at least table and form_name
# parameters.
#
# Example:
#    if @opts[:edit_mode] > 1
#      opts = {table: 'agile_page;agile_part', form_name: 'agile_part', ids: @doc.id }
#      html += agile_link_for_create( opts.merge!({title: 'Add new part', 'agile_part.name' => 'initial name', 'agile_part.order' => 10}) )
#    end
#
# Returns:
# String. HTML code which includes add image and javascript to invoke new document create action.
####################################################################
def agile_link_for_create(opts)
  opts.stringify_keys!
  title = opts.delete('title') #
  title = t(title, title) if title
  target = opts.delete('target') || 'iframe_cms'
  opts['form_name']  ||= opts['table'].to_s.split(';').last
  opts['action']       = :new
  opts['controller'] ||= :agile
  url_forward_params(opts)
  js = "$('##{target}').attr('src', '#{_origin.url_for(opts)}'); return false;"
  agile_link_to(nil, _origin.mi_icon('plus-circle'), '#',
                { onclick: js, title: title, alt: 'Create', class: 'ar-inline-link'}).html_safe
end

####################################################################
# Will create HTML code required to edit document.
#
# Parameters:
# [opts] Hash. Optional parameters for url_for helper. These options must provide
# at least table, form_name and id parameters. Optional title, target and icon parameters
# can be set.
#
# Example:
#    html += agile_link_for_edit( @options ) if @opts[:edit_mode] > 1
#
# Returns:
# String. HTML code which includes edit image and javascript to invoke edit document action.
####################################################################
def agile_link_for_edit(opts)
  opts.stringify_keys!
  title  = opts.delete('title') #
  title  = t(title)
  target = opts.delete('target') || 'iframe_cms'
  icon   = opts.delete('icon') || 'edit-o'
  opts['controller'] ||= :agile
  opts['action']     ||= 'edit'
  opts['form_name']  ||= opts['table'].to_s.split(';').last

  js = "$('##{target}').attr('src', '#{_origin.url_for(opts)}'); return false;"
  agile_link_to(nil, _origin.mi_icon(icon), '#',
                { onclick: js, title: title, class: 'ar-inline-link', alt: 'Edit'})
end

####################################################################
# Create edit link with edit picture. Subroutine of agile_page_edit_menu.
####################################################################
def agile_link_menu_tag(title) #:nodoc:
  html = %(
<dl>
  <dt><div class='ar_popmenu ar-inline-link' href="#">
    #{_origin.mi_icon('file-text-o', title: title)}
  </div></dt>
  <dd>
    <ul class=' div-hidden ar_popmenu_class'>
)

  yield html
  "#{html}</ul></dd></dl>"
end

####################################################################
# Create one option in page edit link. Subroutine of agile_page_edit_menu.
####################################################################
def agile_link_for_edit1(opts, link_text) #:nodoc:
  icon = opts.delete('icon')
  url  = _origin.url_for(opts)
  "<li><div class='ar_popmenu_item' style='cursor: pointer;' data-url='#{url}'>
#{_origin.mi_icon(icon)} #{link_text}</div></li>\n"
end

########################################################################
# Create edit menu for editing existing or creating new agile_page documents. Edit menu
# consists of for options.
# * Edit content. Will edit only body part od document.
# * Edit advanced. Will create edit form for editing all document fields.
# * New page. Will create new document and pass some initial data to it. Initial data is saved to cookie.
# * New part. Will create new part of document.
#
# Parameters:
# [opts] Hash. Optional parameters for url_for helper. These options must provide at least table and form_name
# and id parameters.
#
# Example:
#    html += agile_page_edit_menu() if @opts[:edit_mode] > 1
#
# Returns:
# String. HTML code required for manipulation of currently processed document.
########################################################################
def agile_page_edit_menu(opts = @opts)
  opts[:edit_mode] ||= _origin.session[:edit_mode]
  return '' if opts[:edit_mode] < 2

  # save some data to cookie. This can not go to session.
  page  = opts[:page] || @page
  table = _origin.site.page_class.underscore
  kukis = { "#{table}.ar_design_id" => page.ar_design_id,
            #            "#{table}.menu_id"      => page.menu_id,
            #            "#{table}.kats"         => page.kats,
            "#{table}.page_id" => page.id,
            "#{table}.ar_site_id" => _origin.site.id
  }
  _origin.cookies[:record] = Marshal.dump(kukis)
  title = "#{t('agile.edit')}: #{page.subject}"
  opts[:edit_params] ||= {}
  agile_link_menu_tag(title) do |html|
    opts[:edit_params].merge!( controller: :agile, action: 'edit', 'icon' => 'edit-o' )
    opts[:edit_params].merge!( id: page.id, table: _origin.site.page_class.underscore, form_name: opts[:form_name], edit_only: 'body' )
    html += agile_link_for_edit1( opts[:edit_params], t('agile.edit_content') )

    opts[:edit_params].merge!( edit_only: nil, 'icon' => 'edit-o' )
    html += agile_link_for_edit1( opts[:edit_params], t('agile.edit_advanced') )

    opts[:edit_params].merge!( action: 'new', 'icon' => 'plus' )
    html += agile_link_for_edit1( opts[:edit_params], t('agile.edit_new_page') )

    opts[:edit_params].merge!(ids: page.id, form_name: 'agile_part', 'icon' => 'plus',
                              table: "#{_origin.site.page_class.underscore};agile_part" )
    html + agile_link_for_edit1( opts[:edit_params], t('agile.edit_new_part') )
  end.html_safe
end

########################################################################
# Return page class model defined in site document page_class field.
#
# Used in forms, when method must be called from page model and model is overwritten by
# user's own model.
#
# Example as used on form:
#    30:
#      name: link
#      type: text_with_select
#      eval: 'agile_page_class.all_pages_for_site(@env.agile_get_site)'
########################################################################
def agile_page_class
  agile_get_site.page_klass
end

########################################################################
# Return menu class model defined in site document menu_class field.
#
# Used in forms for providing menus class to the forms object.
#
# Example as used on form:
#    30:
#      name: menu_id
#      type: tree_view
#      eval: 'agile_menu_class.all_menus_for_site(@env.agile_get_site)'
########################################################################
def agile_menu_class
  agile_get_site.menu_class.classify.constantize
end

####################################################################
# Parse site name from url and return ar_site document. Site document will be cached in
# @site variable.
#
# If not in production environment and site document is not found
# method will search for 'test' document and return ar_site document found in alias_for field.
#
# Returns:
# ArSite. Site document.
####################################################################
def agile_get_site
  return @site if @site # already cached

  reqst = _origin.request.url # different when called from renderer
  uri   = URI.parse(reqst)
  @site = ArSite.find_by(name: uri.host)
  # Site can be aliased
  @site = ArSite.find_by(name: @site.alias_for) if @site&.alias_for.present?
  # Development. If site with name test exists use alias_for field as pointer to real site data
  if @site.nil? && ENV['RAILS_ENV'] != 'production'
    @site = ArSite.find_by(name: 'development')
    @site = ArSite.find_by(name: @site.alias_for) if @site
  end
  @site = nil unless @site&.active # might be disabled
  @site
end

############################################################################
# Return array of policies defined in a site document formated to be used
# as choices for select field. Method is used for selecting site policy where
# policy for displaying data is required.
#
# Example (as used in forms):
#    name: policy_id
#    type: select
#    eval: agile_choices_for_site_policies
#    include_blank: true
############################################################################
def agile_choices_for_site_policies
  agile_get_site.site_policies.map { |policy| [policy.name, policy.id] }
end

############################################################################
# Returns list of all collections (tables) as array of choices for usage in select fields.
# List is collected from agile_menu.yml files and may not include all collections used in application.
# Currently list is only used for helping defining collection names on agile_permission form.
#
# Example (as used in forms):
#    form:
#      fields:
#        10:
#          name: table_name
#          type: text_with_select
#          eval: agile_choices_for_all_tables
############################################################################
def agile_choices_for_all_tables
  choices = {}
  Agile.paths(:forms).reverse.each do |path|
    filename = "#{path}/agile_menu.yml"
    next unless File.exist?(filename)

    menu = YAML.load_file(filename) rescue nil # load menu
    next unless menu['menu']                   # not menu or error

    menu['menu'].each do |section|
      next unless section.last['items']        # next if no items

      section.last['items'].each_value do |v|
        key = v['table']
        choices[key] ||= "#{key} - #{t(v['caption'], v['caption'])}"
      end
    end
  end
  choices.invert.to_a.sort # hash has to be inverted for values to be returned right
end

##########################################################################
# html code for AgileRails application menu
##########################################################################
def agile_application_menu
  menus = {}
  Agile.paths(:forms).reverse.each do |path|
    filename = "#{path}/agile_menu.yml"
    next unless File.exist?(filename)

    menu = YAML.load_file(filename) rescue nil # load menu file
    next unless menu['menu']

    menus = AgileHelper.forms_merge(menu['menu'], menus) # ignore top level
  end

  html = '<ul>'
  menus.to_a.sort.each do |index, menu| # sort menu numbers
    next unless menu['caption']

    icon = menu['icon'].match('/') ? image_tag(menu['icon']) : mi_icon(menu['icon']) #external or fa- image
    html += %(<li class="agile-top-level-menu"><div>#{icon}#{t(menu['caption'])}</div><ul>)
    menu['items'].to_a.sort.each do |index1, option| # sort by menu items
      html += if option['link']
                opts = { target: option['target'] || 'iframe_cms' }
                "<li>#{agile_link_to(t(option['caption']), option['icon'], option['link'], opts)}</li>"
              else
                opts = { controller: option['controller'],
                         action: option['action'],
                         table: option['table'],
                         form_name: option['form_name'] || option['table'],
                         target: option['target'] || 'iframe_cms',
                       }
                "<li>#{agile_link_to(t(option['caption']), option['icon'], opts)}</li>"
              end
    end
    html += '</ul></li>'
  end
  html.html_safe
end

############################################################################
# Returns list of directories as array of choices for use in select field
# on folder permission form. Directory root is determined from ar_site.files_directory field.
############################################################################
def agile_choices_for_folders
  public  = File.join(Rails.root,'public')
  home    = File.join(public, agile_get_site.files_directory)
  choices = Dir.glob("#{home}/**/*/").select { |fn| File.directory?(fn) }
  choices << home # add home
  choices.map { _1.gsub(public, '') }.sort # remove public part
end

############################################################################
# Returns choices for select input field when choices are generated from
# all documents in collection.
#
# Parameters:
# [model] String. Collection (table) name in lowercase format.
# [name] String. Field name containing description text.
# [id] String. Field name containing id field. Default is '_id'
# [options] Hash. Various options. Currently site: (:only, :with_nil, :all) is used.
# Will return only documents belonging to current site, also with site not defined,
# or all documents.
#
# Example (as used in forms):
#    50:
#      name: agile_poll_id
#      type: select
#      eval: agile_choices_for('agile_poll','name','_id')
############################################################################
def agile_choices_for(model, name, id = 'id', options = {})
  model = model.classify.constantize
  qry   = model.select(id, name)
  if (param = options[:site])
    sites = [agile_get_site.id] unless param == :all
    sites << nil if param == :with_nil
    qry   = qry.where(ar_site_id: sites) if sites
  end
  qry = qry.where(active: true) if model.has_attribute?(:active)
  qry.order(name => :asc).map { [_1[name], _1[id]] }
end

############################################################################
# Returns list of choices for selection top level menu on agile_page form. Used for defining which
# top level menu will be highlited when page is displayed.
#
# Example (as used in forms):
#    20:
#      name: menu_id
#      type: select
#      eval: agile_choices_for_menu
############################################################################
def agile_choices_for_menu
  menu_class = agile_get_site.menu_class
  menu_class = 'ArMenu' if menu_class.blank?
  klass = menu_class.classify.constantize
  klass.choices_for_menu(agile_get_site)
end

############################################################################
# Will add data to record cookie. Record cookie is used to preload some
# data on next create action. Create action will look for cookies[:record] and
# if found initialize fields on form with matching name to value found in cookie data.
#
# Example:
#    kukis = {'agile_page.ar_design_id' => @page.ar_design_id,
#             'agile_page.agile_menu_id' => @page.menu_id)
#   agile_add2_record_cookie(kukis)
############################################################################
def agile_add2_record_cookie(hash)
  kukis = if @env.cookies[:record]&.present?
            Marshal.load(@env.cookies[:record])
          else
            {}
          end
  hash.each { |k, v| kukis[k] = v }
  @env.cookies[:record] = Marshal.dump(kukis)
end

############################################################################
# Will check if user roles allow user to view data in document with defined access_policy.
#
# Parameters:
# [ctrl] Controller object or object which holds methods to access environment. For example @env
# when called from renderer.
# [policy_id] Document or documents policy_id field value required to view data. Method will automatically
# check if parameter send has policy_id field defined and use value of that field.
#
# Example:
#    can_view, message = agile_user_can_view(@env, @page)
#    # or
#    can_view, message = agile_user_can_view(@env, @page.policy_id)
#    return message unless can_view
#
# Returns:
# True if access_policy allows user to view data.
# False and message from policy that is blocking view if access is not allowed.
############################################################################
def agile_user_can_view(ctrl, policy_id)
  @can_view_cache ||= {}
  policy_id = policy_id.policy_id if policy_id&.respond_to?(:policy_id)
  # Eventualy object without policy_id will be checked. This is to prevent error
  policy_id = nil unless policy_id.instance_of?(Integer)
  return @can_view_cache[policy_id] if @can_view_cache[policy_id]

  # get site policies
  site = ctrl.site
  policies = (site.inherit_policy.blank? ? site : ArSite.find(site.inherit_policy)).site_policies.to_a
  # get default policy
  default_policy = policies.find(&:is_default)
  return cache_can_view(policy_id, false, 'Default access policy not found for the site!') unless default_policy

  permissions = {}
  default_policy.ar_policy_rules.each { |v| permissions[v.ar_role_id] = v.permission }
  # update permissions with defined policy
  part_policy = nil
  if policy_id
    part_policy = policies.find { |policy| policy.id == policy_id }
    return cache_can_view(policy_id, false, 'Access policy not found for part!') unless part_policy

    part_policy.ar_policy_rules.each { |v| permissions[v.ar_role_id] = v.permission }
  end
  # apply guest role if no roles defined
  if ctrl.session[:user_roles].nil?
    guest_role = ArRole.get_role('guest')
    return cache_can_view(policy_id, false, 'System guest role not defined!') unless guest_role

    ctrl.session[:user_roles] = [guest_role.id]
  end
  # Check if user has any role that allows him to view part
  can_view = ctrl.session[:user_roles].find{ |role| permissions[role]&.to_i > 0 }
  msg = ''
  unless can_view
    msg = part_policy ? t(part_policy.message, part_policy.message) : t(default_policy.message, default_policy.message)
    # message may have variable content
    msg = _origin.render(inline: msg, layout: nil) if msg.match('<%=')
  end
  cache_can_view(policy_id, can_view, msg)
end

####################################################################
# Check if user has required role assigned to its user profile. If role is passed as
# string method will check roles for name and system name.
#
# Parameters:
# [role] ArRole/String. Required role. If passed as string role will be searched in agile_policy_roles collection.
# [user] User id. Defaults to session[:user_id].
# [roles] Array of roles that will be searched. Default session[:user_roles].
#
# Example:
#    if agile_user_has_role?('decision_maker', session[:user_id), session[:user_roles])
#      do_something_important
#    end
#
# Returns:
# Boolean. True if user has required role.
####################################################################
def agile_user_has_role?( role, user = nil, roles = nil )
  roles = _origin.session[:user_roles] if roles.nil?
  user  = _origin.session[:user_id] if user.nil?
  return false if user.nil? || roles.nil?

  role = ArRole.get_role(role)
  return false if role.nil?

  # role is included in roles array
  roles.include?(role.id)
end

####################################################################
# Returns true if parameter has value of 0, false, no, none or -.
# Returns value of default if parameter has nil value.
#
# Parameters:
# [what] String/boolean/Integer.
# [default] Default value when what has value of nil. False by default.
#
# Example:
#    agile_dont?('none')    # => true
#    agile_dont?('-')       # => true
#    agile_dont?(1)         # => false
#    agile_dont?(nil, true) # => true
####################################################################
def agile_dont?(what, default = false)
  AgileHelper.dont?(what, default)
end

############################################################################
# Truncates string length maximal to the size required and takes care, that words are not broken in middle.
# Used for output text summary with texts that can be longer then allowed space.
#
# Parameters:
# [string] String of any size.
# [size] Maximal size of the string to be returned.
#
# Example:
#    agile_limit_string(description, 100)
#
# Returns:
# String, truncated to required size. If string is truncated '...' will be added to the end.
############################################################################
def agile_limit_string(string, size)
  return string if string.size <= size

  string = string[0, size]
  string.chop! until string[-1, 1] == ' ' || string == ''
  "#{string}..."
end

############################################################################
# Returns key defined in ArBigTable as array of choices for use in select fields.
# ArBigTable can be used like a key/value store for all kind of predefined values
# which can be linked to site and or locale.
#
# Parameters:
# [key] String. Key name to be searched in agile_big_tables documents.
#
# Example:
#    10:
#      name: category
#      type: select
#      eval: agile_big_table_choices 'categories_for_page'  # as used on form
#
# Returns:
# Array of choices ready for select field.
############################################################################
def agile_big_table_choices(key)
  ret = []
  bt = ArBigTable.find_by(key: key, site_id: agile_get_site.id, active: true) ||
       ArBigTable.find_by(key: key, site_id: nil, active: true)
  return ret if bt.nil?

  bt.ar_big_table_values.order(description: 'asc').each do |ar_value| # iterate values
    next unless ar_value.active

    desc = ar_value.get_localized_description
    ret << [desc, ar_value.value]
  end
  ret
end

########################################################################
# Will return html code required for load AgileRails form into iframe. If parameters
# are passed to method iframe url will have initial value and thus enabling automatic form
# load on page display.
#
# Parameters:
# [table] String: Collection (table) name used to load initial form.
# [opts] Hash: Optional parameters which define url for loading AgileRails form.
# These parameters are :action, :oper, :table, :form_name, :id, :readonly
#
# Example:
#    # just iframe code
#    <%= agile_edit_frame(nil) %>
#    # load note form for note collection into iframe with name iframe_name
#    <%= agile_edit_frame('note', iframe: 'iframe_name') %>
#    # on register collection use reg_adresses form_name to display data with id @register.id
#    <%= agile_edit_frame('register', action: :show, form_name: 'reg_adresses', readonly: 1, id: @register.id ) %>
#
# Returns:
# Html code for edit iframe
########################################################################
def agile_edit_frame(table, opts = {})
  iframe_name = opts[:iframe] || 'iframe_edit'
  if params.to_unsafe_h.size > 2 && table # controller, action, path is minimal
    params[:controller] = :agile
    params[:action]     = params[:oper] == 'edit' ? 'edit' : 'index'
    params[:action]     = opts[:action] unless params[:oper]
    params[:table]      ||= table
    params[:form_name]  ||= opts[:form_name] || table
    params[:id]         ||= params[:idp] || opts[:id]
    params[:readonly]   ||= opts[:readonly]
    params[:path]       = nil
    params.permit! # rails 5 request
    "<iframe id='#{iframe_name}' name='#{iframe_name}' src='#{url_for params}'></iframe>"
  else
    "<iframe id='#{iframe_name}' name='#{iframe_name}'></iframe>"
  end.html_safe
end

########################################################################
# Will return value from Rails and AgileRails environment objects.
# This objects can be params, session, record, site, page
#
# Parameters:
# [object] String: Internal object holding variable. Possible values are session, params, record, site, page, class
# [var_name] String[symbol]: Variable name (:user_name, 'user_id', ...)
# [current_record] Object: If passed and object is 'record' then current active record it will be used for retrieving data.
#
# Example:
#    # called when constructing iframe for display
#    agile_internal_var('session', :user_id)
#    agile_internal_var('params', :some_external_parameter)
#    agile_internal_var('site', :name)
#    # or even
#    agile_internal_var('class', 'ClassName.class_method_name')
#
#
# Returns:
# Value of variable or error when not found
########################################################################
def agile_internal_var(object, var_name, current_record = nil)
  begin
    case object.to_s
    when 'session' then _origin.session[var_name]
    when 'params'  then _origin.params[var_name]
    when 'site'    then _origin.agile_get_site.send(var_name)
    when 'page'    then _origin.page.send(var_name)
    when 'record'
      current_record ? current_record.send(var_name) : _origin.record.send(var_name)
    when 'class'
      clas, method_name = var_name.split('.')
      klas = clas.classify.constantize
      # call method. Error will be caught below.
      klas.send(method_name)
    when 'eval' then eval("_origin.#{var_name}")
    else
      'VARIABLE: UNKNOWN OBJECT'
    end
  rescue Exception => e
    Rails.logger.error "\nagile_internal_var. Runtime error. #{e.message}\n"
    Rails.logger.error(e.backtrace.join($/)) if Rails.env.development?
    'VARIABLE: ERROR'
  end
end

########################################################################
# Will return formated code for embedding json+ld data into page
#
# Returns:
# HTML data to be embedded into page header
#######################################################################
def agile_get_json_ld
  return '' if @json_ld.nil? || @json_ld.size == 0

  %(
<script type="application/ld+json">
#{JSON.pretty_generate({ '@context' => 'http://schema.org', '@graph' => @json_ld })}
</script>
).html_safe
end

########################################################################
# Will add new element to json_ld structure
#
# Parameters:
# [element] Hash or Array of hashes: json+ld element
#######################################################################
def agile_add_json_ld(element)
  @json_ld ||= []
  if element.instance_of?(Array)
    @json_ld << element
  else
    @json_ld << element
  end
end

########################################################################
# Will return meta data for SEO optimizations
#
# Returns:
# HTML data to be embedded into page header
#######################################################################
def agile_get_seo_meta_tags
  html = ''
  html += %(<link rel="canonical" href="#{@page.canonical_link}">\n  ) unless @page&.canonical_link.blank?
  if @meta_tags
    html += @meta_tags.inject('') do |r, hash|
      r + %(<meta #{hash.first} content="#{hash.last}">\n  )
    end
  end
  html.html_safe
end

########################################################################
# Will add a meta tag to internal hash structure. If meta tag already exists it
# will be overwritten.
#
# Parameters:
# [name] String: meta name
# [content] String: meta content
########################################################################
def agile_add_meta_tag(type, name, content)
  return if content.blank?

  @meta_tags ||= {}
  key = "#{type}=\"#{name}\""
  @meta_tags[key] = content
end

#######################################################################
# Will return alt image option when text is provided. When text is blank
# it will extract alt name from picture file_name. This method returns
# together with alt="image-tag" tag.
#
# Parameters:
# [file_name] String: Filename of a picture
# [text] String: Alt text name
#
# Returns:
# [String] alt="image-tag"
#######################################################################
def agile_img_alt_tag(file_name, text = nil)
  %( alt="#{agile_img_alt(file_name, text)}" ).html_safe
end

#######################################################################
# Will return alt image option when text is provided. When text is blank
# it will extract alt name from picture file_name. This method returns just
# alt name.
#
# Parameters:
# [file_name] String: Filename of a picture
# [text] String: Alt text name
#
# Returns:
# [String] alt_image_name
#######################################################################
def agile_img_alt(file_name, text = nil)
  return text if text.present?

  name = File.basename(file_name.to_s)
  name[0, name.index('.')].downcase rescue name
end

########################################################################
# Will return name for value defined in ar_big_table
########################################################################
def agile_big_table_name_for_value(key, value)
  agile_big_table_choices(key).each { |k, val| return k if val.to_s == value.to_s}
  '???'
end

private

# will cache agile_user_can_view response
def cache_can_view(id, can_view, msg)
  @can_view_cache[id] = [can_view, msg]
end

end
