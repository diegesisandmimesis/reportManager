#charset "us-ascii"
//
// reportManager.t
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

// Module ID for the library
reportManagerModuleID: ModuleID {
        name = 'Report Manager Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

class ReportManager: object
	minSummaryLength = 2

	_reportManagerData = nil

	initReportManagerData() {
		_reportManagerData = new LookupTable();
	}

	rememberReportData(key, data) {
		if(_reportManagerData == nil)
			initReportManagerData();

		if(_reportManagerData[key] == nil)
			_reportManagerData[key] = new Vector();

		_reportManagerData[key].append(data);

		gAction.callAfterActionMain(self);
	}

	clearReportData() {
		if(_reportManagerData == nil)
				return;
		_reportManagerData.forEachAssoc(function(k, v) {
			if(v == nil)
				return;
			v.setLength(0);
		});
	}

	getReportData(id) {
		return(_reportManagerData ? _reportManagerData[id] : nil);
	}

	afterActionMain() {
		if(gAction.dobjList_.length < minSummaryLength) {
			clearReportData();
			return;
		}

		gTranscript.summarizeAction(
			function(x) { return(x.action_ == gAction); },
			function(vec) {
				return(_summarizeReport(vec));
			}
		);

		clearReportData();
	}

	_summarizeReport(vec) {
		local txt;

		txt = new StringBuffer();

		summarizeReport(vec, txt);

		return(toString(txt));
	}

	summarizeReport(vec, txt) {
		return(txt);
	}
;
