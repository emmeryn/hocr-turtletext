# A DSL syntax for text extraction.
# Modified from the original at https://github.com/tardate/pdf-reader-turtletext
class HocrTurtletext::Textangle

  attr_reader :reader

  # +hocr_turtletext_reader+ is a HocrTurtletext::Reader
  def initialize(hocr_turtletext_reader,&block)
    @reader = hocr_turtletext_reader
    @inclusive = false
    if block_given?
      if block.arity == 1
        yield self
      else
        instance_eval &block
      end
    end
  end

  attr_writer :inclusive

  def inclusive(*args)
    if value = args.first
      @inclusive = value
    end
    @inclusive
  end

  # Command: sets +inclusive true
  def inclusive!
    @inclusive = true
  end

  # Command: sets +inclusive false
  def exclusive!
    @inclusive = false
  end

  attr_writer :above
  def above(*args)
    if value = args.first
      @above = value
    end
    @above
  end

  attr_writer :below
  def below(*args)
    if value = args.first
      @below = value
    end
    @below
  end

  attr_writer :left_of
  def left_of(*args)
    if value = args.first
      @left_of = value
    end
    @left_of
  end

  attr_writer :right_of
  def right_of(*args)
    if value = args.first
      @right_of = value
    end
    @right_of
  end

  # Returns the text array found within the defined region.
  # Each line of text is an array of the separate text elements found on that line.
  #   [["first line first text", "first line last text"],["second line text"]]
  def text
    return unless reader

    xmin = if right_of
             if [Integer,Float].include?(right_of.class)
               right_of
             elsif xy = reader.text_position(right_of)
               xy[:x]
             end
           else
             0
           end
    xmax = if left_of
             if [Integer,Float].include?(left_of.class)
               left_of
             elsif xy = reader.text_position(left_of)
               xy[:x]
             end
           else
             99999 # TODO: figure out the actual limit?
           end

    ymax = if above
             if [Integer,Float].include?(above.class)
               above
             elsif xy = reader.text_position(above)
               xy[:y]
             end
           else
             99999
           end
    ymin = if below
             if [Integer,Float].include?(below.class)
               below
             elsif xy = reader.text_position(below)
               xy[:y]
             end
           else
             0 # TODO: figure out the actual limit?
           end

    reader.text_in_region(xmin,xmax,ymin,ymax,inclusive)
  end
end