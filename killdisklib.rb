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
    fail if Dir.exists?(LOCKFILE_PATH)
    File.new(LOCKFILE_PATH, "w+") {|f| f.puts "LOCKED"}
  end

  def self.unlock
    fail unless Dir.exists?(LOCKFILE_PATH)
    FileUtils.rm(LOCKFILE_PATH)
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
  end

  def self.make_codes
    @@barcodes = {}
    @@devices.each do |serial, data|
      info = "p:#{data[:product]},s:#{serial},r:#{data[:revision]},sz:#{data[:size]}"
      @@barcodes[serial] = info
    end
  end

  def self.print_to_zebra
  end


end
