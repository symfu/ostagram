require 'rails_helper'

RSpec.describe UploadHelper do
  let(:dummy_class) { Class.new { include UploadHelper } }
  let(:helper_instance) { dummy_class.new }

  describe '#new_file_name' do
    context 'when called multiple times' do
      it 'generates unique file names with timestamp' do
        first_name = helper_instance.new_file_name
        sleep(1)
        second_name = helper_instance.new_file_name
        
        expect(first_name).to match(/^img\d{12}$/)
        expect(second_name).to match(/^img\d{12}$/)
        expect(first_name).not_to eq(second_name)
      end
    end

    context 'when called in rapid succession' do
      it 'generates same names when called within same second' do
        names = []
        5.times do
          names << helper_instance.new_file_name
        end
        
        expect(names.uniq.length).to eq(1)
        names.each do |name|
          expect(name).to match(/^img\d{12}$/)
        end
      end
    end

    context 'format validation' do
      it 'generates name with correct format' do
        name = helper_instance.new_file_name
        
        expect(name).to start_with('img')
        expect(name.length).to eq(15)
        expect(name[3..-1]).to match(/^\d{12}$/)
      end
    end

    context 'timestamp accuracy' do
      it 'uses current time for filename generation' do
        before_time = Time.now
        name = helper_instance.new_file_name
        after_time = Time.now
        
        timestamp_part = name[3..-1]
        generated_time = Time.strptime(timestamp_part, '%y%m%d%H%M%S')
        
        expect(generated_time).to be_between(before_time - 1, after_time + 1)
      end
    end

    context 'timestamp format' do
      it 'uses correct timestamp format' do
        name = helper_instance.new_file_name
        timestamp_part = name[3..-1]
        
        expect(timestamp_part.length).to eq(12)
        expect(timestamp_part).to match(/^\d{12}$/)
        
        year = timestamp_part[0..1].to_i
        month = timestamp_part[2..3].to_i
        day = timestamp_part[4..5].to_i
        hour = timestamp_part[6..7].to_i
        minute = timestamp_part[8..9].to_i
        second = timestamp_part[10..11].to_i
        
        expect(year).to be_between(0, 99)
        expect(month).to be_between(1, 12)
        expect(day).to be_between(1, 31)
        expect(hour).to be_between(0, 23)
        expect(minute).to be_between(0, 59)
        expect(second).to be_between(0, 59)
      end
    end
  end
end
