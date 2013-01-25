require_relative 'bencode.rb'
require_relative 'torrent.rb'
require_relative 'tracker.rb'
require_relative 'peer.rb'
require 'socket'

$version = "HT0001"
$my_id = "" 
$pstr = "BitTorrent protocol"

def generate_my_id 
    return "-"+$version+"-"+"%12d" % rand(999999999999).to_s
end

def parse_config(config_file)
    if File.exist?(config_file)
        encoded =  File.open(config_file, "rb").read.strip
        config = Bencode.decode(encoded)
        $my_id = config['my_id']
        puts $my_id
    elsif config_file == "config"
        puts "Default config file not found."
        $my_id = generate_my_id
        # this will probably eventually be put into an array 
        # with other config options
        File.open(config_file, "wb") do |f|
            f.write($my_id.bencode + "\n")
        end
    elsif
        abort("Error: Config file not found. Exiting.")
    end
end

def print_metadata(torrent)
    torrent.decoded_data.each{ |key, val|
        if key == "info" # info dictionary
            puts "info =>"
            val.each{   |info_key, info_val|
                if info_key == "pieces"
                    puts "\t#{info_val.class()}\t#{info_val.length()}"
                    puts "\tSkipping pieces."
                elsif info_key == "files"
                    puts "\tFiles:"
                    info_val.each{  |file|
                        fn = file['path']
                        flen = file['length']
                        puts "\t\t#{fn}, #{flen} bytes"
                    }
                elsif info_key == "length"
                    puts "\tLength of single file torrent: #{info_val}"
                elsif
                    puts "\t#{info_key} => #{info_val}"
                end
            }
        elsif   #Announce URL and any other metadata
            puts "#{key} => #{val}"
        end
    }
end

#establish a connection
def handshake(peer, info_hash)
    s = TCPSocket.new peer.address, peer.port 
    sock.send "\023"+"BitTorrent protocol"+"\0\0\0\0\0\0\0\0",0
    sock.send info_hash+@my_id
end

if __FILE__ == $PROGRAM_NAME    

    config_file = ".config"
    case ARGV.length
    when 0
        puts "usage: ruby %s [config] torrent-file" % [$PROGRAM_NAME]
        puts "\tby default, config is assumed to be in ./.config"
        exit
    when 1
        torrent_file = ARGV[0]
    when 2
        config_file = ARGV[0]
        torrent_file = ARGV[1]
    end


    puts "======\nhello and welcome"
    puts "to the only bittorrent"
    puts "client we\'ve written\n======"

    puts "\nUsing config file #{config_file}"
    parse_config config_file

    puts "Opening #{torrent_file}:"
    torrent = Torrent.open(torrent_file)
    print_metadata torrent

    if torrent
        # initialize a TrackerHandler object
        options = {:tracker_timeout => 5, :port => 42309}
        handler = Tracker.new(Torrent.open(ARGV[0]), options)
                                   

        # get list of available trackers (as an array)
        trackers = handler.trackers

        # establish connection to tracker from index of a tracker
        # from the above 'trackers' array
        success = handler.establish_connection 0
        connected_tracker = handler.connected_trackers.last

        # send request to a connected tracker
        if success
            puts "SUCCESS"
            response = handler.request( :uploaded => 1, :downloaded => 10,
                      :left => 100, :compact => 0,
                      :no_peer_id => 0, :event => 'started',
                      :index => 0)
        end
    end

#    peerlist = Hash.new(1010)
#    peerlist[""]

    # client should listen on port
    # from these initial states, once the client is interested, 
    # it should set up a handshake

    # have to figure out the proper way to SHA-1 the info key in the torrent
    # put that into initialize?

    # handshake( peerlist["some address"] , torrent.info_hash)
    
    # message format = <length><ID><payload>
# fixed length messages:
# choke: <len=0001><id=0>
# unchoke: <len=0001><id=1>
# interested: <len=0001><id=2>
# not interested: <len=0001><id=3>
# have: <len=0005><id=4><piece index>

# var length:
# bitfield, request, piece, cancel, port
# http://wiki.theory.org/BitTorrentSpecification#Peer_wire_protocol_.28TCP.29
end

