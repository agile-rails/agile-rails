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
#++

##########################################################################
# == Schema information
#
# Collection name: ar_images : Images
#
#  _id                  BSON::ObjectId     _id
#  created_at           Time               created_at
#  updated_at           Time               updated_at
#  ar_site_id           BSON::ObjectId     Site id
#  ar_user_id           BSON::ObjectId     User's id
#  name                 String             ip
#  short                String             short name
#  text                 String             text
#  size_o               String             Original image size
#  size_l               String             Large image size
#  size_m               String             Medium image size
#  size_s               String             Small image size
#
# AgileRails module for saving and manipulating images. Images can be saved to local
# directory only. Settings for output images must be set in settings in site record.
# Example:
#   ar_image:
#     sizes: 900x600,500x400,300x200
#     location: images
#     quality: '80'
#     img_type: webp
#
# To use this module imagemagick tools and mini_magick ruby gem must be installed.
##########################################################################
class ArImage < ApplicationRecord

before_validation :set_original
validate :validate_image_values

#########################################################################
# checks that image size values are in correct format. Must be hsize[x]vsize (ex. 300x200)
#########################################################################
def set_original
  if keep_original
    if size_o.blank?
      image = MiniMagick::Image.open(name)
      self.size_o = "#{image.width}x#{image.height}"
    end
  else
    self.size_o = ''
  end
end

#########################################################################
# checks that image size values are in correct format. Must be hsize[x]vsize (ex. 300x200)
#########################################################################
def validate_image_values
  %w[l m s o].each do |size|
    field = "size_#{size}"
    value = send(field)
    next if value.blank?

    a = value.strip.split(/x|\+/)
    a[0, 2].each { |e| errors.add(field, I18n.t('agile.not_valid')) unless e.to_i > 0 }
  end
end

#########################################################################
# Will return first available image starting from small up
#########################################################################
def first_available_image
  image = %w[o s m l].each do |size|
    field = "size_#{size}"
    value = send(field)
    return "#{id}-#{size}.#{img_type}" if value.present?
  end
end

#########################################################################
# Will return size for large image
#########################################################################
def size_ls
  size_l.blank? ? '' : size_l.split(/x|\+/)[0, 2].join('x')
end

#########################################################################
# Will set new size for large image
#########################################################################
def size_ls=(value)
  self.size_l = value.blank? ? '' : value
end

#########################################################################
# Will return x offset for cropping large image
#########################################################################
def offset_lx
  size_l.blank? ? '' : size_l.split(/x|\+/)[2].to_i
end

#########################################################################
# Will set x offset for cropping large image
#########################################################################
def offset_lx=(value)
  self.size_l += (size_l.blank? ? '' : "+#{value}")
end

#########################################################################
# Will return y offset for cropping large image
#########################################################################
def offset_ly
  size_l.blank? ? '' : size_l.split(/x|\+/)[3].to_i
end

#########################################################################
# Will set y offset for cropping large image
#########################################################################
def offset_ly=(value)
  self.size_l += (size_l.blank? ? '' : "+#{value}")
end

def size_ms
  size_m.blank? ? '' : size_m.split(/x|\+/)[0, 2].join('x')
end

def size_ms=(value)
  self.size_m = value.blank? ? '' : value
end

def offset_mx
  size_m.blank? ? '' : size_m.split(/x|\+/)[2].to_i
end

def offset_mx=(value)
  self.size_m += (size_m.blank? ? '' : "+#{value}")
end

def offset_my
  size_m.blank? ? '' : size_m.split(/x|\+/)[3].to_i
end

def offset_my=(value)
  self.size_m += (size_m.blank? ? '' : "+#{value}")
end

def size_ss
  size_s.blank? ? '' : size_s.split(/x|\+/)[0, 2].join('x')
end

def size_ss=(value)
  self.size_s = value.blank? ? '' : value
end

def offset_sx
  size_s.blank? ? '' : size_s.split(/x|\+/)[2].to_i
end

def offset_sx=(value)
  self.size_s += (size_s.blank? ? '' : "+#{value}")
end

def offset_sy
  size_s.blank? ? '' : size_s.split(/x|\+/)[3].to_i
end

def offset_sy=(value)
  self.size_s += (size_s.blank? ? '' : "+#{value}")
end

#########################################################################
# Return all users that have contributed images
#########################################################################
def self.all_users
  ArUser.where(:id.in => distinct(:created_by)).order(name: 'asc').map { [_1.name, _1.id] }
end

def self.html_code
  'code'
end

end
