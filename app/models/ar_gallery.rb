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
# ArGallery model holds data for picture galleries for various types of documents.
# Picture Gallery can be added to any document, provided that it has two parameters:
# doc_id and doc_type.
#########################################################################
# == Schema information
#
# Table name: ar_gallery : Pictures gallery
#
#  id                   Integer       id
#  doc_id               Integer       Parent document id where this gallery lies
#  doc_type             String        Parent document table name
#  title                String        Title name for picture
#  description          String        Short description
#  picture              String        Picture filename
#  thumbnail            String        Picture thumbnail
#  order                Integer       Order of picture in a gallery
#
#  active               Boolean       Picture is active
#  created_by           Integer       created_by
#  updated_by           Integer       updated_by
#  created_at           Time          created_at
#  updated_at           Time          updated_at
# 
#########################################################################
class ArGallery < ApplicationRecord
  validates :picture,  presence: true
  validates :doc_id,   presence: true
  validates :doc_type, presence: true
end