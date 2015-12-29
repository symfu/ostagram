# encoding: utf-8

class AvatarUploader < CarrierWave::Uploader::Base
  include DebHelper
  include CarrierWave::MiniMagick

  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  version :to_proc, :if => :is_content_style_image? do
    process :resize_to_fit => [1500, 1500]
    process :resize_to_fill => [1000, 1000]
  end

  version :thumb200, :if => :is_content_style_image? do
    process :resize_to_fit => [300, 300]
    process :resize_to_fill => [180, 180]
  end

  version :thumb400, :if => :is_processed_image? do
    process :resize_to_fit => [600, 600]
    process :resize_to_fill => [400, 400]
  end

  version :avatar50, :if => false do
    process :resize_to_fit => [80, 80]
    process :resize_to_fill => [46, 46]
    process :round => [2]
  end

  version :avatar100, :if => :is_user_avatar? do
    process :resize_to_fit => [150, 150]
    process :resize_to_fill => [100, 100]
    process :round => [2]
  end

  def is_processed_image? picture
    model.class.to_s.underscore == "pimage"
  end

  def is_content_style_image? picture
    model.class.to_s.underscore == "content" || model.class.to_s.underscore == "style"
  end

  def is_user_avatar? picture
    model.class.to_s.underscore == "client"
  end

  def is_content_image? picture
    model.class.to_s.underscore == "content"
  end

  def is_style_image? picture
    model.class.to_s.underscore == "style"
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "img.#{original_filename.split('.').last}" if original_filename
  end

  def rounded_corners
    radius = 10
    manipulate! do |img|
      masq = Magick::Image.new(img.columns, img.rows)
      d = Magick::Draw.new
      d.roundrectangle(0, 0, img.columns - 1, img.rows - 1, radius, radius)
      d.draw(masq)
      img.composite(masq, 0, 0, Magick::LightenCompositeOp)
    end
  end

  def round(rad = 6)
    manipulate! do |img|
      img.format 'png'

      width = img[:width] - 2
      radius = width / rad

      mask = ::MiniMagick::Image.open img.path
      mask.format 'png'

      mask.combine_options do |m|
        m.alpha 'transparent'
        m.background 'none'
        m.fill 'white'
        m.draw 'roundrectangle 1,1,%s,%s,%s,%s' % [width, width, radius, radius]
      end

      overlay = ::MiniMagick::Image.open img.path
      overlay.format 'png'

      overlay.combine_options do |o|
        o.alpha 'transparent'
        o.background 'none'
        o.fill 'none'
        o.stroke 'white'
        o.strokewidth 2
        o.draw 'roundrectangle 1,1,%s,%s,%s,%s' % [width, width, radius, radius]
      end

      masked = img.composite(mask, 'png') do |i|
        i.alpha "set"
        i.compose 'DstIn'
      end

      masked.composite(overlay, 'png') do |i|
        i.compose 'Over'
      end
    end
  end

  def round_corner(radius = 10)
    round_command = ""
    round_command << '\( +clone -alpha extract '
    round_command << "-draw 'fill black polygon 0,0 0,#{radius} #{radius},0 fill white circle #{radius},#{radius} #{radius},0' "
    round_command << '\( +clone -flip \) -compose Multiply -composite '
    round_command << '\( +clone -flop \) -compose Multiply -composite \) '
    round_command << '-alpha off -compose CopyOpacity -composite'
    manipulate! do |image|
      image.format 'png'
      image.combine_options do |command|
        command << round_command
      end

      image
    end
  end

  def draw_border
    manipulate! do |image|
      image.combine_options do |c|
        c.mattecolor "Blue"
        c.frame "2x2"
      end

      image
    end
  end

  def move_to_cach
    false
  end

end
