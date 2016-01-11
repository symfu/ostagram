require 'rails_helper'

RSpec.feature 'Queue Images', type: :feature do
  let(:client) { create(:client, :confirmed) }
  let(:admin) { create(:client, :admin, :confirmed) }
  let(:style) { create(:style, status: Style::GALLERY_STYLE_IMAGE) } # GALLERY_STYLE_IMAGE
  let(:queue_image) { create(:queue_image, client: client, style: style) }



  context 'Image Processing' do
    scenario 'User can add image to processing queue with file upload' do
      sign_in client
      visit new_queue_image_path(view_style: 0)
      
      expect(page).to have_content('Image to process:')
      expect(page).to have_content('Upload filter file:')
      
      attach_file 'queue_image_content_image', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      attach_file 'queue_image[style_image]', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      
      click_button 'Add to processing'
      
      expect(page).to have_content('Images successfully added to processing queue.')
      expect(current_path).to eq(queue_images_path)
    end

    scenario 'User can add image to processing queue from gallery' do
      sign_in client
      style 
      visit new_queue_image_path(view_style: 1)
      
      attach_file 'queue_image_content_image', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      
      expect(page).to have_content('Choose from gallery or upload from file')
      expect(page).to have_content('FROM GALLERY')
      expect(page).to have_content('FROM FILE')
    end

    scenario 'User cannot add image without content image' do
      sign_in client
      visit new_queue_image_path(view_style: 0)
      
      attach_file 'queue_image[style_image]', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      
      click_button 'Add to processing'
      
      expect(page).to have_content('Please add an image for processing')
    end

    scenario 'User cannot add image without style image when uploading file' do
      sign_in client
      visit new_queue_image_path(view_style: 0)
      
      attach_file 'queue_image_content_image', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      
      click_button 'Add to processing'
      
      expect(page).to have_content('Please add a filter image')
    end

    scenario 'User cannot add image without selecting style from gallery' do
      sign_in client
      visit new_queue_image_path(view_style: 1)
      
      attach_file 'queue_image_content_image', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      
      click_button 'Add to processing'
      
      expect(page).to have_content('Please select a filter image')
    end

    scenario 'Admin can set processing parameters' do
      sign_in admin
      visit new_queue_image_path(view_style: 0)
      
      attach_file 'queue_image_content_image', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      attach_file 'queue_image[style_image]', Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')
      
      fill_in 'queue_image[init]', with: '-gpu 0 -backend cudnn -image_size 500'
      fill_in 'queue_image[end_status]', with: QueueImage::STATUS_PROCESSED_BY_BOT.to_s
      
      click_button 'Add to processing'
      
      expect(page).to have_content('Images successfully added to processing queue.')
    end
  end

  context 'Image Management' do
    scenario 'User can view their image collection' do
      sign_in client
      create_list(:queue_image, 3, client: client)
      
      visit queue_images_path
      
      expect(page).to have_content('My collection')
      expect(page).to have_selector('.styleRow2-lg', count: 3)
    end

    scenario 'Regular user cannot view individual image details' do
      sign_in client
      visit queue_image_path(queue_image)
      
      expect(page).to have_content("Cool hacker, you don`t have permission for this action!")
    end

    scenario 'Admin can view individual image details' do
      sign_in admin
      visit queue_image_path(queue_image)
      
      expect(page).to have_content('Back')
      expect(page).to have_content('Likes:')
      expect(page).to have_content('Images:')
    end

    scenario 'User can make image visible' do
      sign_in client
      hidden_image = create(:queue_image, client: client, status: QueueImage::STATUS_HIDDEN) # STATUS_HIDDEN
      
      page.driver.browser.put "/queue_images/#{hidden_image.id}/visible"
      
      expect(hidden_image.reload.status).to eq(QueueImage::STATUS_PROCESSED) # STATUS_PROCESSED
    end

    scenario 'User can hide image' do
      sign_in client
      visible_image = create(:queue_image, client: client, status: QueueImage::STATUS_PROCESSED) # STATUS_PROCESSED
      
      page.driver.browser.put "/queue_images/#{visible_image.id}/hidden"
      
      expect(visible_image.reload.status).to eq(QueueImage::STATUS_HIDDEN) # STATUS_HIDDEN
    end

    scenario 'User can delete image' do
      sign_in client
      deletable_image = create(:queue_image, client: client, status: QueueImage::STATUS_NOT_PROCESSED) # STATUS_NOT_PROCESSED
      visit queue_images_path
      
      first('a', text: 'DELETE').click
      
      expect(page).to have_content('Images deleted.')
    end
  end

  context 'Likes and Social Features' do
    scenario 'User can like an image' do
      sign_in client
      other_image = create(:queue_image, client: create(:client, :confirmed))
      
      page.driver.browser.put "/queue_images/#{other_image.id}/like"
      
      expect(other_image.reload.likes_count).to eq(1)
      expect(Like.exists?(queue_id: other_image.id, client_id: client.id)).to be true
    end

    scenario 'User can unlike an image' do
      sign_in client
      other_image = create(:queue_image, client: create(:client, :confirmed))
      Like.create(queue_id: other_image.id, client_id: client.id)
      other_image.update(likes_count: 1)
      
      page.driver.browser.put "/queue_images/#{other_image.id}/unlike"
      
      expect(other_image.reload.likes_count).to eq(0)
      expect(Like.exists?(queue_id: other_image.id, client_id: client.id)).to be false
    end

    scenario 'User cannot like their own image' do
      sign_in client
      visit queue_image_path(queue_image)
      
      expect(page).not_to have_link('Like')
    end
  end

  context 'View Styles' do
    scenario 'User can switch between file upload and gallery view styles' do
      sign_in client
      visit new_queue_image_path(view_style: 0)
      
      expect(page).to have_content('FROM GALLERY')
      expect(page).to have_content('FROM FILE')
      
      click_link 'FROM GALLERY'
      
      expect(page).to have_content('FROM GALLERY')
      expect(page).to have_content('FROM FILE')
    end

    scenario 'Gallery view shows available styles' do
      sign_in client
      create_list(:style, 3, status: Style::GALLERY_STYLE_IMAGE) # GALLERY_STYLE_IMAGE
      
      visit new_queue_image_path(view_style: 1)
      
      expect(page).to have_selector('img.imagesStyle.roundImageStyle', count: 3)
    end
  end

  context 'Access Control' do
    scenario 'Unauthenticated user cannot access queue images' do
      visit queue_images_path
      
      expect(current_path).to eq('/error')
      expect(page).to have_content("Cool hacker, you don`t have permission for this action!")
    end

    scenario 'User can only see their own images' do
      other_client = create(:client, :confirmed)
      other_image = create(:queue_image, client: other_client)
      
      sign_in client
      visit queue_images_path
      
      expect(page).not_to have_content(other_image.id.to_s)
    end

    scenario 'User cannot access other user images' do
      other_client = create(:client, :confirmed)
      other_image = create(:queue_image, client: other_client)
      
      sign_in client
      visit queue_image_path(other_image)
      
      expect(current_path).to eq('/error')
      expect(page).to have_content("Cool hacker, you don`t have permission for this action!")
    end
  end

  context 'Pagination' do
    scenario 'Images are paginated' do
      sign_in client
      create_list(:queue_image, 10, client: client)
      
      visit queue_images_path
      
      expect(page).to have_selector('.styleRow2-lg', count: 6) 
      expect(page).to have_selector('.pagination')
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
