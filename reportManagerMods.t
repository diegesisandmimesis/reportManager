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

	construct() {
		inherited();
		dobj_ = gDobj;
	}
;

// Modify TAction to check to see if any matching objects have report
// managers.
modify TAction
	afterActionMain() {
		inherited();
		if(parentAction == nil)
			reportManagerAfterAction();
	}

	reportManagerAfterAction() {
		local l;

		// If we don't have any objects, we have nothing to do.
		// Should never happen.
		if(dobjList_ == nil)
			return;

		// Vector to keep track of our matches.
		l = new Vector(dobjList_.length);

		// Go through the object list.
		dobjList_.forEach(function(o) {
			// If the object doesn't have a report manager, bail.
			if(o.obj_.reportManager == nil)
				return;

			// Check to see if the report manager handles this
			// kind of action.
			if(!o.obj_.reportManager.reportManagerMatchAction(self))
				return;

			// Remember this report manager.
			l.appendUnique(o.obj_.reportManager);
		});

		// Ping all of the report managers we got above.
		l.forEach(function(o) { o.afterActionMain(); });
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

	reportInPrep(txt) {
		return('<<txt>> <<objInPrep>> <<theNameObj>>');
	}
;

modify Actor
	reportInPrep(txt) {
		return('<<theNamePossAdj>> <<txt>>');
	}
;

modify Room
	reportInPrep(txt) {
		return('<<txt>> on the ground');
	}
;
