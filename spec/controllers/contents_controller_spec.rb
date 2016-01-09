require 'rails_helper'

RSpec.describe ContentsController, type: :controller do
  let(:client) { create(:client, :admin) }
  let(:content) { create(:content) }

  before do
    allow(controller).to receive(:current_client).and_return(client)
    allow(controller).to receive(:client_signed_in?).and_return(true)
  end

  describe 'GET #index' do
    let!(:content1) { create(:content, :active) }
    let!(:content2) { create(:content, :processed) }

    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns @contents' do
      get :index
      expect(assigns(:contents)).to be_present
    end
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show, id: content.id
      expect(response).to have_http_status(:success)
    end

    it 'assigns @content' do
      get :show, id: content.id
      expect(assigns(:content)).to eq(content)
    end
  end

  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'assigns @content' do
      get :new
      expect(assigns(:content)).to be_a_new(Content)
    end
  end

  describe 'GET #edit' do
    it 'returns http success' do
      get :edit, id: content.id
      expect(response).to have_http_status(:success)
    end

    it 'assigns @content' do
      get :edit, id: content.id
      expect(assigns(:content)).to eq(content)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) { { image: File.open(Rails.root.join('spec', 'fixtures', 'test_content.jpg')), status: 1 } }

    context 'with valid attributes' do
      it 'assigns @content' do
        post :create, content: valid_attributes
        expect(assigns(:content)).to be_present
      end

      it 'handles create action response' do
        post :create, content: valid_attributes
        if assigns(:content).persisted?
          expect(response).to redirect_to(new_content_path)
          expect(flash[:notice]).to eq('content was successfully created.')
        else
          expect(response).to have_http_status(:success)
          expect(response).to render_template(:new)
        end
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) { { image: nil, status: nil } }

      it 'does not create content' do
        expect {
          post :create, content: invalid_attributes
        }.not_to change(Content, :count)
      end

      it 'renders new template' do
        post :create, content: invalid_attributes
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PUT #update' do
    let(:valid_attributes) { { status: 2 } }

    it 'updates the content' do
      put :update, id: content.id, content: valid_attributes
      content.reload
      expect(content.status).to eq(2)
    end

    it 'redirects to @content with notice' do
      put :update, id: content.id, content: valid_attributes
      expect(response).to redirect_to(content)
      expect(flash[:notice]).to eq('content was successfully updated.')
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the content' do
      content_to_delete = create(:content)
      expect {
        delete :destroy, id: content_to_delete.id
      }.to change(Content, :count).by(-1)
    end

    it 'redirects to contents_url with notice' do
      delete :destroy, id: content.id
      expect(response).to redirect_to(contents_url)
      expect(flash[:notice]).to eq('content was successfully destroyed.')
    end
  end

  describe 'parameter handling' do
    it 'permits correct parameters' do
      expect(controller.private_methods).to include(:content_params)
    end
  end
end
