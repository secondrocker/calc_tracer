# 跟踪器依赖的block内method 硕源类，代理方法到block的所属context的self下
class ContextBoundDelegate
  class << self
    def instance_eval_with_context(receiver, &block)
      calling_context = eval("self", block.binding, __FILE__, __LINE__)
      if (parent_calling_context = calling_context.instance_eval do
            @__calling_context__ if defined?(@__calling_context__)
          end)
        calling_context = parent_calling_context
      end
      t = new(receiver, calling_context)
      t.instance_eval(&block)
    end

    private :new
  end

  BASIC_METHODS = %w[== equal? ! != instance_eval instance_exec methods object_id __send__ __id__].map(&:to_sym)

  instance_methods.each do |method|
    undef_method(method) unless BASIC_METHODS.include?(method.to_sym)
  end

  undef_method(:select)

  def initialize(receiver, calling_context)
    @__receiver__ = receiver
    @__calling_context__ = calling_context
  end

  def id
    @__calling_context__.__send__(:id)
  rescue ::NoMethodError => e
    begin
      @__receiver__.__send__(:id)
    rescue ::NoMethodError
      raise(e)
    end
  end

  # Special case due to `Kernel#sub`'s existence
  def sub(*args, &block)
    __proxy_method__(:sub, *args, &block)
  end

  def method_missing(method, *args, &block)
    __proxy_method__(method, *args, &block)
  end

  def __proxy_method__(method, *args, &block)
    @__receiver__.__send__(method.to_sym, *args, &block)
  rescue ::NoMethodError => e
    begin
      @__calling_context__.__send__(method.to_sym, *args, &block)
    rescue ::NoMethodError
      raise(e)
    end
  end
end
