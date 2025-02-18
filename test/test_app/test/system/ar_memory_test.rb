require "application_system_test_case"

##################################################################################
class ArMemoryTest < ApplicationSystemTestCase

#######################
test "test array browse and data edit with submit" do
  #login
  visit "/agile?form_name=ar_memory_test_submit&table=ar_memory"

  # check if browsed fields are present on form
  assert_equal find('.th[data-name="description"]').text, 'description'
  assert_equal find('.ar-result-data.ar-odd div:nth-child(2)').text, 'Name 1'
  assert_equal find('.ar-result-data.ar-odd div:nth-child(4)').text, 'Description 1'

  assert_equal find('.ar-result-data.footer div:nth-child(2)').text, 'Footer'
  assert_equal find('.ar-result-data.footer div:nth-child(4)').text, 'Footer description'

  click_action('New')
  fill_in 'record_name', with: 'New name'
  fill_in 'record_description', with: 'New description'

  click_form_action('Save')
  # Info should be written out
  assert_equal find('.ar-form-info').text, 'New name'
end

#######################
test "test data edit with ajax action call" do
  #login
  visit "/agile/new?form_name=ar_memory_test_ajax&table=ar_memory"
  fill_in 'record_info', with: 'info'
  fill_in 'record_error', with: 'error'

  # test not defined action
  click_form_ajax_action('Error ajax call')
  # not defined error text
  assert_match 'not defined', find('.ar-form-error').text

  # test ajax action. Should return some data in info and error message section and change info input field
  click_form_ajax_action('Ajax call')
  # info text present
  assert_equal find('.ar-form-info').text, 'info'
  assert_equal find('.ar-form-error').text, 'error'

  assert_equal find_field('record_info').value, 'updated'
end

end

