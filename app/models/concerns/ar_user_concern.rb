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
# ActiveSupport::Concern definition for ArUser class. 
#########################################################################
module ArUserConcern
extend ActiveSupport::Concern
#include ActiveModel::Validations
included do
@@countries = nil

include ActiveModel::SecurePassword

has_many :ar_user_roles
has_many :ar_roles, through: :ar_user_roles

has_secure_password

validates_length_of :username, minimum: 4
validates           :username, uniqueness: true
validates           :email,    uniqueness: true
validate :do_validate

before_save :do_before_save
before_validation :do_before_validation

attr_reader :cached_roles

##########################################################################
# Checks if user has role 'role_id' defined in his roles.
# 
# Role may be passed as id or as String like role name.
##########################################################################
def has_role?(role_id)
  return false if role_id.nil?

  if role_id.class == String
    role    = ArRole.get_role(role_id)
    role_id = role.id if role
  end
  roles().include?(role_id)
end

##########################################################################
# Returns all active roles for user
#
# @return [Array] : Array of user roles ids
##########################################################################
def roles
  return @cached_roles if @cached_roles

  user_and_groups = [id] + ArUserGroup.where(ar_user_id: id).map(&:group_id)
  @cached_roles = ArUserRole.where(ar_user_id: user_and_groups, active: true).select(&:active?).map(&:ar_role_id).uniq
end

##########################################################################
# Helper for updating group membership
##########################################################################
def member_a=(value)
  return if id.nil?

  old = member_a
  new = (value.is_a?(String) ? [value] : value).map(&:to_i)
  remove = old - new
  create = new - old
  ArUserGroup.where(ar_user_id: id, :group_id => remove).delete_all if remove.present?
  create.each { |e| ArUserGroup.create(ar_user_id: id, group_id: e) }
end

##########################################################################
# Helper for updating group membership
##########################################################################
def member_a
  ArUserGroup.where(ar_user_id: id).map(&:group_id)
end

##########################################################################
# Will return all possible values for country field ready for input in select field. 
# Values are loaded from github when method is first called.
##########################################################################
def self.choices_for_country
  countries.map(&:reverse)
end

##########################################################################
# Will return @@countries class variable
##########################################################################
def self.countries
  return @@countries if @@countries

  uri  = URI.parse("https://raw.githubusercontent.com/umpirsky/country-list/master/data/en/country.json")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request  = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  @@countries = JSON.parse(response.body)
end

##########################################################################
# Performs logically test on passed email parameter.
# 
# Parameters:
# [email] String: e-mail address
# 
# Returns:
# Boolean: True if parameter is logically valid email address.
# 
# Example:
#    if ! ArUser.is_email?(params[:email])
#      flash[:error] = 'e-Mail address is not valid!'
#    end
# 
##########################################################################
def self.is_email?(email)
  email.to_s =~ /^[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
end

##########################################################################
# Will return list of available groups
##########################################################################
def self.groups_for_select
  where(group: true, active: true).order(name: :asc).map { [_1.name, _1.id] }
end

##########################################################################
# Will return list of available users without groups
##########################################################################
def self.users_for_select
  where(group: false, active: true).order(name: :asc).map { [_1.name, _1.id] }
end

private

##########################################################################
# before_save callback takes care of name field and ensures that e-mail is unique
# when entry is left empty.
##########################################################################
def do_before_save
  self.name  = "#{title} #{first_name} #{middle_name if middle_name.present?} #{last_name}".squish
  # to ensure unique e-mail
  self.email = "unknown@#{id}" if email.blank?
end

##########################################################################
# Create random password for groups. Must be done before validation
##########################################################################
def do_before_validation
  if new_record? && group
    self.password = ArUser.random_password(30)
    self.password_confirmation = password
  end
end

##########################################################################
# Perform some additional validations
##########################################################################
def do_validate
  if group && ArUserGroup.where(ar_user_id: id).present?
    errors.add('member', I18n.t('errors.messages.present'))
  end
end

##########################################################################
# Will create random password
##########################################################################
def self.random_password(number)
  charset = Array('A'..'Z') + Array('0'..'9') + Array('a'..'z')
  Array.new(number) { charset.sample }.join
end

end

end
