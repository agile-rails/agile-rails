require "application_system_test_case"

class AgileFormsTest < ApplicationSystemTestCase

  test "agile_form_fields_test" do
    site = ArSite.find_by(name: 'my.site.com')
    login
    visit "/agile/new?form_name=agile_forms_test&table=ar_memory"
    assert_selector ".ar-form-frame"

    # textfield field11
    value = 'Value field11'
    fill_in 'record_field11', with: value
    assert_equal find_field('record[field11]').value, value
    # textfield2 should have my-class
    within("#td_record_field2") {
      assert find('.my-class')
    }
    # textfield3 readonly field
    assert_equal find_field('record_field3', type: :hidden).value, 'ReadOnly field 1'
    assert_equal find_field('record_field3r', type: :hidden).value, 'ReadOnly field 3r'
    # textfield field6
    assert_empty find_field('record_field6').value
    value = 'Value field6'
    fill_in 'record_field6', with: value
    assert_equal find_field('record_field6').value, value

    # text_with_select field7
    assert_empty find_field('record_field7').value
    find_field('field7_').find(:option, 'two').select_option
    assert_equal find_field('record_field7').value, 'two'

    # TAB SELECT FIELDS
    find(:xpath, "(//li[text()='SELECT FIELDS'])").click
    assert page.has_no_checked_field?('record_field20')
    find_field('record_field20').click
    assert page.has_checked_field?('record_field20')
    # select field21
    assert_equal find_field('record_field21').value, 'Yes'
    find_field('record_field21').find(:option, 'No').select_option
    assert_equal find_field('record_field21').value, 'No'
    # select field22
    assert_empty find_field('record_field22').value
    find_field('record_field22').find(:option, 'Sent').select_option
    assert_equal find_field('record_field22').value, '3'
    # select field23
    assert_equal find_field('record_field23').value, '2'
    find_field('record_field23').find(:option, 'Four').select_option
    assert_equal find_field('record_field23').value, '4'
    # select field24
    assert_empty find_field('record_field24').value
    find_field('record_field24').find(:option, 'my.site.com').select_option
    assert_equal find_field('record_field24').value, site.id.to_s

    # select field25
    assert_empty find_field('record_field25').value
    find_field('record_field25').find(:option, 'six').select_option
    assert_equal find_field('record_field25').value, '6'

    # TAB SELECT CONTINUES
    find(:xpath, "(//li[text()='SELECT CONTINUES'])").click
    within("#td_record_field31") {
      #       within(:xpath, "(select)") {
      #         find(:xpath, "(//option[text()='www.mysite.com'])").click
      #       }
    }

    find_field('record__field32').click
    fill_in 'record__field32', with: 'my'
    find(:xpath, "(//div[text()='my.site.com'])").click
    assert_equal find_field('record__field32').value, 'my.site.com'

  end

end

