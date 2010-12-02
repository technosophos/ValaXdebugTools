using Gee;


/**
 * A trace analyzer front-end that reads from a file.
 */
public class XdebugTools.TracefileAnalyzer : GLib.Object {
  public static bool verbose = false;
  public static int max_lines = 0;
  public static string sort_col = "calls";
  public static bool csv = false;
  public static string csv_separator;
  public static bool csv_no_header = false;
  public static bool no_internals = false;
  
  // Options used by main.
  const OptionEntry entries [] = {
    { "csv", 'c', 0, OptionArg.NONE, out csv, "Print results in CSV. CSV mode will ingnore max-lines.", null },
    { "csv-no-header", 0, 0, OptionArg.NONE, out csv_no_header, "Suppress the CSV header.", null },
    { "csv-separator", 0, 0, OptionArg.STRING, out csv_separator, "Use this string as a separator.", "','" },
    { "max-lines", 'n', 0, OptionArg.INT, out max_lines, "Set the max number (N) of lines to print.", "N"},
    { "no-internals", 0, 0, OptionArg.NONE, out no_internals, "Do not display stats for internal functions. Only user-defined functions will be shown.", null},
    { "sort", 's', 0, OptionArg.STRING, out sort_col, "Name of the column to sort on.", "calls | time_own | memory_own | time_inclusive | memory_inclusive"},
    { "verbose", 'v', 0, OptionArg.NONE, out verbose, "Turn on verbose output.", null },
    { null }
  };
  
  /**
   * Main entry point.
   */
  public static int main(string [] args) {
    
    // Setup and parse options
    var context = new OptionContext("filename.xt - parse a trace file and print a report");
    context.add_main_entries(entries, null);
    try {
      context.parse(ref args);
    } catch (OptionError oe) {
      stderr.printf("%s\n", oe.message);
      return 1;
    }
    
    // We need a filename
    if (args.length == 1) {
      stdout.printf("ERROR: Wrong number of arguments.\n\n");
      stdout.printf(context.get_help(true, null));
      return 1;
    }
    
    string file_name = args[1];
        
    var f = File.new_for_path(file_name);
    if (!f.query_exists()) {
      stdout.printf("FATAL ERROR: File %s does not exist.\n", file_name);
      return 1;
    }
    
    // Do a little scanning of the input params.
    string sort = sort_col == null ? "calls" : sort_col;
    int max = max_lines;
    
    // Create a new tracer.
    var tracer = new TraceAnalyzer(f, sort, max);
    if (TracefileAnalyzer.verbose) {
      tracer.verbose = true;
    }
    if (no_internals) {
      stdout.printf("No internals");
      //tracer.suppress_internals = true;
    }
    
    try {
      tracer.parse_file();
    } catch (Error e) {
      stderr.printf("%s", e.message);
      return 1;
    }
    
    var functions = tracer.get_functions(sort, no_internals);
    var report = new TraceAnalyzerReport(functions);
    
    if (csv) {
      string sep = (csv_separator == null) ? "," : csv_separator;
      report.write_csv_report(sep, !csv_no_header);
    } 
    else {
      report.write_report(max);
    }
    
    return 0;
  }
}