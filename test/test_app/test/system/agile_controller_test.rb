require 'application_system_test_case'

class AgileControllerTest < ApplicationSystemTestCase

  test '1_browse_and_update_collection' do
    login
    #sleep  20
    assert_selector '#agile-div'
    # Open CMS submenus
    find(:xpath, "(//button[@class='cms-toggle mode-1'])").click
    find(:xpath, "(//div[text()='Main tables'])").click
    find(:xpath, "(//div[text()='Advanced tables'])").click
    click_link_or_button 'Sites'
    # iframe_cms
    page.within_frame('iframe_cms') do
      find(:xpath, "(.//i[@class='mi mi-more_vert'])[1]").click # Click on first menu
      find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit

      assert_equal find_field('record_name').value, 'my.site.com'

      find(:xpath, "(//li[text()='Parameters'])").click # Click parameters tab
      assert_equal find_field('record_menu_class').value, 'ArMenu'

      find(:xpath, "(//li[text()='Permissions'])").click # Click permissions tab

      # if_ar_policies iframe
      page.within_frame('if_ar_policies') do
        find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit
        assert_equal find_field('record_description').value, 'Default policy'

        # if_ar_policy_rules iframe
        page.within_frame('if_policy_rules') do
          find(:xpath, "(.//i[@class='mi-o mi-edit'])[3]").click # Click on edit
          # value should be 1
          assert_equal( find_field('record_permission').value, '1' )
          find_field('record_permission').find(:option, 'CAN_EDIT').select_option
          # press Save and back. First
          click_form_action('Save & back')
          # If OK, there should be permission row with CAN_ADMIN
          #          assert find(:xpath, "(.//i[@class='mi-o mi-edit'])[3]").find(:xpath, "(//div[text()='CAN_EDIT'])")
          find(:xpath, "(.//i[@class='mi-o mi-edit'])[3]").click # Click on edit
          assert_equal( find_field('record_permission').value, '2' )
        end
      end
    end

    # Add policy to site
    visit '/agile?form_name=ar_site&table=ar_site'
    assert_selector '.ar-form-frame'

    find(:xpath, "(.//i[@class='mi mi-more_vert'])[1]").click # Click on first menu
    find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit
    assert_equal find_field('record_name').value, 'my.site.com'
    fill_in 'record_description', with: 'Description'

    click_form_action('Save & back')
    assert find(:xpath, "(//div[text()='Description'])")

    find(:xpath, "(.//i[@class='mi mi-more_vert'])[1]").click # Click on first menu
    find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit

    find(:xpath, "(//li[text()='Parameters'])").click # Click parameters tab
    assert_equal find_field('record_menu_class').value, 'ArMenu'

    find(:xpath, "(//li[text()='Permissions'])").click # Click permissions tab

    # if_ar_policies iframe
    page.within_frame('if_ar_policies') do
      find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit

      assert_equal find_field('record_name').value, 'Default policy'
      fill_in 'record_name', with: 'New Description'
      click_form_action('Save & back')

      assert find(:xpath, "(//div[text()='New Description'])")
      find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit

      # if_ar_policy_rules iframe
      page.within_frame('if_policy_rules') do
        find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit
        assert_equal find_field('record_permission').value, '2'

        click_form_action('Save & back')
      end

=begin
      page.within_frame('if_policy_rules') do
        assert find(:xpath, "(//div[text()='Access policy rules'])")
        assert find(:xpath, "(//div[text()='CAN_EDIT'])")
      end
=end
    end
  end

end

