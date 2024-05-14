#charset "us-ascii"
//
// reportManagerPreinit.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

reportManagerPreinit: PreinitObject
	execute() {
		forEachInstance(ReportSummary, function(o) {
			o.initializeReportSummary();
		});

		forEachInstance(ReportManager, function(o) {
			o.initializeReportManager();
		});
	}
;
