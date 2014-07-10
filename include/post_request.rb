class Http2::PostRequest
  VALID_ARGUMENTS_POST = [:post, :url, :default_headers, :headers, :json, :method, :cookies, :on_content, :content_type]

  def initialize(http2, args)
    args.each do |key, val|
      raise "Invalid key: '#{key}'." unless VALID_ARGUMENTS_POST.include?(key)
    end

    @http2, @args, @debug, @nl = http2, http2.parse_args(args), http2.debug, http2.nl
  end

  def execute
    @data = raw_data

    @http2.mutex.synchronize do
      puts "Http2: Doing post." if @debug
      puts "Http2: Header str: #{header_str}" if @debug

      @http2.write(header_string)
      return @http2.read_response(@args)
    end
  end

private

  def method
    if @args[:method]
      @args[:method].to_s.upcase
    else
      "POST"
    end
  end

  def content_type
    if @args[:content_type]
      @args[:content_type]
    elsif @args[:json]
      content_type = "application/json"
    else
      "application/x-www-form-urlencoded"
    end
  end

  def raw_data
    if @args[:json]
      require "json" unless ::Kernel.const_defined?(:JSON)
      @args[:json].to_json
    elsif @args[:post].is_a?(String)
      @args[:post]
    else
      phash = @args[:post] ? @args[:post].clone : {}
      @http2.autostate_set_on_post_hash(phash) if @http2.args[:autostate]
      ::Http2::PostDataGenerator.new(phash).generate
    end
  end

  def headers
    headers_hash = {"Content-Length" => @data.bytesize, "Content-Type" => content_type}
    headers_hash.merge! @http2.default_headers(@args)
  end

  def header_string
    header_str = "#{method} /#{@args[:url]} HTTP/1.1#{@nl}"
    header_str << @http2.header_str(headers, @args)
    header_str << @nl
    header_str << @data

    header_str
  end
end