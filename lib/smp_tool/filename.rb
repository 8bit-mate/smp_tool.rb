# frozen_string_literal: true

module SMPTool
  #
  # Converts RADIX-50 <-> ASCII filenames.
  #
  class Filename
    attr_reader :radix50, :ascii

    ASCII_LENGTH = 9  # Characters.
    RADIX_LENGTH = 3  # 16-bit words.
    ASCII_DOT_POS = 6 # Dot position in the printable ASCII filename.
    SEP_CHR = "•"     # Separation character.

    def initialize(options = {})
      _validate_options(options)

      if options.key?(:radix50)
        _handle_radix_input(options)
      elsif options.key?(:ascii)
        _handle_ascii_input(options)
      else
        raise ArgumentError, "Either :radix50 or :ascii must be provided"
      end

      _make_ascii_name
    end

    #
    # ASCII filename with a dot to separate extension.
    #
    def print_ascii
      @ascii.insert(ASCII_DOT_POS, SEP_CHR).delete(" ")
    end

    private

    def _validate_options(options)
      return unless options.key?(:radix50) && options.key?(:ascii)

      raise ArgumentError, ":radix50 and :ascii are mutually exclusive"
    end

    def _make_ascii_name
      @ascii = DECRadix50.decode(DECRadix50::MK90_CHARSET, @radix50)
    end

    def _handle_radix_input(options)
      @radix50 = _enforce_radix(options[:radix50])
    end

    def _handle_ascii_input(options)
      @radix50 = DECRadix50.encode(
        DECRadix50::MK90_CHARSET, _enforce_ascii(options[:ascii])
      )
    end

    def _enforce_ascii(str)
      str.slice(0, ASCII_LENGTH).ljust(ASCII_LENGTH).upcase
    end

    def _enforce_radix(arr)
      arr.slice(0, RADIX_LENGTH).fill(0, arr.length...RADIX_LENGTH)
    end
  end
end
