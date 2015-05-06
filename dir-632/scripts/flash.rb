#!/usr/bin/env ruby
# Copyright (C) 2011 CASPUR (wifi@caspur.it)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# This script will help you flashing D-LINK DIR-825 devices 'cause  they can be flashed only with IE7
# Your ETH Address must be 192.168.0.100/24

require 'socket'

HOST = "192.168.0.1"
PATH = "/cgi/index"

if ARGV.count == 0
  puts "Usage #{$0} <filename>"
  exit 1
else
  filename = ARGV[0]
  puts "[#{Time.now}] Using firmware file '#{filename}'"
end

predata = <<-eopd
-----------------------------7db12928202b8
Content-Disposition: form-data; name="files"; filename="#{filename}"
Content-Type: application/octet-stream

eopd

firmware = File.open(filename, "rb") { |io| io.read }

postdata="\x0d\x0a-----------------------------7db12928202b8--\x0d\x0a"

# Each line must end with cr/lf characters, and we have to know how many 
# data the script will send to the dir-825 this is why we concatenate it before
# creating the header

buffer = predata.gsub(/\n/,"\x0d\x0a") + firmware + postdata

header = <<-eoh
POST #{PATH} HTTP/1.1
Accept: image/jpeg, application/x-ms-application, image/gif, application/xaml+xml, image/pjpeg, application/x-ms-xbap, */*
Referer: http://#{HOST}/
Accept-Language: it-IT
User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0)
Content-Type: multipart/form-data; boundary=---------------------------7db12928202b8
Accept-Encoding: gzip, deflate
Host: #{HOST}
Content-Length: #{buffer.length}
Connection: Keep-Alive
Cache-Control: no-cache

eoh

begin
  puts "[#{Time.now}] Firmware file laded (#{firmware.length} bytes)"
  http = TCPSocket.new(HOST, 'www')

  puts "[#{Time.now}] Sending firmware to the device...  "

  http.print header.gsub(/\n/,"\x0d\x0a") + buffer
  resp = http.recv(1012)

  # Let's check if it's all ok
  if resp.match /Don't turn the device off before the Upgrade jobs done/
     puts "\n[#{Time.now}] Finished. Please wait for the device to reboot."
  else
     puts "\n[#{Time.now}] Problem sending firmware to the device. Response from device follows."
     puts resp
   end

  http.close
  rescue Exception => e
  puts "[#{Time.now}] Problem flashing device. Error: '#{e}'"
end

exit 0
