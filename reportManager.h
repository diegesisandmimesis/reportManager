//
// reportManager.h
//

#include "syslog.h"
#ifndef SYSLOG_H
#error "This module requires the syslog module."
#error "https://github.com/diegesisandmimesis/syslog"
#error "It should be in the same parent directory as this module.  So if"
#error "reportManager is in /home/user/tads/reportManager, then"
#error "syslog should be in /home/user/tads/syslog ."
#endif // SYSLOG_H

#define gIsReport(r) (((r != nil) && r.ofKind(CommandReport)) ? true : nil)
#define gReportObject(r) (gIsReport(r) ? r.dobj_ : nil)
#define gReportObjectOfKind(r, cls) \
	(gIsReport(r) ? (r.dobj_ ? r.dobj_.ofKind(cls) : nil) : nil)
#define gReportAction(r) (gIsReport(r) ? r.action_ : nil)

ReportSummary template @action;

#define REPORT_MANAGER_H
