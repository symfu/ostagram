# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base
  include DebHelper
  include UploadHelper
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  version :thumb200 do
    process :resize_to_fit => [300, 300]
    process :resize_to_fill => [180, 180]
    process convert: 'jpg'

    def full_filename (for_file)
      # = model.logo.file)
      if (for_file.size == 29) && (for_file.index('img') == 0)
        "thumb200_img.jpg"
      else
        [version_name, for_file].compact.join('_')
      end
    end
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "#{secure_token(10)}.#{file.extension}" if original_filename.present?
  end

  protected

  def secure_token(length = 16)
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) ||
      model.instance_variable_set(var, "img#{Time.now.strftime("%y%m%d%H%M%S")}#{SecureRandom.hex(length / 2)}")
  end

end
