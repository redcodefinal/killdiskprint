require 'nokogiri'
require 'zebra/zpl'
require "fileutils"

module KillDisk
  LOCKFILE_PATH = '/home/user/Desktop/killdiskprint/lockfile.lock'
  XML_LOG_PATH = '/home/user/Desktop/killdisklog/'

  clear_all 

  def self.clear_all
    @@printed_paths = []
    @@devices = {}
    @@barcodes = {}
  end

  def self.lock
    fail if locked?
    File.new(LOCKFILE_PATH, "w+") {|f| f.puts "LOCKED"}
  end

  def self.unlock
    fail unless locked?
    FileUtils.rm(LOCKFILE_PATH)
  end

  def self.locked?
    Dir.exists?(LOCKFILE_PATH)
  end

  def self.single_run(path)
    xml = File.open(path) { |f| Nokogiri::XML(f) }
	  parse xml
  end
  
  def self.batch_run
    files = Dir[xml_log_path + '*.xml']
	  unless files.empty?
      files.each do |path|
        single_run path
      end
    end
  end

  def self.parse(xml)
    xml.xpath("//result").children.each do |disk|
        if disk.name == "disk"
            date = disk.xpath('//started').text
            month = date.split(?/)[1]
            day = date.split(?/)[0]
            date = month + ?/ + day + ?/ + date.split(?/).last
            device = disk.xpath("//device")
            unless device.attr("serial").to_s == ""
                product = device.attr("product").to_s
                revision = device.attr("revision").to_s
                serial = device.attr("serial").to_s
                size = device.attr("size").to_s
                size = size.split('(').first
                @@devices[serial] = {product: product, size: size, revision: revision, date: date} 
            end
        end
    end
    @@printed_paths << path
  end

  def self.move_printed_file(path)
    FileUtils.mv(path, xml_log_path + 'printed/' + path.split(?/).last)
  end

  def self.make_codes
    @@barcodes = {}
    @@devices.each do |serial, data|
      info = 
      """
      product:#{data[:product]},
      serial:#{serial},
      rev:#{data[:revision]},
      size:#{data[:size]}
      """
      @@barcodes[serial] = info
    end
  end

  def self.print_to_zebra
    @@devices.each do |device|

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

        date = Zebra::Zpl::Text.new(
        :data                      => devices[serials[0]][:date],
        :position                  => [100, 20],
        :font_size => Zebra::Zpl::FontSize::SIZE_2
        )
        label << date

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
        print_job = Zebra::PrintJob.new "zebratlp2844z"
        print_job.print(label, '127.0.0.1')
    end
  end


end
