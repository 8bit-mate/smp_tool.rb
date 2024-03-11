# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Volume data entry: permanent file or empty entry.
    #
    class DataEntry
      extend Forwardable

      def_delegators :@header, :status, :filename, :n_clusters, :ch_job, :date, :extra_word,
                     :rename, :permanent_entry?, :empty_entry?, :snapshot, :print_ascii_filename

      attr_reader :header, :data

      def initialize(header:, data:)
        @header = header
        @data = data
      end

      #
      # Resize data string to a new size.
      #
      # @param [Integer] new_size
      #
      # @return [DataEntry] self
      #
      def resize(new_size)
        @header.resize(new_size)

        @data = @data.slice(0, new_size).ljust(new_size, PAD_CHR)

        self
      end

      #
      # Turn `self` into an empty entry.
      #
      def clean
        @header.clean
        @data = @data.gsub(/./m, PAD_CHR)

        self
      end
    end
  end
end
