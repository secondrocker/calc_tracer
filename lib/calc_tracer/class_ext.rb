class Object
  # @description 跟踪代码执行路径，并记录一些信息
  # @param args [Array] 参数，可以是一个Hash对象，也可以是一个字符串
  # @yield
  # @return nil
  def __trace(args = {}, &block)
    self._c_tracer = CalcTracer::Tracer.new(**args)
    # 调用一个内部方法__trace__，传入相同的块参数，执行具体的跟踪逻辑
    _c_tracer.trace(&block)
  ensure
    self._c_tracer = nil
  end

  # @description 在当前span中创建一个子span，并执行块参数中的代码
  # @param args [Array] 参数，可以是一个Hash对象，也可以是一个字符串
  # @yield
  # @return nil
  def __in_span(args = {}, &block)
    return if _c_tracer.nil? # 无tracer不做任何事，不抛异常

    self._c_tracer = _c_tracer.new_span(**args)
    _c_tracer.trace(&block) # 子 span下执行
    _parent = _c_tracer.parent # 获取父 span
    _c_tracer.parent = nil # 设置父 span为nil
    self._c_tracer = _parent # 恢复到父span 下执行
  end

  # @description 在当前span/或直接tracer中记录一些信息
  # @param args [Hash] 参数，可以是一个Hash对象，也可以是一个字符串
  # @return nil
  def __r(args)
    return if _c_tracer.nil? # 无tracer不做任何事，不抛异常

    _c_tracer.r(args)
  end

  # get
  def _c_tracer
    Thread.current[:_c_tracer]
  end

  # set
  def _c_tracer=(val)
    Thread.current[:_c_tracer] = val
  end
end
