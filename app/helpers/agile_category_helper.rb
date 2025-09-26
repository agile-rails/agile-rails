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


####################################################################
# Helper for editing categories as tree view.
####################################################################
module AgileCategoryHelper

####################################################################
# Returns code for editing categories in a treeview
####################################################################
def categories_as_tree
  head = '<div id="catagories-as-tree"><ul><li data-id="nil"><span class="mi-o mi-home"></span>'
  data = ArCategory.where(parent: nil).order(order: :asc).to_a
  "#{head}#{html_for_category_tree(data)}</li></ul></div>#{js_for_category_tree}".html_safe
end

private

####################################################################
#
####################################################################
def html_for_category_tree(data)
  html = '<ul>'
  data.each do |category|
    icon = category.active ? 'check_box' : 'check_box_outline_blank'
    html += %(<li id="#{category.id}" data-parent="#{category.parent}"><span class="mi-o mi-#{icon} mi-18"></span>#{category.name}\n)
    children = ArCategory.where(parent: category.id).order(order: :asc).to_a

    html += html_for_category_tree(children) if children.size > 0
    html += '</li>'
  end
  "#{html}</ul>"
end

####################################################################
# Required javascript code
####################################################################
def js_for_category_tree
  %(<script>
$(function() {
  $("#catagories-as-tree").jstree( {
    core: { themes: { icons: false },
            multiple: false
          },
    plugins: ["types", "contextmenu"],
    contextmenu: {
        items: function ($node) {
            return {
                edit: {
                    label: "<span class='ar-result-submenu'>#{t('agile.edit')}</span>",
                    icon: "mi-o mi-edit",
                    action: function (obj) {
                        let id = $('#catagories-as-tree').jstree('get_selected', true)[0].id;
                        let params = "&ids=" + id;
                        location.href = "/agile/" + id + "/edit?t=ar_category&f=ar_category_as_tree" + params;
                    }
                },

                new_child: {
                    label: "<span class='ar-result-submenu'>#{t('agile.new')}</span>",
                    icon: "mi-o mi-plus",
                    action: function (obj) {
                        let id = $('#catagories-as-tree').jstree('get_selected', true)[0].id;
                        let params = "&ids=" + id + "&p_parent=" + id;
                        location.href = "/agile/new?t=ar_category&f=ar_category_as_tree" + params
                    }
                },

                delete: {
                    label: "<span class='ar-result-submenu'>#{t('agile.delete')}</span>",
                    icon: "mi-o mi-delete",
                    action: function (obj) {
                        if (confirmation_is_cancelled("#{t('agile.confirm_delete')}") === true) return false;

                        let id = $('#catagories-as-tree').jstree('get_selected', true)[0].id;
                        let id_return = $('#catagories-as-tree').jstree('get_selected', true)[0].data["parent"];

                        $.ajax({
                            url: "/agile/" + id + "?t=ar_category",
                            type: 'DELETE',
                            success: function(data) {
                              let error = data.match("#{I18n.t('agile.category_has_subs')}");
                              if (error !== null) {
                                alert(error[0]);
                                params = "?t=ar_category&f=ar_category_as_tree&ids=" + id;
                                location.href = "/agile" + params;
                                return true;
                              }
                            }
                        });

                        let params = "?t=ar_category&f=ar_category_as_tree&ids=" + id_return;
                        location.href = "/agile" + params;
                    }
                },
            }
          },
       },
    });
    $("#catagories-as-tree").jstree(true).select_node("#{params[:ids]}");
});

</script>)
end

end
