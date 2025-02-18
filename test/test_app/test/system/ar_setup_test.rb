
require "application_system_test_case"
class ArSetupTest < ApplicationSystemTestCase

  @@form_data = %(
tab1:
  caption: My app
  10:
    name: partner
    type: text_field
    size: 50
  20:
    name: ceo
    type: text_field
    size: 30
)

  test "application_setup" do
    login
    # Open Applications settings
    find(:xpath, "(//button[@class='cms-toggle mode-1'])").click
    find(:xpath, "(//div[text()='Advanced tables'])").click
    click_link_or_button 'Applications settings'

    # add new setup options
    page.within_frame('iframe_cms') do
      sleep 2
      click_action('New')
      fill_in 'record_name', with: 'my app name'
      # add editor user
      find_field('record__editors').click
      fill_in 'record__editors', with: 'use'
      find(:xpath, "(//div[text()='User 5'])").click
      assert_equal find_field('record__editors').value, 'User 5'
      find(:xpath, "(.//i[@class='mi-o mi-plus_square mi-green'])[1]").click # Click on + icon

      find(:xpath, "(//li[text()='Form'])").click # Click form tab
      fill_in 'record_form', with: @@form_data

      click_form_action('Save')
    end

    # login as User 5. User 5 can edit application settings
    user_login 'user5', 'secret'
    visit '/agile?table=ar_setup'
    find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit
    assert find(:xpath, "(//li[text()='My app'])") # My app tab exists

    fill_in 'record_partner', with: 'My partner'
    fill_in 'record_ceo', with: 'CEO name'
    click_form_action('Save & back')
    find(:xpath, "(.//i[@class='mi-o mi-edit'])[1]").click # Click on edit
    assert_equal find_field('record_partner').value, 'My partner'
    assert_equal find_field('record_ceo').value, 'CEO name'
  end

end
