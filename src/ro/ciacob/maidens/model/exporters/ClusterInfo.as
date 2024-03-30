package ro.ciacob.maidens.model.exporters {

import ro.ciacob.maidens.legacy.MusicUtils;
import ro.ciacob.maidens.legacy.ProjectData;
import ro.ciacob.maidens.legacy.constants.DataFields;


import ro.ciacob.math.Fraction;
import ro.ciacob.utils.Strings;

public class ClusterInfo {

    private var _duration:Fraction;
    private var _pitches:Vector.<NoteInfo>;
    private var _uid:String;
    private var _startTime:Fraction;

    /**
     * Helper; builds a ClusterInfo instance from a given "cluster" ProjectData instance.
     * @param   cluster
     *          The source ProjectData instance to build a ClusterInfo instance from.
     *
     * @return  A new ClusterInfo instance.
     */
    public static function fromCluster(cluster:ProjectData):ClusterInfo {
        var clusterDuration:Fraction = Fraction.fromString(cluster.getContent(
                DataFields.CLUSTER_DURATION_FRACTION) as String);

        // Factor-in the augmentation dot if available.
        var dotSrc:String = (cluster.getContent(DataFields.DOT_TYPE) as String);
        if (dotSrc != DataFields.VALUE_NOT_SET) {
            var dot:Fraction = Fraction.fromString(dotSrc);
            var toAdd:Fraction = clusterDuration.multiply(dot) as Fraction;
            clusterDuration = clusterDuration.add(toAdd) as Fraction;
        }

        var pitchesInfo:Vector.<NoteInfo> = new Vector.<NoteInfo>;
        var i:int;
        var numNotes:uint = cluster.numDataChildren;
        var noteNode:ProjectData;
        var notePitch:uint;
        var ties:Boolean;
        var noteInfo:NoteInfo;
        for (i = 0; i < numNotes; i++) {
            noteNode = (cluster.getDataChildAt(i) as ProjectData);
            notePitch = MusicUtils.noteToMidiNumber(noteNode);
            ties = (noteNode.getContent(DataFields.TIES_TO_NEXT_NOTE) as Boolean);
            noteInfo = new NoteInfo(notePitch, false, ties);
            pitchesInfo.push(noteInfo);
        }
        return new ClusterInfo(cluster.route, clusterDuration, pitchesInfo);
    }

    /**
     * Examines the NoteInfo instances of both `cluster` and `nextCluster` given ClusterInfo instances,
     * and determines which ties are legit and which are bogus; updates the involved NoteInfo instances in the
     * process.
     * @param   cluster
     *          Left-hand ClusterInfo to examine.
     *
     * @param   nextCluster
     *          Right-hand ClusterInfo to examine.
     */
    public static function proofTies(cluster:ClusterInfo, nextCluster:ClusterInfo):void {
        if (!cluster) {
            return;
        }
        var clusterPitches:Vector.<NoteInfo> = cluster.pitches;
        var nextClusterPitches:Vector.<NoteInfo> = new Vector.<NoteInfo>;
        if (nextCluster && nextCluster.pitches) {
            nextClusterPitches = nextCluster.pitches;
        }
        if (!clusterPitches || !clusterPitches.length) {
            return;
        }
        var i:int;
        var numClusterPitches:uint = clusterPitches.length;
        var numNextClusterPitches:uint = nextClusterPitches.length;
        var clusterPitch:NoteInfo;
        var nextClusterPitch:NoteInfo;
        var clusterEndTime:Fraction = (cluster.startTime.add(cluster.duration) as Fraction);
        for (i = 0; i < numClusterPitches; i++) {
            clusterPitch = clusterPitches[i];
            nextClusterPitch = _getMatchFor(clusterPitch, nextClusterPitches);
            if (!nextClusterPitch) {
                clusterPitch.tiesRight = false;
                continue;
            }
            if (clusterPitch.tiesRight) {
                if (clusterEndTime.equals(nextCluster.startTime) && numNextClusterPitches > 0) {

                    // Legit tie; if this "pitch" starts a tie, we assign it a "tie group" id, one that we will also
                    // copy over to all the members of the tie.
                    if (!clusterPitch.tiesLeft) {
                        clusterPitch.tieGroupId = Strings.UUID;
                    }
                    nextClusterPitch.tiesLeft = true;
                    nextClusterPitch.tieGroupId = clusterPitch.tieGroupId;
                } else {

                    // Bogus tie, clear
                    clusterPitch.tiesRight = false;
                    nextClusterPitch.tiesLeft = false;
                }
            }
        }
    }

    public function ClusterInfo(uid:String, duration:Fraction, pitches:Vector.<NoteInfo>) {
        _uid = uid;
        _duration = duration;
        _pitches = pitches;
        _pitches.sort(__byMidiNumber);
    }

    public function get uid():String {
        return _uid;
    }

    public function get duration():Fraction {
        return _duration;
    }

    public function get pitches():Vector.<NoteInfo> {
        return _pitches;
    }

    public function get startTime():Fraction {
        return _startTime;
    }

    public function set startTime(value:Fraction):void {
        _startTime = value;
    }

    public function toString():String {
        return ('[ClusterInfo: ' + _uid + ' @' + _startTime + ' | ' + _duration + ' | {' + pitches.join(',') + '}]');
    }

    /**
     * Helper function to be used for sorting NoteInfo instances by their MIDI pitch.
     *
     * @param   pitchA
     *          NoteInfo instance to compare.
     *
     * @param   pitchB
     *          Another NoteInfo instance to compare.
     *
     * @return  An integer value; see Array.sort() for details.
     */
    private static function __byMidiNumber(pitchA:NoteInfo, pitchB:NoteInfo):int {
        return (pitchA.midiPitch - pitchB.midiPitch);
    }

    /**
     * Returns the first NoteInfo instance found in the `inCollection` Vector that has the same "midiPitch" as the one
     * of the given `pitch`. Returns `null` if none found.
     */
    private static function _getMatchFor(pitch:NoteInfo, inCollection:Vector.<NoteInfo>):NoteInfo {
        var i:int;
        var numTestPitches:uint = inCollection.length;
        var testPitch:NoteInfo;
        for (i = 0; i < numTestPitches; i++) {
            testPitch = inCollection[i];
            if (pitch.midiPitch == testPitch.midiPitch) {
                return testPitch;
            }
        }
        return null;
    }
}
}
