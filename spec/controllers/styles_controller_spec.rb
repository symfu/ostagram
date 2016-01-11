require 'rails_helper'

RSpec.describe StylesController, type: :controller do
  let(:client) { create(:client, :admin) }
  let(:style) { create(:style) }

  before do
    allow(controller).to receive(:current_client).and_return(client)
    allow(controller).to receive(:client_signed_in?).and_return(true)
  end

  describe 'GET #index' do
    let!(:style1) { create(:style, :active) }
    let!(:style2) { create(:style, :processed) }

    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns @styles' do
      get :index
      expect(assigns(:styles)).to be_present
    end
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show, id: style.id
      expect(response).to have_http_status(:success)
    end

    it 'assigns @style' do
      get :show, id: style.id
      expect(assigns(:style)).to eq(style)
    end
  end

  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'assigns @style' do
      get :new
      expect(assigns(:style)).to be_a_new(Style)
    end
  end

  describe 'GET #edit' do
    it 'returns http success' do
      get :edit, id: style.id
      expect(response).to have_http_status(:success)
    end

    it 'assigns @style' do
      get :edit, id: style.id
      expect(assigns(:style)).to eq(style)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) { { image: File.open(Rails.root.join('spec', 'fixtures', 'test_style.jpg')), init: 'starry_night', status: 1 } }

    context 'with valid attributes' do
      it 'assigns @style' do
        post :create, style: valid_attributes
        expect(assigns(:style)).to be_present
      end

      it 'renders new template on success' do
        post :create, style: valid_attributes
        expect(response).to have_http_status(:success)
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) { { image: nil, init: nil } }

      it 'assigns @style' do
        post :create, style: invalid_attributes
        expect(assigns(:style)).to be_present
      end

      it 'renders new template' do
        post :create, style: invalid_attributes
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PUT #update' do
    let(:valid_attributes) { { status: Style::BOT_STYLE_IMAGE } }

    it 'updates the style' do
      put :update, id: style.id, style: valid_attributes
      style.reload
      expect(style.status).to eq(Style::BOT_STYLE_IMAGE)
    end

    it 'redirects to @style with notice' do
      put :update, id: style.id, style: valid_attributes
      expect(response).to redirect_to(style)
      expect(flash[:notice]).to eq('style was successfully updated.')
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the style' do
      style_to_delete = create(:style)
      expect {
        delete :destroy, id: style_to_delete.id
      }.to change(Style, :count).by(-1)
    end

    it 'redirects to styles_url with notice' do
      delete :destroy, id: style.id
      expect(response).to redirect_to(styles_url)
      expect(flash[:notice]).to eq('style was successfully destroyed.')
    end
  end

  describe 'PUT #mark' do
    it 'assigns @mark_style_id' do
      put :mark, id: style.id, format: :js
      expect(assigns(:mark_style_id)).to eq(style.id.to_s)
    end

    it 'responds with js format' do
      put :mark, id: style.id, format: :js
      expect(response.content_type).to eq('text/javascript')
    end
  end

  describe 'parameter handling' do
    it 'permits correct parameters' do
      expect(controller.private_methods).to include(:style_params)
    end
  end
end
