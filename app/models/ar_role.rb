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
# Table name: ar_role : User roles
#
#  id                 Integer           id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  name                 String               Role name
#  system_name          String               System role name if required by application
#  active               Boolean              Role is active
# 
# Documents in this model define all available user roles in the application. Roles 
# are defined by unique name which is valid for current application or as alternative name (system_name) 
# which can be persistent, when application is used as Rails plugin.
#########################################################################
class ArRole < ApplicationRecord

validates :name, :length => { :minimum => 4 }
validates :name, uniqueness: true

after_save :cache_clear
after_destroy :cache_clear

####################################################################
# Clear cache if cache is configured
####################################################################
def cache_clear
  Agile.cache_clear(:ar_permission)
  Agile.cache_clear(:ar_site)
  Agile.cache_clear(:ar_role)
end

########################################################################
# Return all defined roles as choices for use in select field.
########################################################################
def self.choices_for_roles
  where(active: true).order(name: :asc).map { |role| [ role.name, role.id] }
end

########################################################################
# Search for role when role parameter is String.
########################################################################
def self.get_role(name)
  record = Agile.cache_read(['ar_role', name])
  return record if record

  record = find_by(name: name) || find_by(system_name: name)
  Agile.cache_write(['ar_policy_role', name], record)
end

########################################################################
# Search for role when role parameter is String.
########################################################################
def self.get_role(name)
  Agile.cache_read(['ar_role', name]) do
    record = find_by(name: name) || find_by(system_name: name)
  end
end

end
