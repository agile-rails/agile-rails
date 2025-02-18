require "application_system_test_case"

##################################################################################
class DataSetAsMethodTest < ApplicationSystemTestCase

#######################
test "test if anything returned" do
  login
  visit "/agile?form_name=data_set_as_method&table=ar_memory"
  # check for h2 to be present
  assert_css('h2', count: 1)
  within ('h2') { assert_text('Works') }
end

end
