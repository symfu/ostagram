require 'rails_helper'

RSpec.feature 'Styles', type: :feature do
  let(:client) { create(:client, :confirmed) }
  let(:admin) { create(:client, :admin, :confirmed) }
  let(:style) { create(:style, status: Style::GALLERY_STYLE_IMAGE) } # GALLERY_STYLE_IMAGE

  context 'Style Management' do
    scenario 'Admin can create a new style' do
      sign_in admin
      visit new_style_path
      
      attach_file 'style_image', Rails.root.join('spec', 'fixtures', 'test_style.jpg')
      fill_in 'style_init', with: '-gpu 0 -backend cudnn -image_size 700'
      fill_in 'style_status', with: Style::GALLERY_STYLE_IMAGE.to_s
      
      click_button 'Create Style'
      
      expect(page).to have_content('style was successfully created.')
    end

    scenario 'Regular user cannot create a style' do
      sign_in client
      visit new_style_path
      
      expect(page).to have_content("Cool hacker, you don`t have permission for this action!")
    end

    scenario 'Admin can edit a style' do
      sign_in admin
      visit edit_style_path(style)
      
      fill_in 'style_init', with: '-gpu 0 -backend cudnn -image_size 800'
      click_button 'Update Style'
      
      expect(page).to have_content('style was successfully updated.')
    end

    scenario 'Regular user cannot edit a style' do
      sign_in client
      visit edit_style_path(style)
      
      expect(page).to have_content("Cool hacker, you don`t have permission for this action!")
    end

    scenario 'Admin can delete a style' do
      sign_in admin
      create(:style, status: Style::GALLERY_STYLE_IMAGE)
      visit styles_path
      
      expect(page).to have_content('Styles')
      expect(page).to have_link('New style')
      
      expect(page).to have_link('Destroy')
      
      first('a', text: 'Destroy').click
      
      expect(page).to have_content('style was successfully destroyed.')
    end

    scenario 'Regular user cannot delete a style' do
      sign_in client
      visit styles_path
      
      expect(page).not_to have_link('Destroy')
    end
  end

  context 'Style Gallery' do
    scenario 'Regular user cannot view styles index' do
      sign_in client
      create_list(:style, 5, status: Style::GALLERY_STYLE_IMAGE)
      
      visit styles_path
      
      expect(page).to have_content("Cool hacker, you don`t have permission for this action!")
    end

    scenario 'Regular user cannot view individual style details' do
      sign_in client
      visit style_path(style)
      
      expect(page).to have_content("Cool hacker, you don`t have permission for this action!")
    end

    scenario 'Admin can view all styles' do
      sign_in admin
      create_list(:style, 5, status: Style::GALLERY_STYLE_IMAGE)
      
      visit styles_path
      
      expect(page).to have_selector('.row', count: 5)
    end

    scenario 'Admin can view styles by status' do
      sign_in admin
      create_list(:style, 3, status: Style::GALLERY_STYLE_IMAGE) 
      create_list(:style, 2, status: Style::BOT_STYLE_IMAGE) 
      
      visit styles_path(status: Style::GALLERY_STYLE_IMAGE)
      
      expect(page).to have_selector('.row', count: 3)
    end

    scenario 'Admin can view individual style details' do
      sign_in admin
      visit style_path(style)
      
      expect(page).to have_content(style.id.to_s)
      expect(page).to have_selector('img.imagesStyle')
    end
  end

  context 'Style Selection' do
    scenario 'Gallery view shows available styles' do
      sign_in client
      create_list(:style, 3, status: Style::GALLERY_STYLE_IMAGE)
      
      visit new_queue_image_path(view_style: 1)
      
      expect(page).to have_content('Choose from gallery or upload from file')
      expect(page).to have_content('FROM GALLERY')
      expect(page).to have_content('FROM FILE')
    end

    scenario 'Gallery view shows styles in grid layout' do
      sign_in client
      create_list(:style, 3, status: Style::GALLERY_STYLE_IMAGE)
      
      visit new_queue_image_path(view_style: 1)
      
      expect(page).to have_selector('img.imagesStyle.roundImageStyle', count: 3)
    end
  end

  context 'Style Status Management' do
    scenario 'Admin can change style status' do
      sign_in admin
      visit edit_style_path(style)
      
      fill_in 'style_status', with: Style::BOT_STYLE_IMAGE.to_s 
      click_button 'Update Style'
      
      expect(page).to have_content('style was successfully updated.')
      expect(style.reload.status).to eq(Style::BOT_STYLE_IMAGE)
    end

    scenario 'Style use counter can be manually updated' do
      initial_count = style.use_counter
      
      style.update(use_counter: initial_count + 1)
      
      expect(style.reload.use_counter).to eq(initial_count + 1)
    end
  end

  context 'Access Control' do
    scenario 'Unauthenticated user cannot access styles' do
      visit styles_path
      
      expect(current_path).to eq('/error')
      expect(page).to have_content("Cool hacker, you don`t have permission for this action!")
    end

    scenario 'Regular user cannot view styles' do
      sign_in client
      visit styles_path
      
      expect(page).to have_content("Cool hacker, you don`t have permission for this action!")
    end

    scenario 'Admin has full access to styles' do
      sign_in admin
      visit styles_path
      
      expect(page).to have_content('Styles')
      expect(page).to have_link('New style')
      if Style.count > 0
        expect(page).to have_link('Edit')
        expect(page).to have_link('Destroy')
      end
    end
  end

  context 'Pagination' do
    scenario 'Styles are paginated' do
      sign_in admin
      create_list(:style, 15, status: Style::GALLERY_STYLE_IMAGE)
      
      visit styles_path
      
      expect(page).to have_selector('.row', count: 10)
      expect(page).to have_selector('.pagination')
    end
  end

  context 'Image Processing' do
    scenario 'Style can be used in image processing' do
      sign_in client
      create(:style, status: Style::GALLERY_STYLE_IMAGE)
      
      visit new_queue_image_path(view_style: 1)
      
      attach_file 'queue_image_content_image', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      
      expect(page).to have_selector('img.imagesStyle.roundImageStyle')
      expect(page).to have_content('Choose from gallery or upload from file')
    end

    scenario 'Style with custom parameters can be used' do
      sign_in admin
      custom_style = create(:style, status: Style::GALLERY_STYLE_IMAGE, init: '-gpu 0 -backend cudnn -image_size 500')
      
      visit new_queue_image_path(view_style: 1)
      
      attach_file 'queue_image_content_image', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      
      expect(page).to have_selector('img.imagesStyle.roundImageStyle')
      expect(page).to have_content('Choose from gallery or upload from file')
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
