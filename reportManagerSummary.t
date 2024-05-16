#charset "us-ascii"
//
// reportManagerSummary.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

class ReportSummaryData: object
	dobj = nil
	vec = nil
	count = nil
	prep = nil

	construct(v, o, p) {
		vec = v;
		dobj = o;
		prep = p;
		count = dobj._reportCount;
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

	// Wrapper for the summary method.  We ping the report manager
	// to figure out if EVERY report for the current action is being
	// summarized, and the report manager decides whether or not
	// to prepend announcement text (usually the object name with
	// a colon) to the summary.
	summarizeByLocation(vec, txt) {
		local dobjs, i, locs, n, obj, vecs;

		if((vec == nil) || (vec.length < 1))
			return;

		locs = new Vector(vec.length);
		dobjs = new Vector(vec.length);
		vecs = new Vector(vec.length);

		vec.forEach(function(o) {
			if(o.dobj_ == nil)
				return;
			if((i = locs.indexOf(o.dobj_.location)) == nil) {
				locs.appendUnique(o.dobj_.location);
				dobjs.append(o.dobj_);
				vecs.append(new Vector());
				i = locs.length;
			}
			vecs[i].append(o);
		});

		for(i = 1; i <= locs.length; i++) {
			n = 0;
			gAction.dobjList_.forEach(function(o) {
				if(o.obj_.reportManager != reportManager)
					return;
				if(o.obj_.location != locs[i])
					return;
				n += 1;
			});
			dobjs[i]._reportCount = n;
		}

		for(i = 1; i <= locs.length; i++) {
			obj = new ReportSummaryData(vecs[i], dobjs[i],
				(locs.length > 1));

			reportSummaryMessageParams(obj.dobj);
			reportManager.reportManagerAnnouncement(obj, txt);
			summarize(obj, txt);
		}
	}

	reportSummaryMessageParams(obj?) {}

	summarize(data, txt) {}
;
