# frozen_string_literal: true

require 'mini_magick'
require 'nokogiri'
require 'tempfile'

require_relative 'twemoji/twemoji'
require_relative '../helpers/object'

# Defines an custom-built emoji
class CustomEmoji
  def initialize(params)
    @params = params
    @time = @params[:time]

    @size = @params[:size]
    @xml_template = xml_template

    @base_emoji_id = @params[:emoji_id]
    @twemoji_version = Twemoji.validate_version(@params[:twemoji_version])
  end

  def validate_emoji_input(input, find_class)
    return false if input == 'false'

    message = "Emoji is not supported: #{input}"
    input.downcase!

    if input[0..1] == 'u+'
      input = input[2..]
    elsif input.scan(Unicode::Emoji::REGEX).length == 1
      # Source: https://dev.to/ohbarye/convert-emoji-and-codepoints-each-other-in-ruby-27j
      input = input.each_codepoint.map { |n| n.to_s(16) }
      input = input.join('-') if input.is_a?(Array)
    end

    if find_class.find(input, @twemoji_version).nil?
      input = input.to_i(16)
      raise message if find_class.find(input, @twemoji_version).nil?
    end

    input
  end

  def svg
    svg = Tempfile.new([to_s, '.svg'], 'tmp')

    File.open(svg.path, 'w') do |f|
      f.write(@xml)
    end

    svg
  end

  def png
    png_file = Tempfile.new([to_s, '.png'], 'tmp')
    svg_file = svg

    convert_svg_to_png(svg_file.path, png_file.path)
    contents = png_file.read

    png_file.unlink
    svg_file.unlink

    contents
  end

  private

  def xml_template
    xml = File.open('assets/template.svg') { |f| Nokogiri::XML(f) }.at(:svg)
    unless @size.nil?
      xml.attributes['width'].value = "#{@size}px"
      xml.attributes['height'].value = "#{@size}px"
    end

    xml
  end

  # Create a PNG file out of an SVG file
  def convert_svg_to_png(svg_filepath, png_filepath)
    size = @size.presence || 128
    MiniMagick::Tool::Convert.new do |convert|
      convert.background('none')
      convert.size("#{size}x#{size}")
      convert << svg_filepath
      convert << png_filepath
    end
  end
end
