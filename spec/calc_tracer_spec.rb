# frozen_string_literal: true

RSpec.describe CalcTracer do
  it "trace without span" do
    data = {}
    CalcTracer.trace_callback { |d| data = d }
    __trace tag: "sum" do
      __r(age: 15)
    end
    expect(data).to eq({ tag: "sum", age: 15 })
  end

  def print_age
    puts "age: 15"
    __r age: 15
    15
  end

  it "trace without span - args" do
    data = {}
    CalcTracer.trace_callback { |d| data = d }
    __trace id: 12, name: "aa" do
      __in_span son: "son1" do
        print_age
      end
    end
    expect(data).to eq({ id: 12, name: "aa", spans: [{ son: "son1", age: 15 }] })
  end

  it "branches demos" do
    data = {}
    CalcTracer.trace_callback { |d| data = d }

    __trace(tag: :branches_scores) do
      __in_span(branch: 1) do
        __in_span(team: 11) do
          __r(count: 11)
        end
        __in_span(team: 12) do
          __r(count: 12)
        end
      end
      __in_span(branch: 2) do
        __in_span(team: 21) do
          __r(count: 21)
        end
        __in_span(team: 22) do
          __r(count: 22)
        end
      end
    end

    expect(data).to eq({ tag: :branches_scores, spans: [
                         {
                           branch: 1,
                           spans: [
                             {
                               team: 11,
                               count: 11
                             },
                             {
                               team: 12,
                               count: 12
                             }
                           ]
                         }, {
                           branch: 2,
                           spans: [
                             {
                               team: 21,
                               count: 21
                             },
                             {
                               team: 22,
                               count: 22
                             }
                           ]
                         }
                       ] })
  end

  it "__r no error" do
    expect(print_age).to eq(15)
  end
end
