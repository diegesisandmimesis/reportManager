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
	reportManagerFor = Ball
	reportManagerAnnounceText = 'balls'
;
+ReportSummary @ExamineAction
	// Summarize the examines.
	summarize(data) {
		return('It\'s <<objectLister.makeSimpleList(data.objs)>>. ');
	}
;
+ReportSummary @LookInAction
	summarize(data) {
		return('It\'s <<objectLister.makeSimpleList(data.objs)>>. ');
	}
;
+ReportSummary @SmellAction
	summarize(data) { return('They all smell the same. '); }
;

// A class for the objects we're going to summarize.
// The only interesting thing about the class is that the objects are
// identical except for their color.
class Ball: Thing 'ball*balls' 'ball'
	"A <<color>> ball. "

	reportManager = ballReportManager

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
;

startRoom: Room 'Void' "This is a featureless void.";
+me: Person;
// A bunch of ball instances with a pebble in the middle.
+redBall: Ball color = 'red';
+pebble: Thing '(small) (round) pebble' 'pebble' "A small, round pebble. ";
+greenBall: Ball color = 'green';
+blueBall: Ball color = 'blue';
