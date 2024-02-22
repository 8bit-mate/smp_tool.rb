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

  # Read a full volume, check the number of files.
  # BASIC 1.0 ver.
  def test_read_volume_bas10
    io = read_bin_file("./data/read/basic_10/full_volume_121_bas_10.bin")
    n_files = SMPTool::VolumeIO::RawVolume.read(io).snapshot.data.length

    assert_equal 121, n_files
  end

  # Read a full volume, check the number of files.
  # BASIC 2.0 ver.
  def test_read_volume_bas20
    io = read_bin_file("./data/read/basic_20/full_volume_121_bas_20.bin")
    n_files = SMPTool::VolumeIO::RawVolume.read(io).snapshot.data.length

    assert_equal 121, n_files
  end

  def test_read_micro_vol_bas10
    io = read_bin_file("./data/read/basic_10/micro_bas_10.bin")
    SMPTool::VirtualVolume::Utils::ConverterFromRawVolume.read_io(io)
  end

  def test_virtual_volume_read_bas10
    io = read_bin_file("./data/read/basic_10/full_volume_121_bas_10.bin")

    orig_vol = SMPTool::VolumeIO::RawVolume.read(io)
    conv_vol = SMPTool::VirtualVolume::Utils::ConverterFromRawVolume.read_raw_volume(orig_vol).to_raw_volume

    assert_equal orig_vol.to_binary_s, conv_vol.to_binary_s
  end

  def test_file_converter_to_data_entry_arr
    SMPTool::VirtualVolume::Utils::FileConverter.hash_arr_to_data_entry_arr(
      [{
        filename: [0x000A, 0x000B, 0x000C],
        data: ["10 PRINT \"Привет, Мир!\""]
      }],
      0
    )
  end

  def test_file_push
    io = read_bin_file("./data/read/basic_10/micro_bas_10.bin")

    vol = SMPTool::VirtualVolume::Utils::ConverterFromRawVolume.read_io(io)

    vol.f_delete("DIZZY BAS")

    vol.inspect

    vol.f_push(
      {
        filename: [0x000A, 0x000B, 0x000C],
        data: ["10 PRINT \"Привет, Мир!\""]
      }
    )

    vol.inspect
  end
end
