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

#########################################################################
# ActiveSupport::Concern definition for ArSite class. 
#########################################################################
module ArSiteConcern
extend ActiveSupport::Concern
include ActiveModel::Validations

included do

has_many :ar_policies
validates :name, presence: true

after_save :cache_clear
after_destroy :cache_clear

####################################################################
# Clear cache if cache is configured
####################################################################
def cache_clear
  Agile.cache_clear(:ar_site)
end

########################################################################
# Returns value of site setting. If no value is send as parameter it returns 
# all settings hash object.
########################################################################
def params(what = nil)
  @params ||= self.settings.to_s.size > 5 ? YAML.load(self.settings) : {}
  what.nil? ? @params : @params[what.to_s]
end
alias :options :params

########################################################################
# Returns class object of page table
########################################################################
def page_klass
  page_class.classify.constantize
end

########################################################################
# Returns class object of site's menu table name
########################################################################
def menu_klass
  (menu_class.blank? ? 'ArMenu' : menu_class).classify.constantize
end

########################################################################
# Returns this site policies
########################################################################
def site_policies
  ArPolicy.where(ar_site_id: id, active: true).order(name: :asc)
end

########################################################################
# Return default site policy rules
########################################################################
def default_policy
  ArPolicyRule.where('ar_policy.ar_site_id' => id, 'ar_policy.is_default' => true).joins(:ar_policy)
end

########################################################################
# Return choices for select for site_id
########################################################################
def self.choices_for_sites
  all.map { |site| [(site.active ? '' : I18n.t('agile.disabled') ) + site.name, site.id] }
     .sort { |a, b| a[0] <=> b[0] }
end

########################################################################
# Return choices for selecting policies for the site
########################################################################
def self.choices_for_menu(menu_class)
  return [] if menu_class.blank?

  menu = menu_class.classify.constantize
  menu.where(active: true).map { [_1.description, _1.id] }
end

end  
end
