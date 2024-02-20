# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Volume data entry: permanent file or empty entry.
    #
    class DataEntry
      extend Forwardable

      def_delegators :@header, :status, :filename, :n_clusters, :ch_job, :date, :extra_word,
                     :rename

      attr_reader :header, :data

      def initialize(header:, data:)
        @header = header
        @data = data
      end

      #
      # Turn `self` into an empty entry.
      #
      def clean
        @header.make_empty.clean_filename
        @data = @data.gsub(/./m, PAD_BYTE.chr)

        self
      end
    end
  end
end
