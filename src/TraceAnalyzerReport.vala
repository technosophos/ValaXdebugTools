using Gee;

public class XdebugTools.TraceAnalyzerReport : GLib.Object {
  
  protected ArrayList<XdebugTools.FunctionReport> functions;
  protected string format = "%s%s%8d  %8d  %16d  %8d  %16d\n";
  protected string header = """
                                                                               Inclusive:                     Own:
Func                                                                           Calls        Time (i)        Mem (i)        Time (o)        Mem (o)
==================================================================================================================================================
""";
  
  public TraceAnalyzerReport(ArrayList<XdebugTools.FunctionReport> functions) {
    this.functions = functions;
  }
  
  public void write_report(int max_lines) {
    stdout.printf(this.header);
    
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