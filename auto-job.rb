#! /usr/bin/env ruby

require 'nokogiri'
require 'zebra/zpl'
require "fileutils"
require "./killdisklib"

xml_log_path = '/home/user/Desktop/killdisklog/'
printed_paths = []
devices = {}

unless Dir.exists?(lockfile_path)
	KillDisk.lock

	files = Dir[xml_log_path + '*.xml']
	unless files.empty?
		files.each do |path|
			doc = File.open(path) { |f| Nokogiri::XML(f) }
			KillDisk.parse doc
			printed_paths << path
		end
		# Put info into barcode
		KillDisk.make_codes
		# Format barcode with human readable label
		KillDisk.print_to_zebra

		# Move file out of folder into printed
		printed_paths.each do |path|
			FileUtils.mv(path, xml_log_path + 'printed/' + path.split(?/).last)
		end
		end
	end
	# DELETE LOCK FILE
	FileUtils.rm(lockfile_path)
end




