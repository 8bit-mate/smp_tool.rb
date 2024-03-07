# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Interface to add/retrieve files to/from a volume.
    #
    class FileInterface
      attr_accessor :filename, :data

      def initialize(filename:, data:)
        @filename = filename
        @data = data
      end

      # Hash-like interface to access keys in the +[]+ syntax.
      def [](key) = send(key)

      # Hash-like interface to access keys in the +[]=+ syntax.
      def []=(key, value)
        send("#{key}=", value)
      end

      # Return `self` as a hash.
      def to_h
        {
          filename: @filename,
          data: @data
        }
      end
    end
  end
end
