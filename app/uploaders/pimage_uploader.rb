class PimageUploader < CarrierWave::Uploader::Base
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

  process convert: 'jpg'

  version :thumb400 do
    process :resize_to_fit => [600, 600]
    process :resize_to_fill => [400, 400]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "#{secure_token(10)}.jpg" if original_filename.present?
  end

  protected

  def secure_token(length = 16)
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) ||
      model.instance_variable_set(var, "img#{Time.now.strftime("%y%m%d%H%M%S")}#{SecureRandom.hex(length / 2)}")
  end

end
