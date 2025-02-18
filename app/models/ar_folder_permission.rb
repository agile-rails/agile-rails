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
# Table name: ar_folder_permissions : Folder permissions
#
#  id                 Integer         id
#  created_at           Time        created_at
#  updated_at           Time        updated_at
#  name                 String      Folder name
#  inherited            Boolean     Inherit permissions from parent
#  active               Boolean     Permission is valid
#  ar_policy_rules      Embedded:   ArPolicyRule Policy rules
# 
# Similar to ArPermission ArDirPermission model defines documents
# for accessing file system. Permissions defined on a parent folder automatically
# apply to all folders below unless folder on lower level has its own permission document.
# 
# At least one document must exist for file manager to work.
#########################################################################
class ArFolderPermission < ApplicationRecord

has_many :ar_folder_rules

validates :folder_name, presence: true
validates :folder_name, uniqueness: true

end
