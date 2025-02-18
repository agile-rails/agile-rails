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
# Table name: ar_journal : Update journal
#
#  id                 Integer           id
#  user_id              Integer       User
#  site_id              Integer       Site
#  doc_id               Integer       doc_id
#  operation            String               Operation
#  tables               String               Table name
#  ids                  String               Parent ids
#  ip                   String               ip address from where operation was performed
#  time                 DateTime             Time of operation
#  diff                 String               Differences
# 
# ar_journals collections saves all data that has been updated through agile controller.
# It saves old and new values of changed fields and can be used for
# instant restore of single document field or tracking who and when updated 
# particular document.
#########################################################################
class ArJournal < ApplicationRecord
end
