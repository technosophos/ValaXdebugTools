using Gee;


/**
 * A trace analyzer front-end that reads from a file.
 */
public class XdebugTools.TracefileAnalyzer : GLib.Object {
  public static bool verbose = false;
  
  // Options used by main.
  const OptionEntry entries [] = {
    { "verbose", 'v', 0, OptionArg.NONE, out verbose, "Turn on verbose output.", null },
    { null }
  };
  
  /**
   * Main entry point.
   */
  public static int main(string [] args) {
    
    bool verbose = false;
    
    var context = new OptionContext("filename.xt - parse a trace file and print a report");
    context.add_main_entries(entries, null);
    
    try {
      context.parse(ref args);
    } catch (OptionError oe) {
      stderr.printf("%s\n", oe.message);
      return 1;
    }
    
    if (args.length == 1 || args.length > 4) {
      stdout.printf("Wrong number of arguments.\n\n");
      show_usage(args);
      return 1;
    }
    
    string file_name = args[1];
    
    string sort = (args.length >= 3) ? args[2] : "calls";
    
    int max = (args.length >= 4) ? args[3].to_int() : 25;
    
    stdout.printf("Called %s with %s, sort %s, and count %d\n", args[0], file_name, sort, max);

    var f = File.new_for_path(file_name);
    if (!f.query_exists()) {
      stdout.printf("FATAL ERROR: File %s does not exist.\n", file_name);
      return 1;
    }
    
    var tracer = new TraceAnalyzer(f, sort, max);
    if (TracefileAnalyzer.verbose) {
      tracer.verbose = true;
    }
    
    try {
      tracer.parse_file();
    } catch (Error e) {
      stderr.printf("%s", e.message);
      return 1;
    }
    
    var functions = tracer.get_functions(sort);
    var report = new TraceAnalyzerReport(functions);
    
    report.write_report(max);
    
    return 0;
  }
  
  /**
   * Display usage info.
   */
  public static void show_usage(string [] args) {
    
    stdout.printf("Usage: %s filename.xt [sort_filter [number_displayed]]\n\n", args[0]);
    
  }
}