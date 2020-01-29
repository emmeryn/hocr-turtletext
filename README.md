# HocrTurtletext

Heavily inspired by [PDF::Reader::Turtletext](https://github.com/tardate/pdf-reader-turtletext), HocrTurtletext provides convenient methods to extract content from a hOCR file. hOCR output is commonly produced by OCR software such as tesseract-ocr.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hocr_turtletext'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hocr_turtletext

## Usage

### Instantiate HocrTurtletext

Typical usage: 
```ruby
hocr_path = '/tmp/page1.hocr'
options = { :y_precision => 7 }
reader = HocrTurtletext::Reader.new(hocr_path, options)
```

Options:  
`x_whitespace_threshold`: Words with a x distance of less than this threshold will be concatenated with a space. Try increasing this value if words/letters that are supposed to belong together are separated.   
`y_precision`: Different rows of text with y positions that are less than y_precision of difference will be put together into one row. Try increasing this value if words that are supposed to be on the same row are detected as separate rows.

### Extract text within a region described in relation to other text

This method works nearly identically to its counterpart from PDF::Reader::Turtletext. 
The main difference is that we are not dealing with multiple pages in our hOCR input, so
there is no need to support page selection.

Given that we know the text we want to find is relatively positioned (for example)
below a certain bit of text, to the left of another, and above some other text, use 
the `bounding_box` method to describe the region and extract the matching text.
```
  textangle = reader.bounding_box do
    below /electricity/i
    above 10
    right_of 240.0
    left_of "Total ($)"
  end
  textangle.text
  => [['string','string'],['string']] # array of rows, each row is an array of text elements in the row
```

The range of methods that can be used within the `bounding_box` block are all optional, and include:
- `inclusive` - whether region selection should be inclusive or exclusive of the specified positions
  (default is false).
- `below` - a string, regex or number that describes the upper limit of the text box
  (default is top border of the page)`.
- `above` - a string, regex or number that describes the lower limit of the text box
  (default is bottom border of the page).
- `left_of` - a string, regex or number that describes the right limit of the text box
  (default is right border of the page).
- `right_of` - a string, regex or number that describes the left limit of the text box
  (default is left border of the page).

Note that `left_of` and `right_of` constraints do *not* need to be within the vertical
range of the box being described.
For example, you could use an element in the page header to describe the `left_of` limit
for a table at the bottom of the page, if it has the correct alignment needed to describe your text region.

Similarly, `above` and `below` constraints do *not* need to be within the horizontal
range of the box being described.

### Using a block parameter with the `bounding_box` method

An explicit block parameter may be used with the `bounding_box` method:
```
  textangle = reader.bounding_box do |r|
    r.below /electricity/i
    r.left_of "Total ($)"
  end
  textangle.text
  => [['string','string'],['string']] # array of rows, each row is an array of text elements in the row
```

### How to describe an inclusive `bounding_box` region

By default, the `bounding_box` method makes exclusive selection (i.e. not including the
region limits).

To specify an inclusive region, use the `inclusive!` command:
```ruby
  textangle = reader.bounding_box do
    inclusive!
    below /electricity/i
    left_of "Total ($)"
  end
```
Alternatively, set `inclusive` to true:
```ruby
  textangle = reader.bounding_box do
    inclusive true
    below /electricity/i
    left_of "Total ($)"
  end
```
Or with a block parameter, you may also assign `inclusive` to true:
```ruby
  textangle = reader.bounding_box do |r|
    r.inclusive = true
    r.below /electricity/i
    r.left_of "Total ($)"
  end
```
### Extract text for a region with known positional co-ordinates

If you know (or can calculate) the x,y positions of the required text region, you can extract the region's text using the `text_in_region` method.
```
  text = reader.text_in_region(
    10,   # minimum x (left-most)
    900,  # maximum x (right-most)
    200,  # minimum y (top-most)
    400,  # maximum y (bottom-most)
    false # inclusive of x/y position if true (default false)
  )
  => [['string','string'],['string']] # array of rows, each row is an array of text elements in the row
```
Note that the x,y origin is at the **top-left**. 
This differs from how it works in PDF::Reader::Turtletext, where the origin 
was bottom-left of the page.

### How to find the x,y co-ordinate of a specific text element

If you are doing low-level text extraction with `text_in_region` for example,
it is usually necessary to locate specific text to provide a positional reference.

Use the `text_position` method to locate text by exact or partial match.
It returns a Hash of x/y co-ordinates that is the bottom-left corner of the text.
```
  text_by_exact_match = reader.text_position("Transaction Table")
  => { :x => 10.0, :y => 600.0 }
  text_by_regex_match = reader.text_position(/transaction summary/i)
  => { :x => 10.0, :y => 300.0 }
```
Note: in the case of multiple matches, only the first match is returned.

## Contributing

- Check issue tracker if someone is working on what you plan to work on
- Fork project
- Create new branch
- Make changes in new branch
- Submit pull request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Special Thanks
- Paul Gallagher, creator of the [PDF::Reader::Turtletext](https://github.com/tardate/pdf-reader-turtletext) gem, from which large sections of this gem was copied/modified from.