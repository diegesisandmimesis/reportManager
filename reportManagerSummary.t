#charset "us-ascii"
//
// reportManagerSummary.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

class ReportSummary: PreinitObject
	action = nil

	reportManager = nil

	execute() { initializeSummary(); }

	initializeSummary() {
		if(location == nil)
			return(nil);
		if(location.ofKind(ReportManager)) {
			location.addReportManagerSummary(self);
			return(true);
		}

		return(nil);
	}

	matchAction(act) {
		if((act == nil) || (action == nil))
			return(nil);

		return(act.ofKind(action));
	}

	getReportObjects(v?) { return(reportManager.getReportObjects(v)); }

	// Wrapper for the summary method.  We ping the report manager
	// to figure out if EVERY report for the current action is being
	// summarized, and the report manager decides whether or not
	// to prepend announcement text (usually the object name with
	// a colon) to the summary.
	_summarize(vec, txt) {
		reportManager.reportManagerAnnouncement(txt);
		summarize(vec, txt);

	}

	summarize(vec, txt) {}
;
