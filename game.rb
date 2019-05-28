require 'pry'
require 'gosu'
require './lib/track'
require './lib/population'

class Game < Gosu::Window
  WIDTH = 900
  HEIGHT = 700

  attr_reader :goal

  def initialize
    super WIDTH, HEIGHT

    start!
  end

  def update
    update_dragging
    update_population
  end

  def draw
    @track.draw
    @population.draw unless dragging?

    draw_fps
    draw_stats
  end

  def button_down(id)
    close if id == Gosu::Button::KbEscape
    start! if id == Gosu::Button::KbR
    change_track! if id == Gosu::Button::KbT
    @population.force_natural_selection if id == Gosu::Button::KbN
    @population.speedup! if id == Gosu::KB_UP
    @population.slowdown! if id == Gosu::KB_DOWN
  end

  def needs_cursor?
    true
  end

  private

  def start!
    @track ||= Track.new
    @population = Population.new(track: @track, count: 100)
    @population.populate!
    @dragging = false
    @was_dragging = false
  end

  def update_dragging
    @was_dragging = dragging?
    @dragging = button_down?(Gosu::MS_LEFT)

    if !@was_dragging && dragging?
      @track.start_drag(self)
    elsif @was_dragging && !dragging?
      @track.end_drag(self)
      start!
    elsif @was_dragging && dragging?
      @track.update_drag(self)
    end
  end

  def update_population
    @population.update
  end

  def change_track!
    @track = Track.new
    start!
  end

  def draw_fps
    draw_text("FPS: #{Gosu.fps}", 5, 5)
    draw_text("Speed: #{@population.speed}x", 5, 20)
  end

  def draw_stats
    height = 5

    [ "Gen: #{@population.number}",
      "Cars: #{@population.count}",
      "Alive: #{@population.cars.count(&:alive?)}",
      "Score: #{@population.cars.map(&:score).max}"
    ].each do |text|
      draw_text(text, nil, height, width: 100, align: :right)
      height += 15
    end
  end

  def draw_text(text, x, y, options = {})
    x = WIDTH - options[:width] - 10 if options[:align] == :right

    Gosu::Image.from_text(text, 15, options).draw(x, y, 0)
  end

  def dragging?
    @dragging == true
  end
end

$game = Game.new
$game.show
