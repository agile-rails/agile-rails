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
# Renders code for displaying a poll. Polls may replace forms when user interaction
# is required in browser.
########################################################################
class ArPollRenderer

include AgileCommonHelper
include AgileApplicationHelper
include ActionView::Helpers::FormHelper # for form helpers
include ActionView::Helpers::FormOptionsHelper # for select helper

########################################################################
# Object initialization.
########################################################################
def initialize( env, opts = {} ) #:nodoc:
  @env      = env
  @opts     = opts
  @part_css = ''
  @part_js  = ''
  self
end

########################################################################
# Dummy params method for accesing environment params object from form.
########################################################################
def params
  @env.params
end

########################################################################
# Outputs code required for poll item. Subroutine of default method.
########################################################################
def do_one_item(poll, yaml)
  html = ''
  yaml['separator'] ||= ''
  yaml['text']      ||= ''
  # label
  text = yaml['text'].match(/\./) ? t(yaml['text']) : yaml['text']
  if yaml['mandatory']
    text += ( poll.display == 'in' ? ' *' : '<span class="required"> *</span>' )
    yaml['html'] ||= {}
    yaml['html']['required'] = true
  else
    text += ' &nbsp;' if poll.display == 'lr' and !yaml['type'].match(/submit_tag|link_to/)
  end

  # Just add text if comment and go to next one
  if yaml['type'] == 'comment'
    html += if poll.display == 'lr'
      "<div class='row-div'><div class='ar-form-label poll-data-text comment no_help'>#{text}</div></div>"
    else
      "<div class='poll-data-text comment'>#{text}</div>"
    end
    return html
  end

  # Set default value, if not already set
  if yaml['default']
    if yaml['default'].match('eval')
      e = yaml['default'].match(/\((.*?)\)/)[1]
      yaml['default'] = eval e
    elsif yaml['default'].match('params')
      param_name = yaml['default'].split(/\.|\ |\,/)[1]
      yaml['default'] = @env.params[param_name]
    end
    key = "p_#{yaml['name']}"
    params[key] = yaml['default'] unless params[key]
  end
  # Label as placeholder
  if poll.display == 'in'
    yaml['html'] ||= {}
    yaml['html']['placeholder'] = text
  end
  # create form_field object and retrieve html code
  clas_string = yaml['type'].camelize
  field_html = if AgileFormFields.const_defined?(clas_string)
                 clas  = AgileFormFields.const_get(clas_string)
                 field = clas.new(@env, @record, yaml).render
                 @part_js += field.js
                 field.html
               else # error string
                 "Error: Code for field type #{yaml['type']} not defined!"
               end

  if yaml['type'].match(/submit_tag|link_to/)
    # There can be more than one links on form. End the data at first link or submit.
    unless @end_of_data
      html += (poll.display == 'lr' ? "</div><br>\n" : "</div>\n")
      # captcha
      if poll.captcha_type.to_s.size > 1
        @opts.merge!(:captcha_type => poll.captcha_type)
        captcha = ArCaptchaRenderer.new(@env, @opts)
        html += captcha.render_html
        @part_css = captcha.render_css
      end
      @end_of_data = true
    end
    # submit and link tag
    clas = yaml['type'].match(/submit_tag/) ? '' : 'ar-link-submit'
    html += "<span class='#{clas}'>#{field_html}#{yaml['separator']}</span>"
  # other fields
  else
    html += case
      when poll.display == 'lr'
        "<div class='row-div'><div class='ar-form-label poll-data-text lr #{yaml['class']} no_help'>#{text}</div>
         <div class='poll-data-field td #{yaml['class']}'>#{field_html}</div></div>\n"
      when poll.display == 'td' then
        "<div class='poll-data-text td #{yaml['class']}'>#{text}</div>
         <div class='poll-data-field td #{yaml['class']}'>#{field_html}#{yaml['separator']}</div>\n"
      else
        "<div class='poll-data-field in #{yaml['class']}'>#{field_html}#{yaml['separator']}</div>\n"
    end
  end
end

########################################################################
# Call method before poll is displayed. Usefull for filling predefined values into flash[:record][value]
# Method cane be defined as ClassName.method or only method.
# If only method is defined then method name must exist in helpers.
#
# Called method must return at least one result if process can continue.
########################################################################
def eval_pre_display(code)
  a = code.strip.split('.')
  if a.size == 1
    continue, message = @env.send(a.first)
  else
    klass = a.first.classify.constantize
    continue, message = klass.send(a.last,@env)
  end
  [continue, message]
end

########################################################################
# Default poll renderer method. Renders data for specified pool.
########################################################################
def default
  # poll_id may be defined in params or opts
  poll_id = @opts[:poll_id] || @env.params[:poll_id]
  return '<br>Poll id is not defined?<br>' if poll_id.nil?

  poll = ArPoll.find_by(id: poll_id) || ArPoll.find_by(name: poll_id)
  return %(<div class="ar-form-error">Invalid Poll id #{poll_id}</div>) if poll.nil?

  # If env cant be seen. so cant be polls
  can_view, message = agile_user_can_view(@env, @env.page)
  return %(<div class="ar-form-error">#{message}</div>) unless can_view

  html = @opts[:div] ? %(<div id="#{@opts[:div]}"'>) : ''
  html += '<a name="poll-top"></a>'
  if poll.pre_display.present?
    begin
      continue, message = eval_pre_display(poll.pre_display)
    rescue Exception => e
      return %(<div class="ar-form-error">Error! Poll pre display. Error: #{e.message}</div>)
    end
    return message unless continue

    html += message if message
  end
  # there might be more than one poll displayed on page. Check if messages and values are for me
  if @env.flash[:poll_id].nil? || @env.flash[:poll_id].to_s == poll_id.to_s
    # If flash[:record] is present copy content to params record hash
    @env.flash[:record].each {|k,v| @env.params["p_#{k}"] = v } if @env.flash[:record]
    # Error during procesing request
    html += %(<div class="ar-form-error">#{@env.flash[:error]}</div>\n) if @env.flash[:error].to_s.size > 0
    html += %(<div class="ar-form-info">#{@env.flash[:info]}</div>\n) if @env.flash[:info]
  end
  # div and form tag
  html +=  %(<div class="poll-div">\n)
  # edit link
  if @opts[:edit_mode] > 1
    @opts[:edit_params].merge!( controller: :agile, action: :edit, id: poll.id, table: 'ar_poll', form_name: 'ar_poll' )
    @opts[:edit_params].merge!(title: "#{t('agile.edit')}: #{poll.name}")
    @opts[:edit_params].delete(:ids) # this is from page, but it gets in a way
    html += agile_link_for_edit( @opts[:edit_params] )
  end

  html += case
  when poll.operation == 'poll_submit' then
    @env.form_tag(action: poll.operation, method: :put)
  when poll.operation == 'link' then
    @env.form_tag( poll.parameters, method: :put)
  end
  # header, - on first position will not display title
  html += %(<div class="poll-title">#{poll.title}</div>) unless poll.title[0] == '-'
  html += %(<div class="poll-text">#{poll.sub_text}</div>)
  html += if poll.display == 'lr'
            %(\n<div class="poll-data-table">)
          else
            %(<div class="poll-data-div">\n)
          end
  # items. Convert each item to yaml
  @end_od_data = false
  if poll.form.to_s.size < 10
    poll.ar_poll_items.order(order: 'asc').each do |item|
      next unless item.active # disabled items

      # convert options to yaml
      begin
        yaml = YAML.load(item.options) || {}
        yaml = {} if yaml.class == String
      rescue Exception => e
        html += %(<div class="ar-form-error">Item #{item.name}! Error: #{e.message}</div>)
        next
      end

      yaml['name'] = item.name
      yaml['html'] ||= {}
      yaml['html']['size'] = item.size
      (yaml['html']['class'] ||= 'ra-submit') if item.field_type == 'submit_tag'
      yaml['text']      = item.text
      yaml['mandatory'] = item.mandatory
      yaml['type']      = item.field_type

      html += do_one_item(poll, yaml)
    end
  else
    yaml = YAML.load(poll.form.gsub('&nbsp;', ' ')) # very annoying. They come with copy&paste ;-)
    # if entered without numbering yaml is returned as Hash otherwise as Array
    yaml.each { |i| html += do_one_item(poll, (i.class == Hash ? i : i.last)) }
  end
  # hide some fields usefull as parameters
  html += @env.hidden_field_tag('return_to', @opts[:return_to] || @env.params[:return_to] || @env.request.url)
  html += @env.hidden_field_tag('return_to_error', @env.request.url)
  html += @env.hidden_field_tag('poll_id', poll_id )
  html += @env.hidden_field_tag('page_id', @env.page.id)
  # Add javascript code
  html += @env.javascript_tag(@part_js + poll.js.to_s)
  html += '</form></div>'
  html += '</div>' if @opts[:div]

  @part_css = poll.css
  html
end

########################################################################
# Renderer dispatcher. Method returns HTML part of code.
########################################################################
def render_html
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "Error ArPoll: Method #{method} doesn't exist!"
end

########################################################################
# Return CSS part of code.
########################################################################
def render_css
  @part_css
end

end
