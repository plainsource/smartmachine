require 'socket'

module Wiredrop
  class Peer
    def initialize(port:, directory:, allowed_ips:, endpoint:)
      @port = port
      @directory = directory
      @allowed_ips = allowed_ips
      @endpoint = endpoint
      @peers = {} # @peers = { 'identity' => { hostname: '', port: '', endpoint: '', directory: '' } }
      @files = {} # Pieces, piece hashes, piece order
    end

    def up
      server
    end

    private

    def server
      server = TCPServer.open @port
      loop do
        Thread.start(server.accept) do |client|
          client.puts "Hello !"
          client.puts "Time is #{Time.now}"
          # message = client.gets
          # client.puts "#{message} - from server"
          # peer(@peers[0])
          client.close
        end
      end
    end

    def peer(hostname:, port:)
      # hostname = 'terminalone.timeboard.local/frontend/wiredrop/peer'
      socket = TCPSocket.open hostname, port
      while (line = socket.gets)
        puts line
      end
      socket.close
    end
  end
end

# wiredrop

# peer
#   IP Address & Port
#   Last Known Endpoint
#   Allowed IPs
#   Directory
#   Tracker

# Files List
#   Filepaths
#   Filehashes

# Pieces
#   Break all data to be sent into small chunks
#   Send Packets/Messages
#   Receive Packets/Messages
