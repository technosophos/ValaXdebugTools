using Gee;

/**
 * Trace analyzer parses Xdebug trace files and produces a report.
 */
public class XdebugTools.TraceAnalyzer : GLib.Object {

  protected int max;
  protected string sort;
  protected File file;
  //protected string[][];
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
  
  /**
   * 
   */
  public TraceAnalyzer(File file, string sort, int max) {
    this.file = file;
    //this.sort = sort;
    //this.max = max;
    
    this.stack = new ArrayList<FunctionCall>();
    this.functions = new HashMap<string, FunctionReport>();
  }
  
  /**
   * Parse the file.
   */
  public void parse_file() throws Error {
    string line;
    
    if (this.verbose) {
      stdout.printf("Parsing file...\n\n");
    }
    
    // Add the wrapper.
    var stack_item = new FunctionCall("<start>", 0, 0, 0, 0);
    this.stack.add(stack_item);
    
    var input = new DataInputStream(this.file.read());
    while ((line = input.read_line(null)) != null) {
      this.parse_line(line);
    }
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
        if (this.verbose) stdout.printf("Hiding %s", function.name);
        continue;
      }

      function.memory_own = function.memory_inclusive - function.memory_children;
      function.time_own = function.time_inclusive - function.time_children;
      sortable_list.add(function);
    }
    
    // Sort the list if a sorter is set.
    CompareDataFunc comparator = this.createComparator(sort);
    
    sortable_list.sort_with_data(comparator);
        
    return sortable_list;
  }
  
  /**
   * Create a comparison function.
   */
  protected CompareDataFunc createComparator(string sort) {
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
  
  protected void parse_line(string line) {
    string [] parts = line.split("\t");
    
    // Short lines are for non-important details.
    if (parts.length < 5) {
      return;
    }
    
    // FIELD DEFINITIONS:
    // 0: depth
    // 1: function number
    // 2: type: 0 = entry, 1 = exit
    // 3: elapsed time
    // 4: total memory usage to this point
    //
    // The following fields are only present when type = 0
    // 5: function name
    // 6: function type: 0 = internal, 1 = user
    // 7: seems to always be empty
    // 8: include filename
    // 9: line number of definition
    
    int depth = parts[0].to_int();
    //string func_nr = parts[1];
    double time = parts[3].to_double();
    int memory = parts[4].to_int();
    
    
    // Entering function
    if (parts[2] == "0") {
      string func_name = parts[5];
      string int_func = parts[6];
      //string include_string = parts[7];
      string filename = parts[8];
      int line_number = parts[9].to_int();
      
      var stack_item = new FunctionCall(func_name, time, memory, 0, 0);
      
      if (int_func == "0") {
        //stdout.printf("Function %s is internal.\n", func_name);
        stack_item.is_internal = true;
      }
      
      stdout.printf("File: %s (%s), line %d\n", filename, include_string, line_number);
      
      //
      if (this.verbose) {
        stdout.printf("> %d %s (%0.8f, %d)\n", depth, func_name, time, memory);
      }
      
      
      if (this.stack.size >= depth + 1) {
        this.stack.set(depth, stack_item);
      }
      else {
        this.stack.add(stack_item);
      }
    }
    // Leaving function
    else if (parts[2] == "1") {
      
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
      
      report.memory_inclusive += func.memory;
      report.memory_children += func.nested_memory;
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
  
  public int memory_inclusive = 0;
  public int memory_own = 0;
  public int memory_children = 0;
  
  public string name;
  
  public FunctionReport(string name) {
    this.name = name;
  }
}