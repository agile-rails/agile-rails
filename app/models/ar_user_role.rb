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
# Table name: ar_user_role : User roles
#
#  id                 Integer           id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  ar_role_id    Object               User role
#  valid_from           Date                 Role is valid from
#  valid_to             Date                 Role is valid to
#  active               Boolean     Role is active
#  created_by           Integer       created_by
#  updated_by           Integer       Role last updated 
# 
# ArUserRole documents are embedded in ArUser model and define user roles which
# belong to user.
########################################################################
class ArUserRole < ApplicationRecord
belongs_to :ar_user
belongs_to :ar_role

###############################################################################
# Determine of role is still active
###############################################################################
def active?
  now = Time.current
  active && (valid_from.nil? || now > valid_from) && (valid_to.nil? || now < valid_to)
end

end