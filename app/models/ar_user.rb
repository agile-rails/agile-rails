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
# Table name: ar_user : Users
#
#  id                 Integer           id
#  created_at           Time                 created_at
#  updated_at           Time                 updated_at
#  username             String               Username
#  title                String               Title (dr, mag)
#  first_name           String               Users first name
#  middle_name          String               Middle name
#  last_name            String               Users last name
#  name                 String               Name colected from firstname, title and lastname
#  company              String               company
#  address              String               Home address
#  post                 String               Post and post city
#  country              String               Country
#  phone                String               Phone number
#  email                String               e-Mail address
#  www                  String               www
#  picture              String               Picture file name
#  birthdate            Date                 Date of birth
#  about                String               Short description of user
#  last_visit           Time                 Users last visit
#  active               Boolean     Account is active
#  valid_from           Date                 Account is valid from
#  valid_to             Date                 Account is valid until
#  created_by           Integer       created_by
#  updated_by           Integer       Account last updated by
#  type                 Integer              Type of user account
#  signature            String               signature
#  interests            String               interests
#  job_occup            String               job_occup
#  description          String               description
#  reg_date             Date                 reg_date
#  password_digest      String               password_digest
#  ar_user_roles        Embedded: ArUserRole  Roles for this user
# 
# ar_users table holds data about regitered users. Passwords are encrypted
# with bcrypt gem. 
# 
# This model defines basic fields required for evidence of
# registerred users. Since it is implemented as ActiveSupport::Concern you are
# encouraged to further expand model with your own data structures.
########################################################################
class ArUser < ApplicationRecord
  include ArUserConcern
end