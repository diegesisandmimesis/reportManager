#charset "us-ascii"
//
// reportManagerSummary.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

class ReportSummaryData: object
	vec = nil
	objs = nil
	count = nil

	construct(v) {
		vec = v;

		objs = new Vector(v.length);
		vec.forEach(function(o) {
			objs.appendUnique(o.dobj_);
		});

		count = objs.length;
	}
;

class ReportSummary: ReportManagerObject
	action = nil

	reportManager = nil

	initializeReportSummary() {
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

	_summarize(data) {
		reportSummaryMessageParams(data.objs[1]);
		return(summarize(data));
	}

	summarize(data) {}

	reportSummaryMessageParams(obj?) {}
;
