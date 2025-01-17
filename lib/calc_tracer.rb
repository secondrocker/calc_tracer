# frozen_string_literal: true

require_relative "calc_tracer/class_ext"
require_relative "calc_tracer/context_bound_delegate"
require_relative "calc_tracer/version"
require "byebug"
require "logger"

module CalcTracer
  def self.trace_callback(&block)
    Thread.current[:tracer_callback] = block
  end

  class Tracer
    # 跟踪的数据，span上一级, 标签
    attr_accessor :data, :parent
    attr_accessor :spans, :top

    # 初始化方法，接收一个参数，可以是一个Hash对象，也可以是一个字符串，用于设置跟踪的数据标签。
    # 如果参数是一个字符串，则将字符串作为标签设置，否则将参数作为数据设置。
    # @param args [Hash, String] 参数，可以是一个Hash对象，也可以是一个字符串
    def initialize(args = {})
      parent = args.delete(:parent) if args
      self.data = args || {}
      self.spans = []
      self.top = parent.nil?
      self.parent = parent
    end

    # 跟踪方法，接收一个块参数，用于执行跟踪逻辑
    # @yield
    def trace(&block)
      return unless block_given? # 如果没有给定块参数，则直接返回

      # 调用ContextBoundDelegate类的instance_eval_with_context方法，并传入当前对象self和块参数block
      # 该方法的作用是将块参数中的代码进行执行，同时将当前对象设置为代码的上下文对象
      val = ContextBoundDelegate.instance_eval_with_context(
        calling_context = eval("self", block.binding, __FILE__, __LINE__), &block
      )
      if top
        logger = Logger.new(STDOUT)
        if Thread.current[:tracer_callback]
          Thread.current[:tracer_callback]&.call(json_data)
          Thread.current[:tracer_callback] = nil
        end
        logger.info(json_data)
      end
      val
    end

    # 存入的json数据
    # @return [Hash]
    def json_data
      _data = {}
      _data.merge!(data) unless data.empty?
      _data.merge!(spans: spans.map(&:json_data)) unless spans.empty?
      _data
    end

    def new_span(args = {})
      t = ::CalcTracer::Tracer.new(**args, parent: self)
      spans << t
      t
    end

    def time_tag
      Time.now.strftime("%Y-%m-%d %H:%M:%S.%L")
    end

    # 定义一个名为__r的私有方法，该方法将参数的描述信息添加到当前span的记录数组中
    #
    # @param args [Array] 参数的数组，包含要记录的信息
    # @return [void]
    def r(args)
      # 将参数的描述信息添加到当前span的记录数组中
      data.merge!(args)
    end
  end
end
