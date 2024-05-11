//
// reportManager.h
//

#define gIsReport(r) (((r != nil) && r.ofKind(CommandReport)) ? true : nil)
#define gReportObject(r) (gIsReport(r) ? r.dobj_ : nil)
#define gReportObjectOfKind(r, cls) (gIsReport(r) ? r.ofKind(cls) : nil)
#define gReportAction(r) (gIsReport(r) ? r.action_ : nil)

#define REPORT_MANAGER_H
