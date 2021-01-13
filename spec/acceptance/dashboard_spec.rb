require 'rails_helper'

RSpec.feature 'An admin user navigating the dashboard' do

  before(:each) do
    @admin = create(:admin)
    admin_role = Role.find_by(name: "admin") || Role.create(name: "admin")
    admin_role.users << @admin
    admin_role.save
    visit '/users/sign_in'
    fill_in "user_email", with: @admin.email
    fill_in "user_password", with: "password"
    page.click_button('Log in')
    puts @admin.email
    visit '/dashboard'
  end

  after(:each) do
    visit '/users/sign_out'
  end

  scenario 'views the main dashboard page' do
    expect(page).to have_content('Your activity')
    expect(page).to have_content('Works')
    expect(page).to have_content('Collections')
#   expect(page).to have_content('Review Submissions')
    expect(page).to have_content('Manage Users')
    expect(page).to have_content('Bulk Operations')
    expect(page).to have_content('Settings')
    expect(page).to have_content('Workflow Roles')
  end

  scenario 'views admin collections browse page' do
    create_list(:collection_lw,2)
    click_on 'Collections'
    click_on "All Collections"
    expect(page).to have_css('td>div.thumbnail-title-wrapper')
  end

  scenario 'views admin works browse page' do
    build_list(:work,11)
    click_on 'Works'
    click_on "All Works"
    expect(page).to have_css('td>div.media img',count: 24)
  end

  scenario 'views Manage Users page' do
    click_on 'Manage Users'
    expect(page).to have_content('Username')
    expect(page).to have_content('Last access')
    expect(page).to have_css('tbody tr')
  end

end

