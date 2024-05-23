#charset "us-ascii"
//
// reportManagerDistinguisher.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

// Now we modify the distinguishers.
// We add an "aOrCountName" method to each, which we use for 
modify nullDistinguisher
	aOrCountName(obj, n) {
		return((n == 1) ? name(obj) : obj.countName(n));
	}
	singlePluralName(obj, n) {
		return((n == 1) ? name(obj) : obj.pluralName);
	}
	reportName(obj, n) {
		return((n == 1) ? obj.reportName : obj.pluralReportName);
	}
;

modify basicDistinguisher
	aOrCountName(obj, n) {
		return((n == 1) ? name(obj) : obj.countDisambigName(n));
	}
	singlePluralName(obj, n) {
		return((n == 1) ? name(obj) : obj.pluralName);
	}
	reportName(obj, n) {
		return((n == 1) ? obj.reportName : obj.pluralReportName);
	}
;

modify ownershipDistinguisher
	aOrCountName(obj, n) {
		return((n == 1)
			? name(obj) : obj.countNameOwnerLoc(n, true));
	}
	singlePluralName(obj, n) {
		return((n == 1) ? obj.aNameOwnerLoc(true) : obj.pluralNameOwnerLoc(true));
	}
	reportName(obj, n) {
		return((n == 1) ? obj.reportNameOwnerLoc(true) : obj.pluralReportNameOwnerLoc(true));
	}
;

modify locationDistinguisher
	aOrCountName(obj, n) {
		return((n == 1)
			? name(obj) : obj.countNameOwnerLoc(n, nil));
	}
	singlePluralName(obj, n) {
		return((n == 1) ? obj.aNameOwnerLoc(nil) : obj.pluralNameOwnerLoc(nil));
	}
	reportName(obj, n) {
		return((n == 1) ? obj.reportNameOwnerLoc(nil) : obj.pluralReportNameOwnerLoc(nil));
	}
;

modify litUnlitDistinguisher
	aOrCountName(obj, n) {
		return((n == 1) ? obj.aNameLit : obj.pluralNameLit);
	}
	singlePluralName(obj, n) {
		return((n == 1) ? obj.aNameLit : obj.pluralNameLit);
	}
	reportName(obj, n) {
		return(singlePluralName(obj, n));
	}
;
