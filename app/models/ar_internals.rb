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
# Internals model returns some Rails environment variables like session, params, record ...
# with more user friendly names. These names can be used for interacting with
# users and hide complexity behind the scene.
#
# eg: ArInternals.get('current_user_name') will return session[:user_name]
#
# Predefined internal values are:
#  current_user
#  current_user_name
#  current_site
##########################################################################
module ArInternals
INTERNALS = {
  'current_user'      => 'session[:user_id]',
  'current_user_name' => 'session[:user_name]',
  'current_site'      => 'agile_get_site.id'
}
@additions = {}
  
##########################################################################
# Add additional internal. This method allows application specific internals 
# to be added to structure and be used together with predefined values.
##########################################################################
def self.add(hash)
  hash.each { |key, value| @additions[key] = value }
end

##########################################################################
#
##########################################################################
def self.get(key)
  key.delete_prefix!('@')
  INTERNALS[key] || @additions[key]
end

end
