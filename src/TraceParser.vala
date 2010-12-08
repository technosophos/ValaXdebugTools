using Gee;

namespace XdebugTools {
  
  /**
   * A parser implementing an observer pattern.
   *
   * Various analyzers can register themselves as observers to this 
   * parser, which makes it possible to chain multiple analyzers off of a 
   * single parser.
   */
  public class TraceParser : GLib.Object {
    
    protected ArrayList<TraceObserver> observers;
    protected File xt_file;
    public bool verbose = false;
    
    public TraceParser(File xt_file) {
      this.xt_file = xt_file;
      this.observers = new ArrayList<TraceObserver>();
    }
    
    public TraceParser.from_filename(string filename) {
      var xt_file = File.new_for_path(filename);
      
      this(xt_file);
    }
    
    /**
     * Register an observer.
     *
     * This must be called before parse().
     *
     * @param TraceObserver observer
     *  The observer. This will be notified of events.
     */
    public void register(TraceObserver observer) {
      this.observers.add(observer);
    }
    
    /**
     * Parse the file.
     */
    public void parse() throws IOError, Error {
      string line;

      if (this.verbose) {
        stdout.printf("Parsing file...\n\n");
      }

      var input = new DataInputStream(this.xt_file.read());
      while ((line = input.read_line(null)) != null) {
        this.parse_line(line);
      }
      
    }
    
    protected void parse_line(string line) {
      string [] parts = line.split("\t");
      
      // Short lines are for start/end of traces.
      if (parts.length < 5) {
        if (parts[0] == null) {
          return;
        }
        else if ("END" in parts[0]) {
          foreach (var observer in this.observers) {
            observer.end_entry(parts[0]);
          }
          return;
        }
        else if ("START" in parts[0]) {
          foreach (var observer in this.observers) {
            observer.start_entry(parts[0]);
          }
          return;
        }
        // Ignore version line.
        else {
          if (this.verbose) {
            stdout.printf("Ignoring line: %s\n", line);
          }
          return;
        }
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
      // 7: extra data. eval() and include/require generate data here.
      // 8: source file path
      // 9: line number of definition

      int depth = parts[0].to_int();
      int func_id = parts[1].to_int();
      //int type = parts[2].to_int();
      double time = parts[3].to_double();
      int memory = parts[4].to_int();

      // Entering function
      if (parts[2] == "0") {
        string func_name = parts[5];
        bool int_func = parts[6] == "0";
        string extra = parts[7];
        string filename = parts[8];
        int line_number = parts[9].to_int();
        
        foreach (var observer in this.observers) {
          observer.enter_function(depth, func_id, time, memory, func_name, int_func, filename, line_number, extra);
        }
      }
      // Leaving function
      else if (parts[2] == "1") {
        foreach (var observer in this.observers) {
          observer.exit_function(depth, func_id, time, memory);
        }
      }
    }
    
  }
  
  public class TraceObserver : GLib.Object {
    
    public virtual void start_entry(string timestamp) {}
    public virtual void end_entry(string timestamp) {}
    /**
     * Handle a function entry.
     *
     * @param int depth
     *  The depth in the call stack.
     * @param int func_id
     *  The id for this entry in the call stack. It will match the corresponding func_id in exitFunction().
     * @param float time
     *  The elapsed time in msec since the program started.
     * @param int memory
     *  The amount of memory consumed during the running of the application.
     * @param string name
     *  The name of the symbol (usually a function name)
     * @param bool is_internal
     *  This is true iff the given symbol is an internal (non-user) function or directive.
     * @param string filename
     *  The name of the file from whence this came.
     * @param int line
     *  The line number where this was defined in the named file.
     * @param string extra
     *  Extra data from the parse. This is usually empty. For includes, this is the name of the 
     *  included file. For eval() this is the eval'd code.
     */
    public virtual void enter_function(int depth, int func_id, double time, int memory, string name, bool is_internal, string filename, int line, string? extra = null){}
    /**
     * Handle a function entry.
     *
     * @param int depth
     *  The depth in the call stack.
     * @param int func_id
     *  The id for this entry in the call stack. It will match the corresponding func_id in enterFunction().
     * @param float time
     *  The elapsed time in msec since the program started.
     * @param int memory
     *  The amount of memory consumed during the running of the application.
     */
    public virtual void exit_function(int depth, int func_id, double time, int memory){}
    
  }
  
}