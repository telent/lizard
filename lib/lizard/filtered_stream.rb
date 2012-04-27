class Lizard::FilteredStream
  def initialize(under_stream,blck)
    @under_stream=under_stream
    @blck=blck
  end
  def write(data)
    data=@blck.call(data)
    data and @under_stream.write(data)
  end
end
