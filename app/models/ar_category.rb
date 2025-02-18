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

#####################################################################
# == Schema information
#
# Table name: ar_category : Categories
#
#  id                   Integer           id
#  created_at           Time                 created_at
#  updated_at           Time                 Last update
#  name                 String               Category name
#  description          String               Additional description of category
#  ctype                Integer              Category type. Could be used for grouping categories.
#  parent               Integer       Parent category. Leave blank if this is top level category.
#  active               Boolean     Category is active.
#  order                Integer              Additional order, which can be used for sorting.
#  created_by           Integer       created_by
#  updated_by           Integer       updated_by
#   
# Categories are used on ArPage documents for grouping documents. Categorization
# is most useful for grouping news, blog entries ...
#####################################################################
class ArCategory < ApplicationRecord

validates :name, presence: true

before_destroy :can_destroy?

private

#########################################################################
# Can't delete if category document has children documents
#########################################################################
def can_destroy?
  if ArCategory.where(parent: id).count > 0
    errors.add(:base, I18n.t('agile.category_has_subs'))
    throw :abort
  end
end

#########################################################################
# Returns all values for use as parent select field.
#########################################################################
def self.values_for_parent(site_id = nil) #:nodoc:
  qry = where(active: true)
  qry = qry.and(ar_site_id: site_id.id) if site_id
  parents = {} # cache parent names to minimize database usage
  qry.inject([]) do |r, v|
    if parents[v.parent].nil?
      name   = ''
      parent = v.parent
      until parent.nil?
        doc    = find(parent)
        name   = "#{doc.name} / #{name}"
        parent = doc.parent
      end
      parents[v.parent] = name
    end
    name = v.parent ? parents[v.parent] + v.name : v.name
    r << [name, v.id]
  end.sort { |a, b| a.first <=> b.first }
end

#########################################################################
# Returns values for category type. Values should be defined in BigTable 
# on the site level all overall.
#########################################################################
# @param [Integer] site_id : Return only values for specified site
#########################################################################
def self.choices_for_ctype(site_id = nil)
  site_id = site_id.id if site_id&.class != Integer
  ArBigTable.choices_for('ar_category_type', site_id)
end

#########################################################################
# Returns choices for all categories, prepared for tree_select input field
#########################################################################
def self.choices_for_categories(site_id = nil)
  qry = where(active: true)
  ar = [nil]
  if site_id
    ar << (site_id.instance_of?(Integer) ? site_id : site_id.id)
  end
  qry = qry.in(ar_site_id: ar)
  qry.map { |category| [category.name, category.id, category.parent, category.order] }
end

end
