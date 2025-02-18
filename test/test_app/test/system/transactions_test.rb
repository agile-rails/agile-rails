require "application_system_test_case"

##################################################################################
class TransactionsTest < ApplicationSystemTestCase

#######################
test "Test transactions" do
  journal_initial_count = ArJournal.all.count
  table_initial_count = ArRemovedUrl.all.count
  login
  visit "/agile?form_name=transactions_test&table=ar_removed_url"
  click_action('New')

  # check if browsed fields are present on form
  fill_in 'record_url', with: 'Some url'
  click_form_action('Save & back')

  # 1 record added to table and journal
  assert_equal 1, ArRemovedUrl.all.count - table_initial_count
  assert_equal 1, ArJournal.all.count - journal_initial_count

  # Test abort transaction
  find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit
  fill_in 'record_url', with: 'Some url updated'
  click_form_action('1. Save with abort transaction')
  click_form_action('Back')

  find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit
  # transaction was aborted. Value of link stays the same. Journal size stays the same.
  assert_equal find_field('record_url').value, 'Some url'
  assert_equal 1, ArJournal.all.count - journal_initial_count

  # Test abort transaction on runtime error
  fill_in 'record_url', with: 'Some url updated'

  #!!!!!!! assert_raise is not working. I had to update controller code
  click_form_action('2. Save with runtime error')

  click_form_action('Back')
  find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit
  # transaction was aborted. Value of link stays the same. Journal size stays the same.
  assert_equal find_field('record_url').value, 'Some url'
  assert_equal 1, ArJournal.all.count - journal_initial_count

  # This time do it right
  fill_in 'record_url', with: 'Some url updated'
  click_form_action('Save & back')
  find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit
  # value of link is changed
  assert_equal find_field('record_url').value, 'Some url updated'
  # Journal has 1 record added
  assert_equal 2, ArJournal.all.count - journal_initial_count
end

end
