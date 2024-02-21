# frozen_string_literal: true

module SMPTool
  module VolumeIO
    #
    # A single directory entry.
    #
    class DirEntry < BinData::Record
      endian :little

      virtual :ascii_filename, value: -> { _radix_to_ascii(filename) }, onlyif: -> { status != DIR_SEG_FOOTER }

      # Status word: empty area/permanent file/end-of-segment:
      uint16le :status

      # RADIX-50 filename (6 bytes):
      array :filename, onlyif: -> { status != DIR_SEG_FOOTER }, initial_length: RAD50_FN_SIZE do
        uint16le initial_value: PAD_WORD
      end

      # Number of clusters occupied by the file:
      uint16le :n_clusters, onlyif: -> { status != DIR_SEG_FOOTER }

      # Job & channel, unused in the MK90:
      uint16le :ch_job, onlyif: -> { status != DIR_SEG_FOOTER }, initial_value: DEF_CH_JOB

      # Creation date, unused in the MK90:
      uint16le :date, onlyif: -> { status != DIR_SEG_FOOTER }, initial_value: DEF_DATE

      # Extra word is unused in the BASIC v.1.0, but it is required in the BASIC v.2.0.
      # The use in the v.2.0 is unknown, probably it was reserved for a checksum.
      # BASIC v.2.0 always sets it to 0x00A0.
      uint16le :extra_word,
               initial_value: EXTRA_WORD_NONE,
               onlyif: lambda {
                         status != DIR_SEG_FOOTER && header.n_extra_bytes_per_entry.positive?
                       }

      private

      def _radix_to_ascii(int_arr)
        DECRadix50.decode(DECRadix50::MK90_CHARSET, int_arr)
      end
    end
  end
end
