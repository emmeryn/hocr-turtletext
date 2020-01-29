
# pdf-reader-turtletext methods such as text_in_region, text_position and
# fuzzed_y method modified from the original at https://github.com/tardate/pdf-reader-turtletext
class HocrTurtletext::Reader

  def initialize(hocr_path, options = {})
    @hocr_path = hocr_path
    @options = options
  end

  def content
    hocr_content = File.read(@hocr_path)
    html = Nokogiri::HTML(hocr_content)
    pos_info_words = extract_words_from_html(html)
    pos_hash = to_pos_hash pos_info_words
    fuzzed_y = fuzzed_y(pos_hash)
    concat_words_in_lines(fuzzed_y)
  end

  def text_in_region(xmin, xmax, ymin, ymax, inclusive=false)
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
               if x = v.reduce(nil){ |memo,vv|  memo = (vv[1] =~ text) ? vv[0] : memo }
                 [k,x]
               end
             end
           else
             content.map { |k,v| if x = v.rassoc(text) ; [k,x] ; end }
           end
    item = item.compact.flatten
    unless item.empty?
      { :x => item[1], :y => item[0] }
    end
  end

  def bounding_box(&block)
    HocrTurtletext::Textangle.new(self, &block)
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
      matching_y = output.map(&:first)
                         .select { |new_y| (new_y - precise_y).abs < y_precision }
                         .first || precise_y
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

  def concat_words_in_lines(fuzzed_y)
    fuzzed_y.map do |line|
      x_pos_keyed_words = line[1]
      concatenated_words = []
      x_pos_keyed_words.each do |x_pos_keyed_word|
        word_hash = x_pos_keyed_word[1]
        if concatenated_words.empty? ||
           word_hash[:x_start] - concatenated_words.last[:x_end] > x_whitespace_threshold
          concatenated_words.push word_hash
        else
          concatenated_words.last[:word] = "#{concatenated_words.last[:word]} #{word_hash[:word]}"
          concatenated_words.last[:x_end] = word_hash[:x_end]
        end
      end
      line[1] = concatenated_words.map! do |word_hash|
        [word_hash[:x_start], word_hash[:word]]
      end
      line
    end
  end

  def extract_words_from_html(html)
    pos_info_words = []

    html.css('span.ocrx_word, span.ocr_word')
        .reject { |word| word.text.strip.empty? }
        .each do |word|
      word_attributes = word.attributes['title'].value.to_s
                            .delete(';').split(' ')
      pos_info_word = word_info(word, word_attributes)
      pos_info_words.push pos_info_word
    end
    pos_info_words
  end

  def to_pos_hash(lines)
    lines.sort_by { |line| line[:y_start] }

    pos_hash = {}
    lines.each do |run|
      pos_hash[run[:y_start]] ||= {}
      pos_hash[run[:y_start]][run[:x_start]] = run
    end
    pos_hash
  end

  def word_info(word, data)
    {
      word: word.text,
      x_start: data[1].to_i,
      y_start: data[2].to_i,
      x_end: data[3].to_i,
      y_end: data[4].to_i
    }
  end
end