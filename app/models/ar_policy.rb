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
# Table name: ar_policy : Access policy declarations
#
#  id                 Integer           id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  name                 String               Unique policy name
#  description          String               Description for this policy
#  is_default           Boolean     This is default policy for the site
#  active               Boolean     Policy is active
#  updated_by           Integer       updated_by
#  message              String               Error message when blocked by this policy
#  rules                String               Policy rules
# 
# ArPolicy documents define policies for accessing data on web site. Policies define which
# user roles (defined in ar_policy_roles table) has no access, can view or edit data (sees CMS menu) on
# current active web page. Policies can then be applied to individual documents or parts of the site.
# 
# Document defined as default, holds top level policy which is inherited by all
# other policies. Default policy is also used when document has no access policy assigned.
#########################################################################
class ArPolicy < ApplicationRecord
belongs_to :ar_site
has_many   :ar_policy_rules

validates :name, length: { minimum: 4 }
validates :message, length: { minimum: 5 }

after_save :cache_clear
after_destroy :cache_clear

validate :is_the_only_default_policy

####################################################################
# Clear cache if cache is configured
####################################################################
def cache_clear
  Agile.cache_clear(:ar_permission)
  Agile.cache_clear(:ar_site)
end

####################################################################
# There should be only one default policy.
####################################################################
def is_the_only_default_policy
  existing_policy_id = ArPolicy.find_by(ar_site_id: ar_site_id, is_default: true)&.id

  if is_default && existing_policy_id && existing_policy_id != id
    errors.add('is_default', I18n.t('agile.already_defined'))
  end
end

end
