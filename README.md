# smp_tool

A Ruby library to work with the Elektronika MK90 volume images. There's a command-line interface: [smp_tool-cli](https://github.com/8bit-mate/smp_tool-cli.rb).

## Installation

Add this line to your application"s Gemfile:

```ruby
gem "smp_tool"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install smp_tool

## Usage

### Example

Create a new empty volume:

```Ruby
require "smp_tool"

params = SMPTool::VirtualVolume::VolumeParams.new(
  n_clusters_allocated: 20,
  n_extra_bytes_per_entry: 0,
  n_dir_segs: 1,
  n_clusters_per_dir_seg: 2,
  extra_word: 0
)

volume = SMPTool::VirtualVolume::Volume.new(
  bootloader: SMPTool::Basic10::DEFAULT_BOOTLOADER,
  home_block: SMPTool::Basic10::HOME_BLOCK,
  volume_params: params
)
```

Or read an existing volume from a file:

```Ruby
io = File.read("/path/to/volume/smp0.bin")
volume = SMPTool::VirtualVolume::Volume.read_io(io)
```

Now you can perform operations on the `volume` object, e.g.:

```Ruby
# Push a text file to the volume:
volume.f_push(
  {
    filename: "hello.bas",
    data: ["10 PRINT \"Hello, world\"", "20 GOTO 10"]
  }
)

# Extract a file by its filename:
volume.f_extract_txt("hello.bas")

# Delete a file from the volume:
volume.f_delete("hello.bas")

# Consolidate all free space at the end of the volume:
volume.squeeze

# Rename a file on the volume:
volume.f_rename("old.bas", "new.bas")

# Allocate more free clusters to the volume:
volume.resize(10)

# ...or trim some free clusters:
volume.resize(-5)
```

When done, you can write modified volume back to a binary file:

```Ruby
data = volume.to_binary_s
File.binwrite("/path/to/volume/smp0_edited.bin", data)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/8bit-mate/smp_tool.rb.

## Special thanks to

- **[Piotr Piatek](http://www.pisi.com.pl/piotr433/index.htm)**: the indisputable master of the MK90 who developed lots of great software tools and hardware devices for the machine;

- **[azya52](https://github.com/azya52/)**: developer of the PIMP cartridge. This device made possible to load large volumes on a real MK90;

- **[flint-1979](https://phantom.sannata.org/memberlist.php?mode=viewprofile&u=6909)**: testing on the real machines with both BASIC v.1.0 and v.2.0;

- **[BitSavers project](http://www.bitsavers.org/)**: the largest source of the DEC PDP-11 / RT-11 and other legacy systems documentation.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
