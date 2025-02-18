require "application_system_test_case"
class LoginTest < ApplicationSystemTestCase

  test 'login_ok' do
    login
    assert_selector '#agile-div'
  end

  test 'login_failed' do
    visit '/agile/login'
    assert_selector "h2", text: "Login"
    fill_in 'record_username', with: 'admin'
    fill_in 'record_password', with: 'wrongsecret'
    find('input[type="submit"]').click

    assert has_no_css?('#agile-div')
  end

end

