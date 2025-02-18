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
# Table name: ar_permission : Table permissions
#
#  id                 Integer           id
#  created_at           Time          created_at
#  updated_at           Time          updated_at
#  table_name           String        Permission is valid for table
#  is_default           Boolean       This is default permission for all tables in database
#  active               Boolean       Permission is active
#  ar_policy_rules      Embedded:     ArPolicyRule Defined policy rules
# 
# ar_permissions table define permissions for accessing single table when in edit mode.
# They define table and user role that can view, edit or delete documents in a table.
# Document marked as default is the top level document and defines general permissions valid for
# all tables. It usually states that admiin can delete all documents and guest has no access.
#
# Rules can also be namespaced. If you have an isolated application which is using its own set
# of tables, you can start table names with same (3 letter) prefix and add a permission rule like ar_*.
#########################################################################
class ArPermission < ApplicationRecord
#- Available permissions settings

# User has no access 
NO_ACCESS = 0
# User can view documents
CAN_VIEW  = 1
# User can create new documents  
CAN_CREATE = 2
# User can edit his own documents
CAN_EDIT = 4
# User can edit all documents in table
CAN_EDIT_ALL = 8
# User can delete his own documents
CAN_DELETE = 16
# User can delete all documents in table
CAN_DELETE_ALL = 32
# User can admin table (same as can_delete_all, but can see documents which do not belong to current site)
CAN_ADMIN = 64
# User is superadmin. Basicly same as admin.
SUPERADMIN = 128

has_many :ar_permission_rules

validates :table_name, presence: true
validates :table_name, uniqueness: true

after_save :cache_clear
after_destroy :cache_clear

####################################################################
# Clear cache if cache is configured
####################################################################
def cache_clear
  Agile.cache_clear(:ar_permission)
end

########################################################################
# Will return choices for permissions prepared for usega in select input field.
# This will return english only comments so it is not used.
########################################################################
def self.table_permissions #:nodoc:
  [['NO_ACCESS', 0],  ['CAN_VIEW', 1], ['CAN_CREATE', 2], ['CAN_EDIT', 4], ['CAN_EDIT_ALL', 8],
   ['CAN_DELETE', 16], ['CAN_DELETE_ALL', 32], ['CAN_ADMIN', 64], ['SUPERADMIN', 128]]
end

########################################################################
# Will return choices for permissions prepared for usega in select input field.
# This will return english only comments so it is not used.
########################################################################
def self.site_permissions #:nodoc:
  [['NO_ACCESS', 0], ['CAN_VIEW', 1], ['CAN_EDIT', 2]]
end

#############################################################################
# Will return permissions for table
############################################################################
def self.permissions_for_table(table_name)
  result = permissions_for('*')
  result = permissions_for("#{table_name[0,3]}*", result)
  permissions_for(table_name, result)
end

#############################################################################
# 
############################################################################
def self.permissions_for(table_name, result = {}) #:nodoc:
  permissions = if table_name == '*'
                  find_by(is_default: true)
                else
                  find_by(table_name: table_name, active: true)
                end
  if permissions
    permissions.ar_permission_rules.each { |rule| result[rule.ar_role_id] = rule.permission }
  end
  result
end

#########################################################################
# Returns values for permissions ready to be used in select field.
#
# Example (as used in AgileRails form):
#    20:
#      name: permission
#      type: select
#      eval: ArPermission.values_for_permissions
#########################################################################
def self.choices_for_permissions
  values_for_permissions_for_key 'helpers.label.ar_policy_rule.choices_for_permission'
end

#########################################################################
# Returns values for site_permissions ready to be used in select field.
#
# Example (as used in AgileRails form):
#    20:
#      name: permission
#      type: select
#      eval: ArPermission.values_for_site_permissions
#########################################################################
def self.choices_for_site_permissions
  values_for_permissions_for_key 'helpers.label.ar_policy_rule.choices_for_sites_permission'
end

#########################################################################
def self.values_for_permissions_for_key(key)
  c = I18n.t(key)
  c = I18n.t(key, locale: 'en') if c.class == Hash || c.match(/translation missing/i)
  c.split(',').map { |e| (ar = e.split(':'); [ar.first, ar.last.to_i]) }
end

#########################################################################
# Will return translated permission name for value.
#
# Parameters:
# [value] Integer. Permission value
#
# Example (as used in AgileRails form):
#    data_set:
#      columns:
#        2:
#          name: permission
#          eval: ArPermission.permission_name_for_value
#
# Returns:
# String. Name (description) for value
#########################################################################
def self.permission_name_for_value(value)
  choices_for_permissions.reduce('error') { |r, v| break v.first if v.last.to_i == value.to_i }
end

def self.site_permission_name_for_value(value)
  choices_for_site_permissions.reduce('error') { |r, v| break v.first if v.last.to_i == value.to_i }
end

end
