#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the reportManager library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

versionInfo: GameID;
gameMain: GameMainDef initialPlayerChar = me;

// Our report manager.  All it does is summarize the >EXAMINE command on
// the balls.
ballReportManager: ReportManager
	// Replacement for the stock ReportManager method.  This is
	// the entry point for our custom report logic.
	summarizeReport(vec, txt) {
		// All we do is summarize >EXAMINE actions on more than on
		// ball.
		summarizeExamines(txt);
	}

	// Summarize the examines.  The argument is a StringBuffer we
	// can add things to.
	summarizeExamines(txt) {
		local l;

		// If we don't remember examining any balls this turn,
		// we have nothing to summarize.
		if((l = getReportData('examine')) == nil)
			return;

		// Append a summary of the objects examined.
		txt.append('It\'s <<objectLister.makeSimpleList(l)>>. ');
	}
;

// A class for the objects we're going to summarize.
// The only interesting thing about the class is that the objects are
// identical except for their color.
class Ball: Thing 'ball*balls' 'ball'
	"A <<color>> ball. "

	// The color property.  Needs to be a single-quoted string.
	color = nil

	// Set up each Ball instance at the start of the game.  We need to
	// do this to handle the per-color vocabulary.
	initializeThing() {
		inherited();
		setColor();
	}

	// Tweak the vocabulary to reflect the ball's color.
	setColor() {
		if(color == nil)
			color = 'colorless';
		cmdDict.addWord(self, color, &adjective);
		name = '<<color>> ball';
	}

	// Hook for the report manager.
	dobjFor(Examine) {
		action() {
			// Do whatever we'd do normally.
			inherited();

			// Ping the report manager.
			ballReportManager.rememberReportData('examine', self);
		}
	}
;

startRoom: Room 'Void' "This is a featureless void.";
+me: Person;
// A bunch of ball instances.
+redBall: Ball color = 'red';
+greenBall: Ball color = 'green';
+blueBall: Ball color = 'blue';
