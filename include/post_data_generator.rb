class Http2::PostDataGenerator
  def initialize(pdata, args = {})
    @pdata, @args = pdata, args
  end

  def generate
    praw = ""

    if @pdata.is_a?(Hash)
      praw << generate_for_hash(@pdata)
    elsif @pdata.is_a?(Array)
      praw << generate_for_array(@pdata)
    else
      return @pdata.to_s
    end

    return praw
  end

private

  def generate_for_hash(hash)
    praw = ""

    @pdata.each do |key, val|
      praw << "&" if praw != ""
      key = "#{@args[:orig_key]}[#{key}]" if @args[:orig_key]
      praw << generate_key_value(key, val)
    end

    praw
  end

  def generate_for_array(array)
    praw = ""

    count = 0
    @pdata.each do |val|
      praw << "&" if praw != ""

      if @args[:orig_key]
        key = "#{@args[:orig_key]}[#{count}]"
      else
        key = count
      end

      praw << generate_key_value(key, val)
      count += 1
    end

    praw
  end

  def generate_key_value(key, value)
    if value.is_a?(Hash) || value.is_a?(Array)
      return ::Http2::PostDataGenerator.new(value, orig_key: key).generate
    else
      data = ::Http2::PostDataGenerator.new(value).generate
      return "#{Http2::Utils.urlenc(key)}=#{Http2::Utils.urlenc(data)}"
    end
  end
end
