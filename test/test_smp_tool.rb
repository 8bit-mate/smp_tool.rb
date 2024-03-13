# frozen_string_literal: true

require_relative "test_helper"

class TestSMPTool < Minitest::Test
  def read_bin_file(path)
    File.read(Pathname(__dir__).join(path).to_s)
  end

  def io_to_a(io)
    io.unpack("H2" * io.length).map(&:hex)
  end

  def test_that_it_has_a_version_number
    refute_nil ::SMPTool::VERSION
  end
end
