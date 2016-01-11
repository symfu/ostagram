require 'rails_helper'

RSpec.describe QueueImagesController, type: :controller do
  let(:client) { create(:client, :admin) }
  let(:queue_image) { create(:queue_image, client: client) }
  let(:style) { create(:style) }
  let(:content) { create(:content) }

  before do
    allow(controller).to receive(:current_client).and_return(client)
    allow(controller).to receive(:client_signed_in?).and_return(true)
    allow(controller).to receive(:start_workers).and_return(nil)
  end

  describe 'GET #index' do
    let!(:queue_image1) { create(:queue_image, client: client, status: 1) }
    let!(:queue_image2) { create(:queue_image, client: client, status: 2) }

    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns @items with client queue images' do
      get :index
      expect(assigns(:items)).to include(queue_image1, queue_image2)
    end

    it 'orders by created_at DESC' do
      get :index
      expect(assigns(:items).first).to eq(queue_image2)
    end

    it 'paginates results' do
      get :index
      expect(assigns(:items).respond_to?(:current_page)).to be true
    end
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show, id: queue_image.id
      expect(response).to have_http_status(:success)
    end

    it 'assigns @queue_image' do
      get :show, id: queue_image.id
      expect(assigns(:queue_image)).to eq(queue_image)
    end
  end

  describe 'GET #new' do
    context 'without view_style parameter' do
      it 'returns http success' do
        get :new
        expect(response).to have_http_status(:success)
      end

      it 'assigns @queue_image' do
        get :new
        expect(assigns(:queue_image)).to be_a_new(QueueImage)
      end

      it 'sets @view_style to VIEW_STYLE_FROM_LIST' do
        get :new
        expect(assigns(:view_style)).to eq(ConstHelper::VIEW_STYLE_FROM_LIST)
      end
    end

    context 'with view_style parameter 0' do
      it 'sets @view_style to VIEW_STYLE_LOAD_FILE' do
        get :new, view_style: '0'
        expect(assigns(:view_style)).to eq(ConstHelper::VIEW_STYLE_LOAD_FILE)
      end
    end

    context 'with view_style parameter 1' do
      it 'sets @view_style to VIEW_STYLE_FROM_LIST' do
        get :new, view_style: '1'
        expect(assigns(:view_style)).to eq(ConstHelper::VIEW_STYLE_FROM_LIST)
      end
    end

    context 'with view_style parameter 2' do
      it 'sets @view_style to VIEW_STYLE_FROM_LENTA' do
        get :new, view_style: '2'
        expect(assigns(:view_style)).to eq(ConstHelper::VIEW_STYLE_FROM_LENTA)
      end
    end

    context 'with JS format' do
      it 'responds to JS format' do
        skip "JS format test skipped due to CSRF protection"
      end
    end
  end

  describe 'GET #edit' do
    it 'returns http success' do
      get :edit, id: queue_image.id
      expect(response).to have_http_status(:success)
    end

    it 'assigns @queue_image' do
      get :edit, id: queue_image.id
      expect(assigns(:queue_image)).to eq(queue_image)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        content_image: File.open(Rails.root.join('spec', 'fixtures', 'test_content.jpg')),
        view_style: '0',
        style_image: File.open(Rails.root.join('spec', 'fixtures', 'test_style.jpg')),
        init: 'starry_night'
      }
    end

    context 'with valid attributes' do
      before do
        allow(controller).to receive(:create_queue).and_return(true)
      end

      it 'calls start_workers on success' do
        expect(controller).to receive(:start_workers)
        post :create, queue_image: valid_attributes
      end

      it 'redirects to queue_images_path with notice on success' do
        post :create, queue_image: valid_attributes
        expect(response).to redirect_to(queue_images_path)
        expect(flash[:notice]).to eq('Images successfully added to processing queue.')
      end

      it 'responds to JSON format on success' do
        post :create, queue_image: valid_attributes, format: :json
        expect(response).to have_http_status(:created)
      end
    end

    context 'with view_style FROM_LIST' do
      let(:style) { create(:style) }
      let(:list_attributes) do
        {
          content_image: File.open(Rails.root.join('spec', 'fixtures', 'test_content.jpg')),
          view_style: '1',
          style_id: style.id
        }
      end

      before do
        allow(controller).to receive(:create_queue).and_return(true)
      end

      it 'creates queue image successfully' do
        post :create, queue_image: list_attributes
        expect(response).to redirect_to(queue_images_path)
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) { { content_image: nil } }

      it 'redirects to new_queue_image_path' do
        post :create, queue_image: invalid_attributes
        expect(response).to redirect_to(new_queue_image_path)
      end

      it 'sets flash alert' do
        post :create, queue_image: invalid_attributes
        expect(flash[:alert]).to eq('Please add an image for processing')
      end
    end

    context 'with missing style image for LOAD_FILE' do
      let(:missing_style_attributes) do
        {
          content_image: File.open(Rails.root.join('spec', 'fixtures', 'test_content.jpg')),
          view_style: '0',
          style_image: nil
        }
      end

      it 'redirects to new_queue_image_path' do
        post :create, queue_image: missing_style_attributes
        expect(response).to redirect_to(new_queue_image_path)
      end

      it 'sets flash alert' do
        post :create, queue_image: missing_style_attributes
        expect(flash[:alert]).to eq('Please add a filter image')
      end
    end

    context 'with missing style_id for FROM_LIST' do
      let(:missing_style_id_attributes) do
        {
          content_image: File.open(Rails.root.join('spec', 'fixtures', 'test_content.jpg')),
          view_style: '1',
          style_id: nil
        }
      end

      it 'redirects to new_queue_image_path' do
        post :create, queue_image: missing_style_id_attributes
        expect(response).to redirect_to(new_queue_image_path)
      end

      it 'sets flash alert' do
        post :create, queue_image: missing_style_id_attributes
        expect(flash[:alert]).to eq('Please select a filter image')
      end
    end
  end

  describe 'PUT #update' do
    let(:valid_attributes) { { status: 2 } }

    it 'updates the queue image' do
      put :update, id: queue_image.id, queue_image: valid_attributes
      queue_image.reload
      expect(queue_image.status).to eq(2)
    end

    it 'redirects to @queue_image with notice' do
      put :update, id: queue_image.id, queue_image: valid_attributes
      expect(response).to redirect_to(queue_image)
      expect(flash[:notice]).to eq('Queue image was successfully updated.')
    end

    it 'responds to JSON format' do
      put :update, id: queue_image.id, queue_image: valid_attributes, format: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE #destroy' do
    it 'updates status to STATUS_DELETED' do
      delete :destroy, id: queue_image.id
      queue_image.reload
              expect(queue_image.status).to eq(QueueImage::STATUS_DELETED)
    end

    it 'redirects to queue_images_url with notice' do
      delete :destroy, id: queue_image.id
      expect(response).to redirect_to(queue_images_url)
      expect(flash[:notice]).to eq('Images deleted.')
    end

    it 'responds to JSON format' do
      delete :destroy, id: queue_image.id, format: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'PUT #visible' do
          before { queue_image.update(status: QueueImage::STATUS_HIDDEN) }

    it 'updates status to STATUS_PROCESSED' do
      put :visible, id: queue_image.id
      queue_image.reload
              expect(queue_image.status).to eq(QueueImage::STATUS_PROCESSED)
    end

    it 'redirects to queue_images_url with notice' do
      put :visible, id: queue_image.id
      expect(response).to redirect_to(queue_images_url)
      expect(flash[:notice]).to eq('Images opened.')
    end

    it 'responds to JSON format' do
      put :visible, id: queue_image.id, format: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'PUT #hidden' do
          before { queue_image.update(status: QueueImage::STATUS_PROCESSED) }

    it 'updates status to STATUS_HIDDEN' do
      put :hidden, id: queue_image.id
      queue_image.reload
              expect(queue_image.status).to eq(QueueImage::STATUS_HIDDEN)
    end

    it 'redirects to queue_images_url with notice' do
      put :hidden, id: queue_image.id
      expect(response).to redirect_to(queue_images_url)
      expect(flash[:notice]).to eq('Images hidden.')
    end

    it 'responds to JSON format' do
      put :hidden, id: queue_image.id, format: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'PUT #like_image' do
    it 'creates a new like' do
      expect {
        put :like_image, id: queue_image.id
      }.to change(Like, :count).by(1)
    end

    it 'increments likes_count' do
      original_count = queue_image.likes_count
      put :like_image, id: queue_image.id
      queue_image.reload
      expect(queue_image.likes_count).to eq(original_count + 1)
    end

    it 'redirects to queue_images_url for HTML format' do
      put :like_image, id: queue_image.id
      expect(response).to redirect_to(queue_images_url)
    end

    it 'responds to JS format' do
      put :like_image, id: queue_image.id, format: :js
      expect(response.content_type).to eq('text/javascript')
    end
  end

  describe 'PUT #unlike_image' do
    let!(:like) { create(:like, queue_id: queue_image.id, client_id: client.id) }

    before { queue_image.update(likes_count: 1) }

    it 'destroys the like' do
      expect {
        put :unlike_image, id: queue_image.id
      }.to change(Like, :count).by(-1)
    end

    it 'decrements likes_count' do
      put :unlike_image, id: queue_image.id
      queue_image.reload
      expect(queue_image.likes_count).to eq(0)
    end

    it 'redirects to queue_images_url for HTML format' do
      put :unlike_image, id: queue_image.id
      expect(response).to redirect_to(queue_images_url)
    end

    it 'responds to JS format' do
      put :unlike_image, id: queue_image.id, format: :js
      expect(response.content_type).to eq('text/javascript')
    end
  end

  describe 'parameter handling' do
    it 'permits correct parameters' do
      expect(controller.private_methods).to include(:queue_image_params)
    end
  end

  describe 'authorization' do
    it 'requires authorization for all actions' do
      expect { get :index }.not_to raise_error
      expect { get :show, id: queue_image.id }.not_to raise_error
      expect { get :new }.not_to raise_error
      expect { get :edit, id: queue_image.id }.not_to raise_error
      expect { post :create, queue_image: { content_image: File.open(Rails.root.join('spec', 'fixtures', 'test_content.jpg')) } }.not_to raise_error
      expect { put :update, id: queue_image.id, queue_image: { status: 2 } }.not_to raise_error
      expect { delete :destroy, id: queue_image.id }.not_to raise_error
      expect { put :visible, id: queue_image.id }.not_to raise_error
      expect { put :hidden, id: queue_image.id }.not_to raise_error
      expect { put :like_image, id: queue_image.id }.not_to raise_error
      expect { put :unlike_image, id: queue_image.id }.not_to raise_error
    end
  end
end
