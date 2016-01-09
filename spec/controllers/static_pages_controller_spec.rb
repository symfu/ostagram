require 'rails_helper'

RSpec.describe StaticPagesController, type: :controller do
  let(:client) { create(:client) }
  let(:admin_client) { create(:client, :admin) }

  describe 'GET #home' do
    context 'when client is signed in' do
      before do
        allow(controller).to receive(:client_signed_in?).and_return(true)
        get :home
      end

      it 'redirects to lenta path' do
        expect(response).to redirect_to(lenta_path)
      end
    end

    context 'when client is not signed in' do
      before do
        allow(controller).to receive(:client_signed_in?).and_return(false)
        get :home
      end

      it 'redirects to about path' do
        expect(response).to redirect_to(about_path)
      end
    end
  end

  describe 'GET #lenta' do
    let!(:processed_image1) { create(:queue_image, :processed, client: client, ftime: 2.days.ago) }
    let!(:processed_image2) { create(:queue_image, :processed, client: client, ftime: 1.day.ago) }
    let!(:processed_image3) { create(:queue_image, :processed, client: client, ftime: Time.current) }

    context 'without last_days parameter' do
      before { get :lenta }

      it 'assigns @items with all processed images' do
        expect(assigns(:items)).to include(processed_image1, processed_image2, processed_image3)
      end

      it 'orders by ftime DESC' do
        expect(assigns(:items).first).to eq(processed_image3)
        expect(assigns(:items).last).to eq(processed_image1)
      end

      it 'paginates results' do
        expect(assigns(:items).limit_value).to eq(6)
      end
    end

    context 'with last_days parameter' do
      before { get :lenta, last_days: 1 }

      it 'assigns @items' do
        expect(assigns(:items)).to be_present
      end

      it 'applies last_days filtering' do
        expect(assigns(:items)).to be_a(ActiveRecord::Relation)
      end
    end

    context 'with page parameter' do
      before do
        create_list(:queue_image, 10, :processed, client: client)
        get :lenta, page: 2
      end

      it 'paginates correctly' do
        expect(assigns(:items).current_page).to eq(2)
      end
    end
  end

  describe 'GET #about' do
    before { get :about }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'renders about template' do
      expect(response).to render_template(:about)
    end
  end

  describe 'GET #error' do
    before { get :error }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'renders error template' do
      expect(response).to render_template(:error)
    end
  end

  describe 'protected methods' do
    describe '#process_image' do
      it 'is a protected method' do
        expect(controller.class.protected_instance_methods).to include(:process_image)
      end
    end
  end
end
