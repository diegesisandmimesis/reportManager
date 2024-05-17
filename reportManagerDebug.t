#charset "us-ascii"
//
// reportManagerDebug.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

#ifdef SYSLOG

modify ReportManagerObject
	_debugReportVector(v) {
		if(v == nil) return;
		_debug('report vector:  <<toString(v.length)>> reports');
		v.forEach(function(o) {
			if(o.dobj_ == nil)
				_debug('\tdobj = nil\n ');
			else
				_debug('\tdobj = <<o.dobj_.name>> @
					<<o.dobj_.location
					? o.dobj_.location.name : 'nowhere'>>');
		});
	}
;

modify ReportManager
	afterActionMain() {
		_debug('afterActionMain(): <<toString(gTranscript.reports_.length)>> reports');
		_debugReportVector(gTranscript.reports_);
		inherited();
	}

	summarizeReports(vec) {
		_debug('summarizeReports(): <<toString(vec.length)>> reports');
		_debugReportVector(vec);
		return(inherited(vec));
	}
;

modify ReportSummary
	_summarize(vec, txt) {
		_debug('_summarize(): <<toString(vec.length)>> reports');
		_debugReportVector(vec);
		inherited(vec, txt);
	}

	_summarizeSingle(idx, cfg, txt) {
		//_debug('_summarizeSingle(): <<toString(vec.length)>> reports');
		//_debugReportVector(vec);
		inherited(idx, cfg, txt);
	}

	reportSummaryMessageParams(obj?) {
		_debug('reportSummaryMessageParams()');
		_debug('\tresource = <<obj.name>>');
		_debug('\tlocation = <<obj.location.name>>');
		_debug('\tcount = <<toString(obj._reportCount)>>');
		inherited(obj);
	}
;

#endif // SYSLOG
