
# pdf-reader-turtletext methods such as text_in_region, text_position and
# fuzzed_y method modified from the original at https://github.com/tardate/pdf-reader-turtletext
class HocrTurtletext::Reader

  def initialize(hocr_path, options = {})
    @hocr_path = hocr_path
    @options = options
  end

  def content
    hocr_content = File.read(@hocr_path)
    lines = precise_content(hocr_content)
    pos_hash = to_pos_hash(lines)
    fuzzed_y(pos_hash)
  end

  def text_in_region(xmin,xmax,ymin,ymax,inclusive=false)
    return [] unless xmin && xmax && ymin && ymax
    text_map = content
    box = []

    text_map.each do |y,text_row|
      if inclusive ? (y >= ymin && y <= ymax) : (y > ymin && y < ymax)
        row = []
        text_row.each do |x,element|
          if inclusive ? (x >= xmin && x <= xmax) : (x > xmin && x < xmax)
            row << element
          end
        end
        box << row unless row.empty?
      end
    end
    box
  end

  def text_position(text)
    item = if text.class <= Regexp
             content.map do |k,v|
               if x = v.reduce(nil){|memo,vv|  memo = (vv[1] =~ text) ? vv[0] : memo  }
                 [k,x]
               end
             end
           else
             content.map {|k,v| if x = v.rassoc(text) ; [k,x] ; end }
           end
    item = item.compact.flatten
    unless item.empty?
      { :x => item[1], :y => item[0] }
    end
  end

  def bounding_box(&block)
    HocrTurtletext::Textangle.new(self,&block)
  end

  private

  def x_whitespace_threshold
    @options[:x_whitespace_threshold] ||= 30
  end

  def y_precision
    @options[:y_precision] ||= 3
  end

  def fuzzed_y(input)
    output = []
    input.keys.sort.each do |precise_y|
      matching_y = output.map(&:first).select { |new_y| (new_y - precise_y).abs < y_precision }.first || precise_y
      y_index = output.index{ |y| y.first == matching_y }
      new_row_content = input[precise_y].to_a
      if y_index
        row_content = output[y_index].last
        row_content += new_row_content
        output[y_index] = [matching_y,row_content.sort{ |a,b| a.first <=> b.first }]
      else
        output << [matching_y,new_row_content.sort{ |a,b| a.first <=> b.first }]
      end
    end
    output
  end

  def precise_content(hocr_content)
    html = Nokogiri::HTML(hocr_content)
    lines = []
    html.css('span.ocr_line').map do |line|
      chunks = chunks_from_processed_ocr_line(line)
      lines.concat(chunks)
    end
    lines
  end

  def chunks_from_processed_ocr_line(ocr_line)
    pos_info_line = add_positional_info_to_line(ocr_line)
    sorted_pos_info_line = sort_words_in_line(pos_info_line)
    concat_words_in_line(sorted_pos_info_line)
  end

  def add_positional_info_to_line(ocr_line)
    ocr_line.css('span.ocrx_word, span.ocr_word').map do |word|
      word_attributes = word.attributes['title'].value.to_s
                            .delete(';').split(' ')
      info(word, word_attributes)
    end
  end

  def sort_words_in_line(pos_info_line)
    # sort word by x value, concat if x2.x_start - x1.x_end < some_x_threshold
    pos_info_line.sort_by { |word| word[:x_start] }
    pos_info_line.slice_when do |x, y|
      y[:x_start] - x[:x_end] > x_whitespace_threshold
    end.to_a
  end

  def concat_words_in_line(sorted_pos_info_line)
    chunks = []
    # merge all words in each chunk
    sorted_pos_info_line.each do |chunk|
      sentence = nil
      chunk.each do |word|
        if sentence.nil?
          sentence = word
        else
          sentence[:word] = "#{sentence[:word]} #{word[:word]}"
          sentence[:x_end] = word[:x_end]
        end
      end
      chunks.push sentence
    end
    chunks
  end

  def to_pos_hash(lines)
    lines.sort_by { |line| line[:y_start] }

    pos_hash = {}
    lines.each do |run|
      pos_hash[run[:y_start]] ||= {}
      pos_hash[run[:y_start]][run[:x_start]] ||= ''
      pos_hash[run[:y_start]][run[:x_start]] << run[:word]
    end
    pos_hash
  end

  def info(word, data)
    {
        word: word.text,
        x_start: data[1].to_i,
        y_start: data[2].to_i,
        x_end: data[3].to_i,
        y_end: data[4].to_i
    }
  end
end