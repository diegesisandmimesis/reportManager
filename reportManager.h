//
// reportManager.h
//

#define gIsReport(r) (((r != nil) && r.ofKind(CommandReport)) ? true : nil)
#define gReportObject(r) (gIsReport(r) ? r.dobj_ : nil)
#define gReportObjectOfKind(r, cls) \
	(gIsReport(r) ? (r.dobj_ ? r.dobj_.ofKind(cls) : nil) : nil)
#define gReportAction(r) (gIsReport(r) ? r.action_ : nil)

ReportSummary template @action;

#define REPORT_MANAGER_H
