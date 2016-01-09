require 'rails_helper'

RSpec.feature 'Authentication', type: :feature do
  let(:client) { create(:client, :confirmed) }
  let(:admin) { create(:client, :admin, :confirmed) }

  context 'User Registration' do
    scenario 'User can register with valid information' do
      visit new_client_registration_path
      
      fill_in 'client_email', with: 'newuser@example.com'
      fill_in 'client_name', with: 'New User'
      fill_in 'client_password', with: 'password123'
      fill_in 'client_password_confirmation', with: 'password123'
      
      attach_file 'client_avatar', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      
      click_button 'Sign up'
      
      expect(page).to have_content('Welcome! You have successfully signed up.')
      expect(Client.last.email).to eq('newuser@example.com')
    end

    scenario 'User cannot register with invalid email' do
      visit new_client_registration_path
      
      fill_in 'client_email', with: 'invalid-email'
      fill_in 'client_name', with: 'New User'
      fill_in 'client_password', with: 'password123'
      fill_in 'client_password_confirmation', with: 'password123'
      
      attach_file 'client_avatar', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      
      click_button 'Sign up'
      
      expect(page).to have_content('Email is invalid')
    end

    scenario 'User cannot register with short password' do
      visit new_client_registration_path
      
      fill_in 'client_email', with: 'newuser@example.com'
      fill_in 'client_name', with: 'New User'
      fill_in 'client_password', with: '123'
      fill_in 'client_password_confirmation', with: '123'
      
      attach_file 'client_avatar', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      
      click_button 'Sign up'
      
      expect(page).to have_content('Password is too short')
    end

    scenario 'User cannot register with mismatched passwords' do
      visit new_client_registration_path
      
      fill_in 'client_email', with: 'newuser@example.com'
      fill_in 'client_name', with: 'New User'
      fill_in 'client_password', with: 'password123'
      fill_in 'client_password_confirmation', with: 'different123'
      
      attach_file 'client_avatar', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      
      click_button 'Sign up'
      
      expect(page).to have_content("Password confirmation doesn't match Password")
    end
  end

  context 'User Login' do
    scenario 'User can login with valid credentials' do
      visit new_client_session_path
      
      fill_in 'client_email', with: client.email
      fill_in 'client_password', with: 'password123'
      
      click_button 'Sign in'
      
      expect(page).to have_content('Successfully signed in.')
    end

    scenario 'User cannot login with invalid email' do
      visit new_client_session_path
      
      fill_in 'client_email', with: 'nonexistent@example.com'
      fill_in 'client_password', with: 'password123'
      
      click_button 'Sign in'
      
      expect(page).to have_content('Invalid email or password.')
    end

    scenario 'User cannot login with invalid password' do
      visit new_client_session_path
      
      fill_in 'client_email', with: client.email
      fill_in 'client_password', with: 'wrongpassword'
      
      click_button 'Sign in'
      
      expect(page).to have_content('Invalid email or password.')
    end

    scenario 'User cannot login when account is locked' do
      locked_client = create(:client, :locked, :confirmed)
      visit new_client_session_path
      
      fill_in 'client_email', with: locked_client.email
      fill_in 'client_password', with: 'password123'
      
      click_button 'Sign in'
      
      expect(page).to have_content('Your account is locked.')
    end
  end

  context 'User Logout' do
    scenario 'User can logout successfully' do
      sign_in client
      visit root_path
      
      click_link 'Sign out'
      
      expect(page).to have_content('Successfully signed out.')
      expect(current_path).to eq('/about')
    end
  end

  context 'Password Reset' do
    scenario 'User can request password reset' do
      visit new_client_password_path
      
      fill_in 'client_email', with: client.email
      click_button 'Send me reset password instructions'
      
      expect(page).to have_content('Within a few minutes, you will receive an email with instructions to recover your password.')
    end

    scenario 'User cannot request password reset with invalid email' do
      visit new_client_password_path
      
      fill_in 'client_email', with: 'nonexistent@example.com'
      click_button 'Send me reset password instructions'
      
      expect(page).to have_content('Email not found')
    end
  end

  context 'Account Management' do
    scenario 'User can change password' do
      sign_in client
      visit edit_client_registration_path
      
      fill_in 'client_password', with: 'newpassword123'
      fill_in 'client_password_confirmation', with: 'newpassword123'
      fill_in 'client_current_password', with: 'password123'
      
      click_button 'Update'
      
      expect(page).to have_content('Your account has been successfully updated.')
    end

    scenario 'User cannot change password without current password' do
      sign_in client
      visit edit_client_registration_path
      
      fill_in 'client_password', with: 'newpassword123'
      fill_in 'client_password_confirmation', with: 'newpassword123'
      
      click_button 'Update'
      
      expect(page).to have_content("Current password can't be blank")
    end
  end

  context 'Access Control' do
    scenario 'Unauthenticated user cannot access protected pages' do
      visit queue_images_path
      
      expect(current_path).to eq('/error')
      expect(page).to have_content("Cool hacker, you don`t have permission for this action!")
    end

    scenario 'Regular user cannot access admin pages' do
      sign_in client
      visit admin_pages_main_path
      
      expect(page).to have_content("Cool hacker, you don`t have permission for this action!")
    end

    scenario 'Admin can access admin pages' do
      sign_in admin
      visit admin_pages_main_path
      
      expect(page).to have_content('Welcome to the Ostagram Project')
    end
  end

  private

  def sign_in(client)
    visit new_client_session_path
    fill_in 'client_email', with: client.email
    fill_in 'client_password', with: 'password123'
    click_button 'Sign in'
  end
end
