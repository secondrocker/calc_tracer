## CalcTracer
CalcTracer是一个用于跟踪、记录代码执行的工具，它可以帮助开发人员了解代码的执行情况和性能问题。可在调用的外部方法中记录数据，用于后续分析。
CalcTracer支持多线程下进行计算，个线程之间链路数据互不干扰


## 方法调用
```CalcTracer::trace_callback```
  > 是一个设置回调函数类方法，用于接收跟踪数据，应在__trace__方法前调用，且仅使用一次，回调完成后就会置空；
  > 因此每个调用__trace前都需要先执行CalcTracer.trace_callback 设置回调
  > 参数为block，且block有一个参数，就是返回的json数据
  
```Object```下方法(引入包后可在任意位置调用)：
- ```__trace__``` 方法是工具的入口方法，用于跟踪代码的执行情况和性能问题。它接收1个hash参数和一个块参数，执行块参数，且能在块内调用```__in_span__```和```__r__```方法。
- ```__in_span__``` 方法是用于创建子跟踪的方法，接收1个hash参数和一个块参数，执行块参数，且能在块内调用```__in_span__```和```__r__```方法。
- ```__r__``` 方法是用于记录数据的方法，接收1个hash参数


## 举例用法

```ruby


# 获取任务得分
def get_task_score(emp_id)
    task_count = get_task_count
    _r(task_count: task_score)
    task_count * task_score_per_count
end

# 获取批得分
def get_batch_score(emp_id)
    batch_count = get_batch_count
    _r(batch_count: batch_count)
    batch_count * batch_score_per_count
end

# 获取奖金
def get_bonus(emp_id)
    batch_score =  get_batch_score(emp_id)
    task_score = get_task_score(emp_id)
    __r(batch_score: batch_score, task_score: task_score)
end


# 计算奖金

# trace_callback 是一个回调函数，用于接收跟踪数据
# 仅使用一次，回调完成后就会置空
# 因此每个调用__trace前都需要先执行CalcTracer.trace_callback 设置回调
data = {}
CalcTracer.trace_callback { |d| data = d }
__trace tag: "inquire_bonus" do
    emps.group_by(&:department_id).each do |dep_id, dep_emps|
        __span dep_id: dep_id, count: dep_emps.count do
            dep_emps.each do |emp|
                __span employee_id: emp.id do
                    bonus = get_bonus(emp.id) + extra_bonus
                    __r(bonus: bonus, extra_bonus: extra_bonus)
                end
            end
        end
    end
end
```

执行完成后，data 会包含跟踪数据，即会按照 ```span```的层级记录，即使像```get_batch_score```这种外部的方法，只要是在正确的链路调用中，都会被记录
```ruby
{
    tag: "inquire_bonus",
    spans: [
        {
            dep_id: 1,
            count: 5,
            spans: [
                {
                    employee_id: 1,
                    task_count: 1,
                    task_score: 2,
                    batch_count: 1,
                    batch_score: 2,
                    bonus: 102,
                    extra_bonus: 98
                }
            ]
        }
    ]
}
```