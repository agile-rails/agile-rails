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
# ActiveSupport::Concern definition for ArPage class. 
#########################################################################
module ArPageConcern
extend ActiveSupport::Concern
included do

# SEO
#include ArSeoConcern

belongs_to  :ar_site,   optional: true
belongs_to  :ar_design, optional: true

before_save :do_before_save

validates :publish_date, presence: true
validate  :validate_images_alt_present

after_save :cache_clear
after_destroy :cache_clear

scope :ar_parts,  -> { ArParts.where("parent_type = 'ArPage'") }

####################################################################
# Clear cache if cache is configured
####################################################################
def cache_clear
  Agile.cache_clear(:ar_page)
end
   
######################################################################
# Will return validation error if all images in body field do not have 
# alt attribute present.
######################################################################
def validate_images_alt_present
  errors.add('body', I18n.t('agile.img_alt_not_present')) unless ArPage.images_alt_present?(body)
end

protected

######################################################################
# Implementation of before_save callback.
######################################################################
def do_before_save
  self.link = ArPage.clear_link(subject.downcase.strip) if link.blank?
  # menu_id is returned as string Array class if entered on form as tree_select object.
  self.menu_id = menu_id.scan(/"([^"]*)"/)[0][0] if menu_id.to_s.match('"')
end

######################################################################
# Clears subject link of chars that shouldn't be there and also takes care 
# than link size is not larger than 100 chars.
######################################################################
def self.clear_link(link)
  link.gsub!(/\.|\?|\!\&|\||»|«|\,|\"|\'|\:/, '')
  link.gsub!('<br>','')
  link.gsub!('–','-')
  link.gsub!(' ','-')
  link.gsub!('---', '-')
  link.gsub!('--', '-')
  # it shall not be greater than 100 chars. Don't break in the middle of words
  if link.size > 100
    link = link[0, 100]
    link.chop! until link[-1, 1] == '-' || link.size < 10 # delete until -
  end
  link.chop! if link[-1, 1] == '-' # remove - at the end
  link
end

######################################################################
# Return all pages belonging to site ready for select input field. Used
# by  ar_menu* forms, for selecting page which will be linked by menu option.
# 
# Parameters:
# [site] Site document.
######################################################################
def self.all_pages_for_site(site)
  only(:subject, :link).where(ar_site_id: site.id, active: true).order(subject: 1)
                       .map { [ _1.subject, _1.link] }
end

########################################################################
# Return filter options
########################################################################
def self.agile_filters
  { title: I18n.t('agile.filters.this_site_only'), operation: 'eq', field: 'ar_site_id', value: '@current_site' }
end

######################################################################
# Clears subject link of chars that shouldn't be there and also takes care 
# than link size is not larger than 100 chars.
######################################################################
def self.images_alt_present?(text)
  return true if text.blank?

  document = Nokogiri::HTML.parse(text)
  document.xpath('//img').each do |image|
    return false if !image.attributes['alt'] || image.attributes['alt'].text.blank?
  end
  true
end

end

end
