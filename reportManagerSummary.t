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
	dobj = nil
	count = nil

	failures = nil
	failureCount = nil

	construct(v) {
		vec = v;

		if((v == nil) || (v.length < 1))
			return;

		objs = new Vector(v.length);
		vec.forEach(function(o) {
			objs.appendUnique(o.dobj_);
		});

		count = objs.length;

		if(objs.length < 1)
			return;

		dobj = objs[1];
		dobj._reportCount = count;
	}
;

class ReportSummary: ReportManagerObject
	action = nil

	reportManager = nil
	isFailure = nil

	reportManagerSummaryClass = ReportManagerSummary

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

	acceptReport(report) {
		if(report == nil)
			return(nil);
		if(!matchAction(report.action_))
			return(nil);
		if(report.isFailure != isFailure)
			return(nil);
		return(true);
	}

	_summarize(data) {
		reportSummaryMessageParams(data.dobj);
		return(summarize(data));
	}

	summarize(data) {}

	reportSummaryMessageParams(obj?) {}

	summarizeReports(vec) {
		local txt;

		if(reportManager != nil)
			txt = reportManager.summarizeReports(vec);
		else
			txt = '';

		return(reportManagerSummaryClass.createInstance(txt));
	}
;

class FailureSummary: ReportSummary
	isFailure = true
;
