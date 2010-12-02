using Gee;

public class XdebugTools.TraceAnalyzerReport : GLib.Object {
  
  protected ArrayList<XdebugTools.FunctionReport> functions;
  protected string format = "%s%s%8d  %0.4f  %16d  %0.4f  %16d\n";
  protected string header = """
                                                                                            Inclusive:                     Own:
Func                                                                           Calls        Time (i)        Mem (i)        Time (o)        Mem (o)
==================================================================================================================================================
""";
  
  public TraceAnalyzerReport(ArrayList<XdebugTools.FunctionReport> functions) {
    this.functions = functions;
  }
  
  public void write_csv_report(string sep = ",", bool print_header = true) {
    if (print_header) {
      stdout.printf("function,calls,time_inclusive,memory_inclusive,time_own,memory_own\n");
    }
    
    
    foreach (var report in this.functions) {
      string buffer = string.join(
        sep,
        "'%s'".printf(report.name),
        report.calls.to_string(),
        "%0.6f".printf(report.time_inclusive),
        report.memory_inclusive.to_string(),
        "%0.6f".printf(report.time_own),
        report.memory_own.to_string()
      );
      
      stdout.printf("%s\n",buffer);
    }
  }
  
  public void write_report(int max_lines) {
    stdout.printf(this.header);
    
    // 0 means unlimited.
    if (max_lines == 0) max_lines = this.functions.size;
    
    int lines = 0;
    foreach (var report in this.functions) {
      if (++lines > max_lines) {
        return;
      }
      //stdout.printf(this.format_message(report, 100));
      string spacer = string.nfill(80 - report.name.length, ' ');

      stdout.printf(
        this.format,
        report.name,
        spacer,
        report.calls,
        report.time_inclusive,
        report.memory_inclusive,
        report.time_own,
        report.memory_own
        );
    }
  }
  
  public void set_format(string format, string header = "") {
    this.format = format;
    this.header = header;
  }

}