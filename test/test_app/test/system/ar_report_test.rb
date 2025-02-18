require 'application_system_test_case'

##################################################################################
class ArReportTest < ApplicationSystemTestCase

#######################
test 'test report' do
  login
  visit '/agile/new?form_name=ar_test_report&table=ar_memory'
  page.within_frame('if_ar_temp') do
    #assert_equal find('dc-result-data').exists?, true
  end

  # check if data_set fields are present on form
  fill_in 'record_year', with: Time.now.year.to_s
  find_field('record_category').find(:option, 'cat 2').select_option

  click_form_ajax_action('Update')
  page.within_frame('if_ar_temp') do
    assert_equal find('-dc-result-data').count, 5
  end
end

end
