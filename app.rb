#! /usr/bin/env ruby

require 'nokogiri'
require 'zebra/zpl'

# Go to report folder, find most recent report
doc = File.open(ARGV[0]) { |f| Nokogiri::XML(f) }
@devices = {}
doc.xpath("//devices").children.each do |device|
  unless device.attr("serial").to_s == ""
    product = device.attr("product").to_s
    revision = device.attr("revision").to_s
    serial = device.attr("serial").to_s
    size = device.attr("size").to_s
    size = size.split('(').first
    @devices[serial] = {product: product, size: size, revision: revision} 
  end
end
# Put info into barcode
@qr_labels = {}
@devices.each do |serial, data|
  info = "p:#{data[:product]},s:#{serial},r:#{data[:revision]},sz:#{data[:size]}"
  @qr_labels[serial] = info
end
# Format barcode with human readable label

@devices.keys.each_slice(2) do |serials|
  
  label = Zebra::Zpl::Label.new(
    :width => 1000,
    :height => 500,
    :print_speed   => 3,
    :print_density => 3
  )

  text = Zebra::Zpl::Text.new(
    :data                      => serials[0],
    :position                  => [100, 0],
    :font_size => Zebra::Zpl::FontSize::SIZE_2
  )
  label << text

  barcode = Zebra::Zpl::Barcode.new(
    :data                      => @qr_labels[serials[0]],
    :position                  => [100, 50],
    :height                    => 40,
    :print_human_readable_code => true,
    :narrow_bar_width          => 2,
    :wide_bar_width            => 2,
    :type                      => Zebra::Zpl::BarcodeType::CODE_AZTEC
  )

  label << barcode
  if serials.length == 2
  text2 = Zebra::Zpl::Text.new(
    :data                      => serials[1],
    :position                  => [500, 0],
    :font_size => Zebra::Zpl::FontSize::SIZE_2
  )
  label << text2

  barcode2 = Zebra::Zpl::Barcode.new(
    :data                      => @qr_labels[serials[1]],
    :position                  => [500, 50],
    :height                    => 40,
    :print_human_readable_code => true,
    :narrow_bar_width          => 2,
    :wide_bar_width            => 2,
    :type                      => Zebra::Zpl::BarcodeType::CODE_AZTEC
  )

  label << barcode2
  end

  print_job = Zebra::PrintJob.new "zebratlp2844z"

  print_job.print(label, '127.0.0.1')
end



