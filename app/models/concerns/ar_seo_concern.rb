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

##########################################################################
#  ar_seo_concern, ads SEO optimization fields to any model.
#
# title                String               Browser title. Optimization for SEO.
# meta_description     String               SEO optimised page description
# meta_additional      String               Additional meta page data. Enter as meta_name=meta data
#  ar_json_lds          Embedded: ArJsonLd    Page structure data
# 
# If you want to add SEO optimization data to your document add:
# 
# "include ArSeoConcern" to your model definition
# 
# and
# 
# "include:  ar_seo" option to top of AgileRails edit form for your document.
##########################################################################
module ArSeoConcern
extend ActiveSupport::Concern

included do  
  field :title,            type: String
  field :meta_description, type: String
  field :canonical_link,   type: String
  embeds_many :ar_json_lds # JSON-LD structure
  
  ######################################################################
  # Will return JSON LD data if defined for the page
  ######################################################################
  def get_json_ld()
    parent_data = {'datePublished' => self.created_at, 'dateModified' => self.updated_at}
    data = []
    if  ar_json_lds.size > 0
       ar_json_lds.where(active: true).each do |element|
        dta = element.get_json_ld(parent_data)
        data << dta if dta.size > 0
      end
    end
    data  
  end
end


end
