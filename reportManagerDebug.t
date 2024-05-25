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
	_debugReportVector(v, lbl?, flg?) {
		if(v == nil) return;
		_debug((lbl ? lbl : 'report vector')
			+ ':  <<toString(v.length)>> reports', flg);
		v.forEach(function(o) {
			o._debugReport(flg);
		});
	}
;

modify CommandReport
	_debug(msg, flg?) { transcriptManager._debug(msg, flg); }
	_debugReport(flg?) {
		_debug('\t<<toString(self)>>', flg);
		_debug('\t\taction = <<toString(action_)>>', flg);
		_debug('\t\tisFailure = <<toString(isFailure)>>', flg);
		if(dobj_ == nil)
			_debug('\t\tdobj = nil', flg);
		else
			_debug('\t\tdobj = <<toString(dobj_.name)>>
				@ <<toString(dobj_.location
					? dobj_.location.name : nil)>>', flg);
	}
;

#endif // SYSLOG
