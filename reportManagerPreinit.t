#charset "us-ascii"
//
// reportManagerPreinit.t
//
//	Preinit singleton for report managers.  We use a singleton
//	to make it easier to ensure seriality of the different init methods.
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
