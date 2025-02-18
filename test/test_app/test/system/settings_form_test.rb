require "application_system_test_case"

##################################################################################
class SettingsFormTest < ApplicationSystemTestCase

#######################
test "Test settings for design element" do
  ArJournal.delete_all
  login
  site = ArSite.find_by(name: 'my.site.com')
  visit "/agile/new?form_name=settings_form_1&table=ar_memory&id=#{site.id}&element=element1&location=ar_site&field_name=settings"
  # check if browsed fields are present on form
  fill_in 'record_field2', with: 'New value'
  fill_in 'record_field3', with: ''
  click_form_action('Save')
  # New value must be on form
  assert_equal find_field('record_field2').value, 'New value'

  site = ArSite.find_by(name: 'my.site.com')
  # and must be in file
  assert_match '  field2: New value', site.settings

  login # otherwise next test fails
  visit "/agile/new?form_name=settings_form_1&table=ar_memory&id=#{site.id}&element=element1&location=ar_site&field_name=settings"
  # clear field2
  fill_in 'record_field2', with: ''
  fill_in 'record_field3', with: 'Some value'
  click_form_action('Save')
  site = ArSite.find_by(name: 'my.site.com')
  # should not be in DB
  assert_no_match 'field2:', site.settings
  assert_match '  field3: Some value', site.settings
  assert_equal ArJournal.all.size, 2, 'Should be 2 documents in journal'

  ####################### Test settings for any option available
  visit "/agile/new?form_name=settings_form_2&table=ar_memory&id=#{site.id}&location=ar_site&field_name=settings"
  # check if value loaded
  assert_equal find_field('record_ck_config').value, '/files/ck_config.js'
  fill_in 'record_field1', with: 'Value1'
  fill_in 'record_field2', with: 'Value2'
  fill_in 'record_field3', with: 'Value3'
  click_form_action('Save')
  # New value must be on form
  assert_equal find_field('record_field1').value, 'Value1'
  assert_equal find_field('record_field2').value, 'Value2'

  # and must be in DB
  site = ArSite.find_by(name: 'my.site.com')
  assert_match 'field1: Value1', site.settings
  assert_match 'field2: Value2', site.settings
  assert_match 'field3: Value3', site.settings

  login # otherwise next test fails
  visit "/agile/new?form_name=settings_form2&table=ar_memory&id=#{site.id}&location=ar_site&field_name=settings"
  # clear field2
  fill_in 'record_field2', with: ''
  fill_in 'record_field3', with: 'New value'
  click_form_action('Save')

  site = ArSite.find_by(name: 'my.site.com')
  # should not be in DB
  assert_no_match 'field2:', site.settings
  assert_match 'field3: New value', site.settings
  assert_equal ArJournal.all.size, 4, 'Should be 4 documents in journal'
end

end

