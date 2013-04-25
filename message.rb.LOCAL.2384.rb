class Integer
    def to_be # int --> [int] --> "packedint"
        [self].pack('N')
    end
end

class String

    def from_be #"packedint" --> [int] --> [int][0] = int
        self.unpack('N')[0]
    end

    def to_x
        self.unpack('H*')[0]
    end

    def from_byte
        self.unpack("C*")[0]
    end
end

class Message

    ID_LIST = [:choke, :unchoke, :interested, :not_interested, :have, :bitfield, :request, :piece, :cancel]

    attr_accessor :id

    def initialize(id, params=nil)
        @id = id
        @params = params
    end

    def to_peer
        case @id
        when :keepalive
            0.to_be
        when :choke, :unchoke, :interested, :not_interested
            1.to_be + ID_LIST.index(@id).chr
        when :have
            5.to_be + ID_LIST.index(@id).chr + @params[:index].to_be
        when :bitfield
            (1+@params[:bitfield].length).to_be + ID_LIST.index[@id].chr + @params[:bitfield]
        when :request, :cancel
            13.to_be + ID_LIST.index[@id].chr + @params[:index].to_be + @params[:begin].to_be + @params[:length].to_be
        when :piece
            (9 + @params[:block].length).to_be + ID_LIST.index[@id].chr + @params[:index].to_be + @params[:begin].to_be + @params[:block]
        end
    end

    def self.from_peer id, info

        start = 0
        inc = 4

        msg = ID_LIST.index(id)

        case msg
        when :choke, :unchoke, :interested, :not_interested
            Message.new(msg)

        when :have
            Message.new(msg, {:index => info[start, inc].from_be})

        when :bitfield
            Message.new(msg, {:bitfield => info}) #from_be??? rm

        when :request, :cancel
            Message.new(msg, {:index => info[start, inc].from_be,
                            :begin => info[start + inc, inc].from_be,
                            :length => info[start + (2 * inc), inc].from_be})
        when :piece
            Message.new(msg, {:index => info[start, inc].from_be,
                            :begin => info[start + inc, inc].from_be})
        else
            return :error
        end
    end
end

# m = Message.new(:request)
# print m.to_peer[2].ord

