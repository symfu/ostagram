require 'rails_helper'

RSpec.describe AdminPagesController, type: :controller do
  let(:client) { create(:client, :admin) }
  let(:queue_image) { create(:queue_image) }
  let(:style) { create(:style) }
  let(:content) { create(:content) }

  before do
    allow(controller).to receive(:current_client).and_return(client)
    allow(controller).to receive(:client_signed_in?).and_return(true)
    allow(controller).to receive(:start_bot).and_return(nil)
    allow(controller).to receive(:start_workers).and_return(nil)
    allow(Resque).to receive(:workers).and_return([])
  end

  describe 'GET #main' do
    it 'returns http success' do
      get :main
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #images' do
    let!(:queue_image1) { create(:queue_image, status: 1) }
    let!(:queue_image2) { create(:queue_image, status: 2) }

    context 'without status parameter' do
      it 'returns http success' do
        get :images
        expect(response).to have_http_status(:success)
      end

      it 'assigns @items with all queue images' do
        get :images
        expect(assigns(:items)).to include(queue_image1, queue_image2)
      end

      it 'assigns @pimage_show as false' do
        get :images
        expect(assigns(:pimage_show)).to be false
      end
    end

    context 'with status parameter' do
      it 'filters by status' do
        get :images, status: 1
        expect(assigns(:items)).to include(queue_image1)
        expect(assigns(:items)).not_to include(queue_image2)
      end
    end

    context 'with pimage parameter true' do
      it 'sets @pimage_show to true' do
        get :images, pimage: 'true'
        expect(assigns(:pimage_show)).to be true
      end
    end

    context 'with pimage parameter false' do
      it 'sets @pimage_show to false' do
        get :images, pimage: 'false'
        expect(assigns(:pimage_show)).to be false
      end
    end
  end

  describe 'GET #users' do
    it 'returns http success' do
      get :users
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #startbot' do
    it 'calls start_bot' do
      expect(controller).to receive(:start_bot)
      get :startbot
    end

    it 'redirects to admin_pages_main_path' do
      get :startbot
      expect(response).to redirect_to(admin_pages_main_path)
    end
  end

  describe 'GET #startprocess' do
    it 'calls start_workers' do
      expect(controller).to receive(:start_workers)
      get :startprocess
    end

    it 'redirects to admin_pages_main_path' do
      get :startprocess
      expect(response).to redirect_to(admin_pages_main_path)
    end
  end

  describe 'GET #unregworkers' do
    it 'redirects to admin_pages_main_path' do
      get :unregworkers
      expect(response).to redirect_to(admin_pages_main_path)
    end
  end

  describe 'GET #update_queue_status' do
    it 'updates queue image status' do
      get :update_queue_status, id: queue_image.id, status: 2
      queue_image.reload
      expect(queue_image.status).to eq(2)
    end

    it 'assigns @queue_image' do
      get :update_queue_status, id: queue_image.id, status: 2
      expect(assigns(:queue_image)).to eq(queue_image)
    end

    it 'redirects to admin_pages_images_path for HTML format' do
      get :update_queue_status, id: queue_image.id, status: 2
      expect(response).to redirect_to(admin_pages_images_path)
    end
  end

  describe 'PUT #update_queue_status' do
    it 'updates queue image status' do
      put :update_queue_status, id: queue_image.id, status: 2
      queue_image.reload
      expect(queue_image.status).to eq(2)
    end

    it 'assigns @queue_image' do
      put :update_queue_status, id: queue_image.id, status: 2
      expect(assigns(:queue_image)).to eq(queue_image)
    end

    it 'redirects to admin_pages_images_path for HTML format' do
      put :update_queue_status, id: queue_image.id, status: 2
      expect(response).to redirect_to(admin_pages_images_path)
    end

    it 'responds to JS format' do
      put :update_queue_status, id: queue_image.id, status: 2, format: :js
      expect(response.content_type).to eq('text/javascript')
    end
  end

  describe 'PUT #update_style_status' do
    let(:queue_image_with_style) { create(:queue_image, style: style) }

    it 'updates style status' do
      put :update_style_status, id: queue_image_with_style.id, status: 2
      style.reload
      expect(style.status).to eq(2)
    end

    it 'assigns @queue_image' do
      put :update_style_status, id: queue_image_with_style.id, status: 2
      expect(assigns(:queue_image)).to eq(queue_image_with_style)
    end

    it 'assigns @style' do
      put :update_style_status, id: queue_image_with_style.id, status: 2
      expect(assigns(:style)).to eq(style)
    end

    it 'redirects to admin_pages_images_path for HTML format' do
      put :update_style_status, id: queue_image_with_style.id, status: 2
      expect(response).to redirect_to(admin_pages_images_path)
    end

    it 'responds to JS format' do
      put :update_style_status, id: queue_image_with_style.id, status: 2, format: :js
      expect(response.content_type).to eq('text/javascript')
    end
  end

  describe 'PUT #delete_queue' do
    it 'destroys the queue image' do
      queue_image_to_delete = create(:queue_image)
      expect {
        put :delete_queue, id: queue_image_to_delete.id
      }.to change(QueueImage, :count).by(-1)
    end

    it 'assigns @queue_image' do
      put :delete_queue, id: queue_image.id
      expect(assigns(:queue_image)).to eq(queue_image)
    end

    it 'redirects to admin_pages_images_path for HTML format' do
      put :delete_queue, id: queue_image.id
      expect(response).to redirect_to(admin_pages_images_path)
    end

    it 'responds to JS format' do
      put :delete_queue, id: queue_image.id, format: :js
      expect(response.content_type).to eq('text/javascript')
    end
  end

  describe 'PUT #update_content_status' do
    let(:queue_image_with_content) { create(:queue_image, content: content) }

    it 'updates content status' do
      put :update_content_status, id: queue_image_with_content.id, status: 2
      content.reload
      expect(content.status).to eq(2)
    end

    it 'assigns @queue_image' do
      put :update_content_status, id: queue_image_with_content.id, status: 2
      expect(assigns(:queue_image)).to eq(queue_image_with_content)
    end

    it 'assigns @content' do
      put :update_content_status, id: queue_image_with_content.id, status: 2
      expect(assigns(:content)).to eq(content)
    end

    it 'redirects to admin_pages_images_path for HTML format' do
      put :update_content_status, id: queue_image_with_content.id, status: 2
      expect(response).to redirect_to(admin_pages_images_path)
    end

    it 'responds to JS format' do
      put :update_content_status, id: queue_image_with_content.id, status: 2, format: :js
      expect(response.content_type).to eq('text/javascript')
    end
  end

  describe 'authorization' do
    it 'requires admin user for all actions' do
      expect { get :main }.not_to raise_error
    end
  end
end
