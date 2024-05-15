#charset "us-ascii"
//
// reportManagerSummary.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

class ReportSummary: object
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

	getReportObjects(v?) { return(reportManager.getReportObjects(v)); }

	// Wrapper for the summary method.  We ping the report manager
	// to figure out if EVERY report for the current action is being
	// summarized, and the report manager decides whether or not
	// to prepend announcement text (usually the object name with
	// a colon) to the summary.
	_summarize(vec, txt) {
		local idx, l, v;

		if((vec == nil) || (vec.length < 1))
			return;

		l = new Vector(vec.length);
		v = new Vector(vec.length);
		vec.forEach(function(o) {
			if((idx = l.indexOf(o.dobj_.location)) == nil) {
				l.append(o.dobj_.location);
				v.append(new Vector());
				idx = l.length;
			}
			v[idx].append(o);
		});

		if(l.length == 1) {
			reportSummaryMessageParams(vec);
			reportManager.reportManagerAnnouncement(txt);
			summarize(vec, txt);
		} else {
			v.forEach(function(o) {
				reportSummaryMessageParams(o);
				reportManager.setReportVector(o);
				reportManager.reportManagerAnnouncement(txt,
					o, true);
				summarize(o, txt);
			});
		}
	}

	reportSummaryMessageParams(v?) {}

	summarize(vec, txt) {}
;
