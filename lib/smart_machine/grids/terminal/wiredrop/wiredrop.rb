#!/usr/bin/env ruby

require 'daemons'
require_relative 'peer'

Daemons.run_proc 'wiredrop' do
  peer = Wiredrop::Peer.new(port: 2000, allowed_ips: [], directory: '', endpoint: '')
  peer.up
end
