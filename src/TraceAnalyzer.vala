using Gee;

/**
 * Trace analyzer parses Xdebug trace files and produces a report.
 */
public class XdebugTools.TraceAnalyzer : XdebugTools.TraceObserver {

  protected int max;
  protected string sort;
  protected File file;
  protected ArrayList<FunctionCall> stack;
  protected HashMap<string, FunctionReport> functions;
  
  protected bool _verbose = false;
  
  /**
   * Set the verbose flag.
   */
  public bool verbose {
    get { return this._verbose; }
    set {this._verbose = value; }
  }
  
  public TraceAnalyzer(string sort, int max) {
    this.stack = new ArrayList<FunctionCall>();
    this.functions = new HashMap<string, FunctionReport>();
    
    var stack_item = new FunctionCall("<start>", 0, 0, 0, 0);
    this.stack.add(stack_item);
  }
  
  /**
   * Get the results of a parsing run.
   */
  public ArrayList<FunctionReport> get_functions(string sort, bool suppress_internal = false) {
    
    var sortable_list = new ArrayList<FunctionReport>();
    // Compute time and memory usage.
    foreach (var entry in this.functions.entries) {
      var function = entry.value;
            
      // Skip internal functions.
      if (suppress_internal && function.is_internal) {
        //if (this.verbose) stdout.printf("Hiding %s\n", function.name);
        continue;
      }

      function.memory_own = function.memory_inclusive - function.memory_children;
      function.time_own = function.time_inclusive - function.time_children;
      
      // Calculate averages
      function.memory_avg = function.memory_own / function.calls;
      function.time_avg = function.time_own / function.calls;
      
      sortable_list.add(function);
    }
    
    // Sort the list if a sorter is set.
    CompareDataFunc comparator = this.create_comparator(sort);
    
    sortable_list.sort_with_data(comparator);
        
    return sortable_list;
  }
  
  // Inherit docs.
  public override void enter_function(int depth, int func_id, double time, int memory, string name, bool is_internal, string filename, int line, string? extra = null){
    var stack_item = new FunctionCall(name, time, memory, 0, 0);
    
    stack_item.is_internal = is_internal;
    
    if (this.verbose) {
      stdout.printf("> %d %s (%0.8f, %d)\n", depth, name, time, memory);
      if (!is_internal)
        stdout.printf("  Defined in %s:%d\n", filename, line);
    }
    
    
    if (this.stack.size >= depth + 1) {
      this.stack.set(depth, stack_item);
    }
    else {
      this.stack.add(stack_item);
    }
  }
  
  // Inherit docs.
  public override void exit_function(int depth, int func_id, double time, int memory){
    if (this.verbose) stdout.printf("< %d\n", depth);
    
    // We retrieve the already-set stack item.
    var stack_item = this.stack.get(depth);
    var parent_item = this.stack.get(depth -1);
    
    // Adjust time and memory.
    var dtime = time - stack_item.time;
    var dmem = memory - stack_item.memory;
    
    parent_item.nested_time += dtime;
    parent_item.nested_memory += dmem;
    
    var new_stack_item = new FunctionCall(stack_item.name, dtime, dmem, stack_item.nested_time, stack_item.nested_memory);
    new_stack_item.is_internal = stack_item.is_internal;
    
    this.add_to_function(new_stack_item, depth);
    
  }
  
  /**
   * Create a comparison function.
   */
  protected CompareDataFunc create_comparator(string sort) {
    CompareDataFunc comparator;
    
    if (this.verbose) stdout.printf("Sorting with %s\n", sort);
    
    // This is here because there is currently an error in Vala.
    // Closures do not correctly handle external variables on OS X.
    switch (sort) {
      case "time_own":
        comparator = (raw_a, raw_b) => {
          FunctionReport a = (FunctionReport)raw_a;
          FunctionReport b = (FunctionReport)raw_b;
          if (a.time_own < b.time_own) return 1;
          return b.time_own < a.time_own ? -1 : 0;
        };
        break;
      case "time_inclusive":
        comparator = (raw_a, raw_b) => {
          FunctionReport a = (FunctionReport)raw_a;
          FunctionReport b = (FunctionReport)raw_b;
          if (a.time_inclusive < b.time_inclusive) return 1;
          return b.time_inclusive < a.time_inclusive ? -1 : 0;
        };
        break;
      case "time_min":
        comparator = (raw_a, raw_b) => {
          FunctionReport a = (FunctionReport)raw_a;
          FunctionReport b = (FunctionReport)raw_b;
          if (a.time_least < b.time_least) return 1;
          return b.time_least < a.time_least ? -1 : 0;
        };
        break;
      case "time_avg":
        comparator = (raw_a, raw_b) => {
          FunctionReport a = (FunctionReport)raw_a;
          FunctionReport b = (FunctionReport)raw_b;
          if (a.time_avg < b.time_avg) return 1;
          return b.time_avg < a.time_avg ? -1 : 0;
        };
        break;
      case "time_max":
        comparator = (raw_a, raw_b) => {
          FunctionReport a = (FunctionReport)raw_a;
          FunctionReport b = (FunctionReport)raw_b;
          if (a.time_most < b.time_most) return 1;
          return b.time_most < a.time_most ? -1 : 0;
        };
        break;
      case "memory_own":
        comparator = (raw_a, raw_b) => {
          FunctionReport a = (FunctionReport)raw_a;
          FunctionReport b = (FunctionReport)raw_b;
          if (a.memory_own < b.memory_own) return 1;
          return b.memory_own < a.memory_own ? -1 : 0;
        };
        break;
      case "memory_inclusive":
        comparator = (raw_a, raw_b) => {
          FunctionReport a = (FunctionReport)raw_a;
          FunctionReport b = (FunctionReport)raw_b;
          if (a.memory_inclusive < b.memory_inclusive) return 1;
          return b.memory_inclusive < a.memory_inclusive ? -1 : 0;
        };
        break;
      case "memory_min":
        comparator = (raw_a, raw_b) => {
          FunctionReport a = (FunctionReport)raw_a;
          FunctionReport b = (FunctionReport)raw_b;
          if (a.memory_least < b.memory_least) return 1;
          return b.memory_least < a.memory_least ? -1 : 0;
        };
        break;
      case "memory_avg":
        comparator = (raw_a, raw_b) => {
          FunctionReport a = (FunctionReport)raw_a;
          FunctionReport b = (FunctionReport)raw_b;
          if (a.memory_avg < b.memory_avg) return 1;
          return b.memory_avg < a.memory_avg ? -1 : 0;
        };
        break;
      case "memory_max":
        comparator = (raw_a, raw_b) => {
          FunctionReport a = (FunctionReport)raw_a;
          FunctionReport b = (FunctionReport)raw_b;
          if (a.memory_most < b.memory_most) return 1;
          return b.memory_most < a.memory_most ? -1 : 0;
        };
        break;
      case "calls":
      default:
        comparator = (raw_a, raw_b) => {
          FunctionReport a = (FunctionReport)raw_a;
          FunctionReport b = (FunctionReport)raw_b;
          if (a.calls < b.calls) return 1;
          return b.calls < a.calls ? -1 : 0;
        };
        break;
    }

    return comparator;
  }
  
  protected void add_to_function(FunctionCall func, int depth) {
    
    FunctionReport report;
    if (!this.functions.has_key(func.name)) {
      report = new FunctionReport(func.name);
      this.functions.set(func.name, report);
    }
    else {
      report = this.functions.get(func.name);
    }
    
    // Increment call counter.
    report.calls++;
    
    // Add data.
    if (!this.function_is_in_stack(func.name, depth)) {
      report.is_internal = func.is_internal;
      
      report.time_inclusive += func.time;
      report.time_children += func.nested_time;
      
      double time_this_call = func.time - func.nested_time;
      if ( time_this_call < report.time_least) report.time_least = time_this_call;
      if ( time_this_call > report.time_most) report.time_most = time_this_call;
      
      report.memory_inclusive += func.memory;
      report.memory_children += func.nested_memory;
      
      int memory_this_call = func.memory - func.nested_memory;
      if ( memory_this_call < report.memory_least) report.memory_least = memory_this_call;
      if ( memory_this_call > report.memory_most) report.memory_most = memory_this_call;
    }
  }
  
  protected bool function_is_in_stack(string func_name, int depth) {
    int i;
    FunctionCall stack_item;
    
    for (i = 0; i < depth; ++i) {
      stack_item = this.stack.get(i);
      if (stack_item.name == func_name) return true;
    }
    return false;
  }
}

/**
 * Class describing a function call.
 */
public class XdebugTools.FunctionCall : GLib.Object {
  public string name;
  
  public bool is_internal = false;
  
  public double time;
  public double nested_time;
  
  public int memory;
  public int nested_memory;
  
  public FunctionCall(string name, double time, int memory, double nested_time, int nested_memory) {
    this.name = name;
    this.time = time;
    this.memory = memory;
    this.nested_time = nested_time;
    this.nested_memory = nested_memory;
  }
}

/**
 * Class describing how many times a function was run.
 */
public class XdebugTools.FunctionReport : GLib.Object {
  
  public bool is_internal = false;
  
  public int calls = 0;
  
  public double time_inclusive = 0;
  public double time_own = 0;
  public double time_children = 0;
  
  public double time_least = 9999;
  public double time_most = 0;
  public double time_avg = 0;
  
  public int memory_inclusive = 0;
  public int memory_own = 0;
  public int memory_children = 0;
  
  public int memory_least = 67108864;
  public int memory_most = 0;
  public int memory_avg;
  
  public string name;
  
  public FunctionReport(string name) {
    this.name = name;
  }
}