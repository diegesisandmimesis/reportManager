#charset "us-ascii"
//
// reportManagerReportName.t
//
//	Additional methods on Thing for report-specific distinguishers.
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

modify Thing
	reportName = name
	pluralReportName = (pluralNameFrom(reportName))

	pluralNameOwnerLoc(ownerPriority) {
		local owner;

		if(((owner = getNominalOwner()) != nil)
			&& (ownerPriority || isDirectlyIn(owner))) {
			return(owner.theNamePossAdj + ' ' + pluralName);
		} else {
			return(location.childInNameWithOwner(pluralName));
		}
	}

	reportNameOwnerLoc(ownerPriority) {
		local owner;

		if(((owner = getNominalOwner()) != nil)
			&& (ownerPriority || isDirectlyIn(owner))) {
			return(owner.theNamePossAdj + ' ' + reportName);
		} else {
			return(location.childInNameWithOwner(reportName));
		}
	}

	pluralReportNameOwnerLoc(ownerPriority) {
		local owner;

		if(((owner = getNominalOwner()) != nil)
			&& (ownerPriority || isDirectlyIn(owner))) {
			return(owner.theNamePossAdj + ' ' + pluralReportName);
		} else {
			return(location.childInNameWithOwner(pluralReportName));
		}
	}
;
