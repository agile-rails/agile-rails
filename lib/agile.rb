require 'agile/engine'
require 'agile/version'
require 'agile/configuration'

################################################################################
# AgileRails plugin module
################################################################################
module Agile
@@paths = {}
@@configuration = nil

################################################################################
# Returns source file name of required model. 
#
# Used wherever end user wants to extend basic Agile model. Model source definition 
# file is tricky to require since it is included in Agile gem and thus a moving 
# target. Whenever gem version changes file location changes with it. This way 
# programmer doesn't have to care about actual source file location.
#
# Parameters:
# [ model_name ] String. Must be passed in lower case, just like the file name is. 
#
# Example: 
#    require Agile.model 'ar_page'
#
###############################################################################
def self.model(model_name)
  File.expand_path("../../app/models/#{model_name}.rb", __FILE__)  
end

###############################################################################
# If new_value is nil method will return current value of application configuration. Otherwise
# it will set new value to the configurations.
#
# @param [Object] what : Config name
# @param [Object] new_value : new config value. Default = nil.
###############################################################################
def self.config(what, new_value = nil)
  @@configuration ||= Agile::Configuration.defaults
  if new_value
    @@configuration[what.to_sym] = new_value
  else
    @@configuration[what.to_sym]
  end
end

###############################################################################
# When new plugin with its own AgileRails forms is added to application, path to
# forms directory must be sent to Agile module. Paths are saved into @@paths hash variable.
#
# Adding path is best done in plugin module initialization code.
#
# Parameters:
# [path] String. Path to forms directory
#
# Example:
#    # As used in MyPlugin plugin.
#    require "my_plugin/engine"
#    module MyPlugin
#    end
#
#    Agile.add_forms_path File.expand_path("../../app/forms", __FILE__)
###############################################################################
def self.add_forms_path(path) 
  if @@paths[:forms].nil?
    @@paths[:forms] = []
    # Agile forms path
    @@paths[:forms] << File.expand_path('../../app/forms', __FILE__)
  end
  @@paths[:forms] << path  
end

###############################################################################
# Not used anymore!
#
# Patching is one of the rubies best strenghts and also its curse. Loading
# patches in development has become real problem for developers. This is my
# way of patch loading.
#
# Preferred location for patch files is lib/patches. But can be located anywhere in 
# Rails application path. Add Agile.add_forms_path to initialization part and pass 
# directory name where patching files are located as parameter.
#
# Method will also load patch file so loading in config/initializers is not required.
#
# Parameters:
# [path] String. Path to patches directory
#
# Example:
#    # As used in MyPlugin plugin.
#    require "my_plugin/engine"
#    module MyPlugin
#    end
#
#    Agile.add_patches_path File.dirname(__FILE__) + '/patches'
###############################################################################
def self.add_patches_path(path)
  self.add_path(:patches, path)
#  Dir["#{path}/**/*.rb"].each { |path| p path; require_dependency path }
#  Dir["#{path}/**/*.rb"].each { |file| p file; require file }
end

###############################################################################
# General add path method. Paths are saved into @@paths hash variable. Paths can
# then be reused in different parts of application.
# 
# Adding paths is best done in plugin mudule initialization code.
# 
# Parameters:
# [type] Symbol. Defines type of data. Current used values are :forms, :patches
# [path] String. Path or string which will be added to @@paths hash.
# 
# Example:
#    Agile.add_path(File.expand_path('patches', __FILE__), :patches)
###############################################################################
def self.add_path(type, path) 
  @@paths[type] ||= []
  @@paths[type] << path  
end

###############################################################################
# Will return value saved to internal @@paths hash.
#
# Parameters:
# [key] String. Key
#
# forms_paths   = Agile.paths(:forms)
# patches_paths = Agile.paths(:patches)
###############################################################################
def self.paths(key)
  @@paths[key]
end

###############################################################################
# Will return name of file relative to agile_rails gem root
###############################################################################
def self.from_root(file = nil)
  File.expand_path("../../#{file}", __FILE__).to_s
end

####################################################################
# Checks if any errors exist on document and writes error log. It can also
# crash if requested. This is mostly usefull in development for debuging
# model errors or when updating multiple collections and each save must be
# checked if succesfull.
#
# @param [Document] Document object which will be checked
# @param [Boolean] If true method should end in runtime error. Default = false.
#
# @return [String] Error messages or empty string if everything is OK.
#
# @Example Check for error when data is saved.
#   model.save
#   if (msg = Agile.model_check(model) ).size > 0
#     p msg
#     error process ......
#   end
#
####################################################################
def self.model_check(document, crash = false)
  return unless document.errors.any?

  msg = document.errors.inject('') { |r, error| r << "#{error.attribute}: #{error.message}\n" }
  if crash && msg.size > 0
    msg = "Validation errors in #{document.class}:\n" + msg
    pp msg
    Rails.logger.error(msg)
    raise 'Validation error. See log for more information.'
  end
  msg
end

########################################################################
# Determines if redis cache store is active
#
# @return [Boolean] : True if  redis cache store is active
########################################################################
def self.redis_cache_store?
  (Rails.application.config.cache_store.first == :redis_cache_store) rescue false
end

####################################################################
# Clear cache. If key is specified only this key will be deleted.
#
# @param [String] Optional key to be deleted
####################################################################
def self.cache_clear(key = nil)
  return Rails.cache.clear if key.nil?

  if redis_cache_store?
    Rails.cache.redis.del(key)
  else
    Rails.cache.delete_matched("#{key}*")
  end
end

####################################################################
# Read from cache
#
# @keys [Array] Array of keys
#
# @return [Object] Data returned from cache
####################################################################
def self.cache_read(keys)
  data = if redis_cache_store?
           tmp_keys  = keys.dup
           first_key = tmp_keys.shift
           cached    = Rails.cache.redis.hget(first_key, tmp_keys.join(''))
           cached ? Marshal.load(cached) : nil
         else
           Rails.cache.read(keys.join(''))
         end
  return data if data
  return unless block_given?

  cache_write(keys, yield)
end

####################################################################
# Write data to cache
#
# @param [Array] keys : array of keys
# @param [Object] data : Document object
#
# @return [Object] data so cache_write can be used as last statement in method.
####################################################################
def self.cache_write(keys, data)
  if redis_cache_store?
    tmp_keys  = keys.dup
    first_key = tmp_keys.shift
    Rails.cache.redis.hset(first_key, tmp_keys.join(''), Marshal.dump(data))
  else
    Rails.cache.write(keys.join(''), data)
  end
  data
end

########################################################################
# Will dump exception to rails log and console.
#
# Parameters:
# [exception] Object: Exception caught
########################################################################
def self.dump_exception(exception)
  msg = [exception.message, *exception.backtrace].join($/)
  pp msg
  Rails.logger.error msg
end

###############################################################################
# All Routes required by agile_rails.
# 
# Usage:
# put Agile.routes line anywhere into your application routes file
###############################################################################
def self.routes
  Rails.application.routes.draw do
    controller :agile_common do
      post 'agile/autocomplete'            => :autocomplete
      post 'agile_common/ad_click'         => :ad_click
      get 'agile/toggle_edit_mode'         => :toggle_edit_mode
      match 'agile_common/process_login'   => :process_login, via: [:put, :post]
      get 'agile_common/login'             => :login
      get 'agile_common/logout'            => :logout
      get 'agile_common/copy_clipboard'    => :copy_clipboard
      match 'agile_common/paste_clipboard' => :paste_clipboard, via: [:get, :post]
      put 'agile_common/restore_from_journal'  => :restore_from_journal
      get 'agile_common/add_json_ld_schema'    => :add_json_ld_schema
      get 'agile_common/help'                  => :help
      put 'agile_common/poll_submit'           => :poll_submit
    end

    match 'elfinder'     => 'agile_elfinder#connector', via: [:get, :post]
    get   'agile/login'  => 'agile#login'
    get   'agile/logout' => 'agile#logout'
    match 'agile/run'    => 'agile#run', via: [:get, :put, :post]

    resources :agile
  end
end

end
