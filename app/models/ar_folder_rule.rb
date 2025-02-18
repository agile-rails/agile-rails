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
# Table name: ar_Folder_rules : Access policy rules for file system folders
#
#  id                   Integer              id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  ar_role_id           Object               User role access defined by this rule
#  permission           Integer              Access permission
#
# ArFolderRule records define rules for accessing folders in the file system.
#########################################################################
class ArFolderRule < ApplicationRecord

belongs_to :ar_folder_permission

validate do
  if new_record? && ArFolderRule.find_by(ar_folder_permission: ar_folder_permission, ar_role_id: ar_role_id).present?
    errors.add('ar_role_id', I18n.t('agile.already_defined'))
  end
end

end
