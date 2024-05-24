#charset "us-ascii"
//
// reportManagerMods.t
//
//	Modifications to base TADS3/adv3 classes.
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

// Remember the direct object in every command report.
// This approach is from Eric Eve's "Manipulating the Transcript"
//	https://tads.org/t3doc/doc/techman/t3transcript.htm
modify CommandReport
	dobj_ = nil
	iobj_ = nil

	reportID = nil
	reportSummarizer = nil

	construct() {
		inherited();
		dobj_ = gDobj;
		iobj_ = gIobj;
	}

	getReportSummarizer() {
		if(reportSummarizer != nil)
			return(reportSummarizer);

		if((dobj_ == nil) || (dobj_.reportManager == nil))
			return(nil);

		reportSummarizer = dobj_.reportManager
			.getReportSummarizer(self);

		return(reportSummarizer);
	}
;

modify Action
	transcriptManagerAfterActionMain() {
		if(parentAction != nil)
			return;
		transcriptManager.afterActionMain();
	}
;

// Modify TAction to check to see if any matching objects have report
// managers.
modify TAction
	afterActionMain() {
		inherited();
		transcriptManagerAfterActionMain();
	}
;

// Modify TIAction to check to see if any matching objects have report
// managers.
modify TIAction
	afterActionMain() {
		inherited();
		transcriptManagerAfterActionMain();
	}
;

// Modify Thing to have a property for the optional report manager.
modify Thing
	// The report manager we use, if any.
	reportManager = nil

	// If we're in a report and we're selected as the "representative"
	// object for the report, this will hold the number of objects
	// being summarized by the report.
	// Used mostly to make it easier to compute once and then look
	// up instead of computing on reference.
	_reportCount = nil
;
