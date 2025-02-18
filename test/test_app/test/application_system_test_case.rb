require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  space = ["\n", '*'*90, "\n"]
  puts space, 'You may prefix command with env DRIVER=chrome (firefox or headless_chrome or headless_firefox)', space
  driver = ENV["DRIVER"] ? ENV["DRIVER"].to_sym : :headless_chrome
  puts "Using: #{driver} driver"
  driven_by :selenium, using: driver, screen_size: [1400, 1200]

  #driven_by :selenium, using: :chrome, screen_size: [1200, 1400]
  #driven_by :selenium, using: :headless_chrome, screen_size: [1200, 1400]
  #driven_by :selenium, using: :headless_firefox, screen_size: [1200, 1400]

  Capybara.reset!

  ##################################################################################
  # admin login
  ##################################################################################
  def login
    visit '/agile/login'
    assert_selector "h2", text: "Agile"
    fill_in 'record_username', with: 'admin'
    fill_in 'record_password', with: 'secret'
    find('input[type="submit"]').click
    assert_selector "#agile-div"
  end

  ##################################################################################
  # user login
  ##################################################################################
  def user_login(username, password)
    visit '/agile/login'
    assert_selector "h2", text: "Agile"
    fill_in 'record_username', with: username
    fill_in 'record_password', with: password
    find('input[type="submit"]').click
  end

  ##################################################################################
  def click_action(action)
    within ('.ar-action-menu') { click_on(action) }
  end

  ##################################################################################
  def click_form_action(action)
    within ('.ar-edit-menu.top') { click_on(action) }
  end

  ##################################################################################
  def click_form_ajax_action(action)
    within ('.ar-edit-menu.top') { find('li', text: action).click }
  end

end
