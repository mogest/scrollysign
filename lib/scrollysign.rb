require 'serialport'

class ScrollySign
  PortClosedError = Class.new(StandardError)

  class TextBuilder
    def initialize
      @text = ""
    end

    def text(text)
      @text << text.to_s
    end

    def control(*controls)
      controls.each do |control|
        @text << ScrollySign::CONTROLS.fetch(control)
      end
    end

    def to_s
      @text
    end
  end

  INITIALISATION_STRING = "\x00" * 5
  SOH = "\x01"
  STX = "\x02"
  EOT = "\x04"
  ESC = "\x1b"

  CONTROLS = {
    "enable_double_high_characters" => "\x051",
    "disable_double_high_characters" => "\x050",
    "enable_true_descenders" => "\x061",
    "disable_true_descenders" => "\x060",
    "enable_character_flash" => "\x071",
    "disable_character_flash" => "\x070",
    "no_hold_speed" => "\x09",
    "new_line" => "\x0d",
    "call_date_mm/dd/yy" => "\x0b0",
    "call_date_dd/mm/yy" => "\x0b1",
    "call_date_mm-dd-yy" => "\x0b2",
    "call_date_dd-mm-yy" => "\x0b3",
    "call_date_mm.dd.yy" => "\x0b4",
    "call_date_dd.mm.yy" => "\x0b5",
    "call_date_mm dd yy" => "\x0b6",
    "call_date_dd mm yy" => "\x0b7",
    "call_date_mmm.dd, yyyy" => "\x0b8",
    "call_date_day_of_week" => "\x0b9",
    "new_page" => "\x0c",
    "new_line" => "\x0d",
    "call_string" => "\x10", # follow by label of string file
    "disable_wide_characters" => "\x11",
    "enable_wide_characters" => "\x12",
    "call_time" => "\x13",
    "call_small_dots_picture" => "\x14", # follow by label of dots picture
    "speed_1" => "\x15", # slowest
    "speed_2" => "\x16",
    "speed_3" => "\x17",
    "speed_4" => "\x18",
    "speed_5" => "\x19",
    "select_character_set" => "\x20", # follow by character set specifier

    "red" => "\x1c1",
    "green" => "\x1c2",
    "amber" => "\x1c3",
    "dim_red" => "\x1c4",
    "dim_green" => "\x1c5",
    "brown" => "\x1c6",
    "orange" => "\x1c7",
    "yellow" => "\x1c8",
    "rainbow_1" => "\x1c9",
    "rainbow_2" => "\x1cA",
    "color_mix" => "\x1cB",
    "autocolor" => "\x1cC",
    "rgb" => "\x1cZ", # alpha 3.0 only: follow by RRGGBB

    "proportional_characters" => "\x1e0",
    "fixed_width_characters" => "\x1e1"
  }

  COMMANDS = {
    "write_text_file" => "A",
    "write_string_file" => "G"
  }

  MODES = {
    "rotate" => 'a',
    "hold" => 'b',
    "flash" => 'c',
    "roll_up" => 'e',
    "roll_down" => 'f',
    "roll_left" => 'g',
    "roll_right" => 'h',
    "wipe_up" => 'i',
    "wipe_down" => 'j',
    "wipe_left" => 'k',
    "wipe_right" => 'l',
    "scroll" => 'm',
    "automode" => 'o',
    "roll_in" => 'p',
    "roll_out" => 'q',
    "wipe_in" => 'r',
    "wipe_out" => 's',
    "compressed_rotate" => 't', # some models only
    "explode" => 'u', # alpha 3.0 only
    "clock" => 'v', # alpha 3.0 only

    "special_twinkle" => 'n0',
    "special_sparkle" => 'n1',
    "special_snow" => 'n2',
    "special_interlock" => 'n3',
    "special_switch" => 'n4',
    "special_slide" => 'n5',
    "special_circle_colors" => 'n5',
    "special_spray" => 'n6',
    "special_starburst" => 'n7',
    "special_welcome" => 'n8',
    "special_slot_machine" => 'n9',
    "special_news_flash" => 'nA', # Betabrite 1036 only
    "special_trumpet_animation" => 'nB', # Betabrite 1036 only
    "special_cycle_colors" => 'nC' # AlphaEclipse 3600 only
  }

  DISPLAY_POSITIONS = {
    "middle_line" => ' ',
    "top_line" => '"',
    "bottom_line" => '&',
    "fill" => '0',
    "left" => '1',
    "right" => '2'
  }

  attr_reader :port
  attr_accessor :type_code, :sign_address

  def initialize(port, baud_rate = 9600)
    @type_code = "Z" # all types of sign
    @sign_address = "00" # all signs

    @port = SerialPort.new(port, baud_rate)
  end

  def self.open(port, baud_rate = 9600)
    sign = new(port, baud_rate)
    begin
      yield sign
    ensure
      sign.close
    end
  end

  def close
    @port.close
    @port = nil
  end

  def c(name)
    CONTROLS.fetch(name)
  end

  def build_text(&block)
    builder = TextBuilder.new
    if block.arity != 1
      builder.instance_eval(&block)
    else
      yield builder
    end
    builder.to_s
  end

  def write_text(text, file_label = "A", mode = nil, display_position = nil)
    data = if mode
      "#{file_label}#{ESC}#{DISPLAY_POSITIONS.fetch((display_position || 'fill').to_s)}#{MODES.fetch(mode.to_s)}#{text}"
    else
      "#{file_label}#{text}"
    end

    write_raw('write_text_file', data)
  end

  def write_string(text, file_label)
    write_raw('write_string_file', "#{file_label}#{text}")
  end

  def write_raw(command, data)
    raise PortClosedError, "port is closed" unless port

    command_code = COMMANDS.fetch(command)

    @port.write "#{INITIALISATION_STRING}#{SOH}#{@type_code}#{@sign_address}#{STX}#{command_code}#{data}#{EOT}"
  end
end
