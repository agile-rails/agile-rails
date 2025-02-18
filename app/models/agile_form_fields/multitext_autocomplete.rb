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
# Implementation of multitext_autocomplete AgileRails Form field.
# 
# multitext_autocomplete field is complex data entry field which uses autocomplete
# function when selecting multiple values for MongoDB Array field. Array typically holds
#  id's of selected documents and control typically displays value of the field name 
# defined by search options.
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ multitext_autocomplete (required)
# * +table+ Model (table) name which must contain searched field name.
# * +search:+ Search may consist of three parameters from which are separated either by dot (.) or comma(,)
#   * search_field_name; when table option is defined search must define field name which will be used for search query
#   * collection_name.search_field_name; Same as above except that table options must be ommited.
#   * collection_name.search_field_name.method_name; When searching is more complex custom search
#   method may be defined in CollectionName model which will provide dataset for search.
# * +with_new+ Will add an icon for shortcut to add new document to collection
#      
# Form example:
#      90:
#        name: kats
#        type: multitext_autocomplete
#        search: ar_category.name
#        with_new: model_name
#        size: 30
###########################################################################
class MultitextAutocomplete < AgileFormField

###########################################################################
# Returns value for readonly field
###########################################################################
def ro_standard(table, search)
  current_values = @record.send(@yaml['name'])
  return self if current_values.blank?

  table  = table.classify.constantize
  search = search.split(/\.|\,/).first if search.match(/\.|\,/)
  html   = current_values.map { |element| table.find(element)[search] + '<br>' }.join
  super(html)
end

###########################################################################
# Render multitext_autocomplete AgileRails form field code
###########################################################################
def render
  # get field name
  if @yaml['search'].class.to_s == 'Hash'
    #if @yaml['search'].kind_of?(Hash)
    table      = @yaml['search']['table']
    field_name = @yaml['search']['field']
    method     = @yaml['search']['method']
    search     = method.nil? ? field_name : "#{field_name}.#{method}"
  elsif @yaml['search'].to_s.match(/[.,]/)
    table, field_name, method = @yaml['search'].split(/[.,]/).map(&:strip)
    search = method.nil? ? field_name : "#{field_name}.#{method}"
  else # search and table name are separated
    search = field_name = @yaml['search']
  end
  # get table name
  if @yaml['table']
    table = if @yaml['table'].class == String
              @yaml['table']
              # eval(how_to_get_my_table_name)
            elsif @yaml['table']['eval']
              eval @yaml['table']['eval']
            else
              Rails.logger.error "Field #{@yaml['name']}: Invalid table parameter!"
              nil
            end
  end

  if table.blank? || search.blank?
    @html += 'Table or search field not defined!'
    return self
  end

  # does collection exists
  collection = table.classify.constantize rescue nil
  if collection.nil?
    @html += "Invalid table name: #{table}"
    return self
  end

  # does field exists
  unless @record.respond_to?(@yaml['name'])
    @html += "Invalid field name: #{@yaml['name']}"
    return self
  end

  # search data entry
  @yaml['html'] ||= {}
  @yaml['html']['value'] = ''   # must be. Otherwise it will look into record and return error
  @yaml['html']['placeholder'] = t('agile.search_placeholder')
  _name = '_' + @yaml['name']
  @html += '<div class="ui-autocomplete-border">'
  @html += @env.link_to(@env.mi_icon('plus-square-o green'), '#', onclick: 'return false;') # dummy add. But it is useful.

  # text_field for autocomplete
  record = record_text_for(@yaml['name'])
  @html += '<span class="ar-text-autocomplete">' + @env.text_field(record, _name, @yaml['html']) + '<span></span></span>'

  # link for adding new documents to searched collection
  if @yaml['with_new'] && !@readonly
    @html += ' ' +
      @env.mi_icon('plus-square-o', class: 'in-edit-add', title: t('agile.new'),
                    style: "vertical-align: top;", 'data-table' => @yaml['with_new'] )
  end

  # div to list active selections
  @html += %(<div id ="#{record}#{@yaml['name']}">)
  # fill with current values
  current_values = @record.send(@yaml['name'])
  unless current_values.nil?
    current_values.each do |element|
      # this is quick and dirty trick. We have model ar_big_table which can be used for retrive
      # more complicated options
      # TODO retrieve choices from big_table
      rec = if table == 'ar_big_table'
              collection.find(@yaml['name'], @env.session)
            else
              collection.find(element)
            end

      @html += if rec
                 link  = @env.link_to(@env.mi_icon('remove_circle red'), '#',
                                      onclick: %($('##{rec.id}').hide(); let v = $('##{record}_#{@yaml['name']}_#{rec.id}'); v.val("-" + v.val());return false;))
                 link  = @env.mi_icon('check green') if @readonly
                 field = @env.hidden_field(record, "#{@yaml['name']}_#{rec.id}", value: element)
                 %(<div id="#{rec.id}" style="padding:4px;">#{link} #{rec.send(field_name)}<br>#{field}</div>)
               else
                 '** error **'  # Related data is missing. It happends.
               end
    end
  end
  @html += "</div></div>"

  # Create text for new div when new category is added
  link    = @env.link_to(@env.mi_icon('remove_circle red'), '#',
            onclick: %($('#rec_id').hide(); let v = $('##{record}_#{@yaml['name']}_rec_id'); v.val("-" + v.val());return false;"))
  field   = @env.hidden_field(record, "#{@yaml['name']}_rec_id", value: 'rec_id')
  one_div = %(<div id="rec_id" style="padding:4px;">#{link} rec_search<br>#{field}</div>)

# JS stuff    
  @js += <<EOJS
$(document).ready(function() {
  $("##{record}_#{_name}").autocomplete( {
    source: function(request, response) {
      $.ajax({
        url: "#{ @env.url_for( controller: 'agile_common', action: 'autocomplete' )}",
        type: "POST",
        dataType: "json",
        data: { input: request.term, table: "#{table}", search: "#{search}" #{(',id: "' + @yaml['id'] + '"') if @yaml['id']} },
        success: function(data) {
          response( $.map( data, function(key) {
            return key;
          }));
        }
      });
    },
    change: function (event, ui) { 
      let div = '#{one_div}';
      div = div.replace(/rec_id/g, ui.item.id)
      div = div.replace('rec_search', ui.item.value)
      $("##{record}#{@yaml['name']}").append(div);
      $("##{record}_#{_name}").val('');
      $("##{record}_#{_name}").focus();
    },
    minLength: 2
  });
});
EOJS

  self 
end

###########################################################################
# Class method for retrieving data from multitext_autocomplete form field.
###########################################################################
def self.get_data(params, name)
  r = []
  params['record'].each do |k, v|
    # if it starts with - then it was removed
    r << v if k.match("#{name}_") && v[0] != '-'
    r
  end
  r.uniq
end

end
end