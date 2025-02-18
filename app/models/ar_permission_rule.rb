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
# == Schema information
#
# Table name: ar_permission_rule : Table access permisssion rules
#
#  id                   Integer              id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  ar_role_id           Object               User role access defined by this rule
#  permission           Integer              Access permission
#
# ar_permission_rules records define rules for accessing single database table.
# They define user roles and their permissions to view, create, edit or delete data.
#
#########################################################################
class ArPermissionRule < ApplicationRecord

belongs_to :ar_permission
has_many   :ar_roles

after_save :cache_clear
after_destroy :cache_clear

validate :validations

####################################################################
# Clear cache if cache is configured
####################################################################
def cache_clear
  Agile.cache_clear(:ar_permission)
end

####################################################################
# Additional validations.
####################################################################
def validations
  if new_record? && ArPermissionRule.find_by(ar_permission_id: ar_permission_id, ar_role_id: ar_role_id).present?
    errors.add('ar_role_id', I18n.t('agile.already_defined'))
  end
end

end
