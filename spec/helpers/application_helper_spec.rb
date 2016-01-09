require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#full_title' do
    context 'when page title is empty' do
      it 'returns only the base title' do
        expect(helper.full_title('')).to eq('Ostagram')
      end
    end

    context 'when page title is provided' do
      it 'returns base title with page title separated by pipe' do
        expect(helper.full_title('Home')).to eq('Ostagram | Home')
      end

      it 'handles single character page title' do
        expect(helper.full_title('A')).to eq('Ostagram | A')
      end

      it 'handles long page title' do
        long_title = 'This is a very long page title that should still work correctly'
        expect(helper.full_title(long_title)).to eq("Ostagram | #{long_title}")
      end

      it 'handles special characters in page title' do
        expect(helper.full_title('User Profile & Settings')).to eq('Ostagram | User Profile & Settings')
      end

      it 'handles numbers in page title' do
        expect(helper.full_title('Page 123')).to eq('Ostagram | Page 123')
      end

      it 'handles empty string with spaces' do
        expect(helper.full_title('   ')).to eq('Ostagram |    ')
      end
    end

    context 'when page title is nil' do
      it 'raises NoMethodError for empty? method' do
        expect { helper.full_title(nil) }.to raise_error(NoMethodError)
      end
    end

    context 'when page title is false' do
      it 'raises NoMethodError for empty? method' do
        expect { helper.full_title(false) }.to raise_error(NoMethodError)
      end
    end

    context 'when page title is numeric' do
      it 'raises NoMethodError for empty? method' do
        expect { helper.full_title(0) }.to raise_error(NoMethodError)
      end
    end
  end
end
