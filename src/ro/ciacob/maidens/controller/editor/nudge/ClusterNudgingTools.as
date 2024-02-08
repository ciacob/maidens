package ro.ciacob.maidens.controller.editor.nudge {
import ro.ciacob.desktop.data.DataElement;
import ro.ciacob.maidens.model.constants.DataFields;

/**
 * Contains utility static functions dedicated to "nudging" (i.e., sliding by one slot or position) the Clusters of a
 * musical Score in MAIDENS.
 *
 *
 * Notes:
 * - consider that the name of this feature in the user-facing UI is likely to be changed soon, i.e., to "moving" or
 *   "sliding" instead of "nudging". If/when this happens, the term "nudging" will be kept internally, for historic
 *   considerations.
 *
 * - while the "nudging" process essentially deals with swapping _one_ Cluster for another (if group selection should
 *   become available in the UI, "nudging" several selected Clusters will internally translate to individually nudging
 *   them), this is different for tuplets (e.g., "triplet", "quintuplet", etc.). As things can exponentially grow in
 *   complexity with tuplets (e.g., what should happen if the user tries to "nudge" a regular Cluster, say a
 *   quarter/crotchet over a tuplet Cluster, say, a triplet eight/quaver?), we treat all tuplets as monolithic blocks,
 *   and they abide by the following rules:
 *
 *   -- _inside_ a tuplet, nudging works as it would usually do, e.g., in a C,D,E eights triplet, the user can "nudge"
 *      the "C" to the right, and they will get the D,C,E triplet.
 *
 *   -- _outside_ of a tuplet, the tuplet starts to act as a monolithic block, e.g., if we had a regular quarter C in front
 *      of the afore-mentioned C,D,E triplet, and the user attempts to nudge it right, it will skip the triplet entirely,
 *      and "land" on its other side, so that the score becomes C,D,E (the triplet) and _then_ the C (the regular
 *      quarter). The very same should happen if the user attempts to "nudge" the first or last Clusters of the triplet
 *      over regular Clusters: the tuplet (here, a triplet) is "nudged" in its entirety instead.
 *
 * - "nudging" can happen in "constrained" or "unconstrained" mode. In constrained mode, Clusters are prevented from
 *   being nudged outside their home Measure; in unconstrained mode, they can cross both their home Measure and Section,
 *   essentially being allowed to travel throughout the entire Score if the user so chooses. This applies to both
 *   regular Clusters and to tuplets (which maintain the rules and regulations previously stated for them).
 *
 * Specific terminology:
 * - "mover" (or derived terms): relates to a Cluster the user has selected in the editor and is attempting to "nudge"
 *   right or left, by using one of the available "nudge" buttons in the toolbar. So, in a score of four quarters,
 *   F,G,A,B, if the user selects the "G" and clicks the "nudge left" button, the score becomes G,F,A,B. In this case,
 *   the "G" was the "mover", because it "moved" from its original position.
 *
 * - "replacer" (or derived terms): relates to a Cluster that will, by means of its position adjacent to the
 *   "mover", take the mover's original position in the Score (conversely, the "mover" will take the replacer's position).
 *    So, again, in a score of four quarters, F,G,A,B, if the user selects the "G" and clicks the "nudge left" button,
 *    the score becomes G,F,A,B. In this case, the "F" was the "replacer", because it came to "replace" the slot the "G"
 *    originally occupied.
 *
 * - "Cluster", "Voice", "Measure", "Part", "Score", they all refer to MAIDEN's "Project Hierarchy",
 *   see https://github.com/ciacob/maidens/wiki/1.2.-The-Project-Hierarchy for details.
 *
 * - "cross-nudge": nudging (in "unconstrained" mode) into a different Measure (and Section, if need be) than the
 *   original one.
 */

public class ClusterNudgingTools {
    public function ClusterNudgingTools() {
    }

    /**
     * To be used as exit point in `analyzeNudge()` when none of the valid scenarios below has been identified.
     */
    public static const SCENARIO_INVALID_NUDGE:int = -1;

    /**
     * DETAIL: "replacer" is missing (cannot be found), which can happen in two conditions:
     *  (i) cross-nudging (left or right) into an empty Measure/Voice ("empty" meaning that it has no Clusters at all);
     * (ii) regular right nudge of the last Cluster of an underful Voice ("underful" meaning it has Clusters that do not
     *      amount to the needed musical duration of the parent Measure).
     * RESOLUTION: copy "mover" to the empty "targetVoice".
     */
    public static const SCENARIO_NUDGE_EMPTY:int = 0;

    /**
     * DETAIL: both "mover" and "replacer" are found and none of them is part of a tuplet.
     * RESOLUTION: swap "mover" with "replacer".
     */
    public static const SCENARIO_NUDGE_REGULAR:int = 1;

    /**
     * DETAIL: both "mover" and "replacer" are found; "mover" IS NOT part of a tuplet, and "replacer" IS part of a
     * tuplet.
     * RESOLUTION: swap "mover" with all the Clusters (in block) of the tuplet the "replacer" is part of.
     */
    public static const SCENARIO_REGULAR_OVER_TUPLET:int = 2;

    /**
     * DETAIL: both "mover" and "replacer" are found; "mover" IS part of a tuplet, and "replacer" IS NOT part of a
     * tuplet.
     * RESOLUTION: swap all the Clusters (in block) of the tuplet the "mover" is part of, with "replacer".
     */
    public static const SCENARIO_TUPLET_OVER_REGULAR:int = 3;

    /**
     * DETAIL: both "mover" and "replacer" are found, and each is part of a different tuplet. This can only happen if
     * they live at the borders (first/last Cluster) of adjacent tuplets, be it tuplets that live in the same Measure,
     * or in two adjacent Measures.
     * RESOLUTION: swap, in block, all the Clusters of one tuplet with all the Clusters of the other.
     */
    public static const SCENARIO_TUPLET_OVER_TUPLET:int = 4;

    /**
     * DETAIL: both "mover" and "replacer" are found, they both are part of the same tuplet, and none of them is the
     * tuplet root (i.e., the first Cluster of the tuplet, the one holding the tuplet definition).
     * RESOLUTION: swap "mover" and "replacer" (as usual).
     */
    public static const SCENARIO_INSIDE_TUPLET_REGULAR:int = 5;

    /**
     * DETAIL: both "mover" and "replacer" are found, and they both are part of the same tuplet; "replacer" is the
     * tuplet root (the first Cluster of the tuplet, holding the tuplet definition).
     * RESOLUTION: copy tuplet definition from "replacer" to "mover", then swap "mover" and "replacer" as usual.
     */
    public static const SCENARIO_INSIDE_TUPLET_TO_ROOT:int = 6;

    /**
     * DETAIL: both "mover" and "replacer" are found, and they both are part of the same tuplet; "mover" is the tuplet
     * root (the first Cluster of the tuplet, holding the tuplet definition).
     * RESOLUTION: copy tuplet definition from "mover" to "replacer", then swap "mover" and "replacer" as usual.
     */
    public static const SCENARIO_INSIDE_TUPLET_FROM_ROOT:int = 7;

    /**
     * Main entry point into the "nudging" routine for Clusters.
     *
     * @param   mover
     *          The Cluster being moved (a DataElement instance).
     *
     * @param   step
     *          Direction and amount of the "nudge" operation, i.e., `1` would mean "nudge right by one step",
     *          whereas `-2` would mean "nudge left by two steps".
     */
    public static function nudgeCluster(mover:DataElement, step:int):void {
        var tupletClusters:Vector.<DataElement>;
        var i:int;
        var tupletCluster:DataElement;
        var moverGroup:Vector.<DataElement> = new Vector.<DataElement>;
        var replacerGroup:Vector.<DataElement> = new Vector.<DataElement>;
        var swapInfo:SwapInfo = getSwapInfo(mover, step);
        var sourceCluster:DataElement = swapInfo.source;
        var targetCluster:DataElement = swapInfo.target;
        var targetVoice:DataElement = swapInfo.targetVoice;
        var scenario:int = analyzeNudge(sourceCluster, targetCluster, targetVoice);

        switch (scenario) {
            case SCENARIO_NUDGE_EMPTY:
                // Copy "mover" to the empty "targetVoice" (or all the Clusters in its tuplet, if applicable).
                if (isTupletCluster(sourceCluster)) {
                    tupletClusters = getTupletClusters(sourceCluster);
                    for (i = 0; i < tupletClusters.length; i++) {
                        tupletCluster = tupletClusters[i];
                        moverGroup.push(tupletCluster);
                    }
                } else {
                    moverGroup.push(sourceCluster);
                }
                swapClusters(moverGroup, replacerGroup, targetVoice);
                break;
            case SCENARIO_NUDGE_REGULAR: // Those two are practically identical.
            case SCENARIO_INSIDE_TUPLET_REGULAR:
                // Swap "mover" with "replacer".
                moverGroup.push(sourceCluster);
                replacerGroup.push(targetCluster);
                swapClusters(moverGroup, replacerGroup);
                break;
            case SCENARIO_REGULAR_OVER_TUPLET:
                // Swap "mover" with all the Clusters (in block) of the tuplet the "replacer" is part of.
                moverGroup.push(sourceCluster);
                replacerGroup = getTupletClusters(targetCluster);
                swapClusters(moverGroup, replacerGroup);
                break;
            case SCENARIO_TUPLET_OVER_REGULAR:
                // Swap all the Clusters (in block) of the tuplet the "mover" is part of with "replacer".
                moverGroup = getTupletClusters(sourceCluster);
                replacerGroup.push(targetCluster);
                swapClusters(moverGroup, replacerGroup);
                break;
            case SCENARIO_TUPLET_OVER_TUPLET:
                // Swap (in block) all the Clusters of the tuplet the "mover" is part of with all the Clusters of the
                // tuplet the "replacer" is part of.
                moverGroup = getTupletClusters(sourceCluster);
                replacerGroup = getTupletClusters(targetCluster);
                swapClusters(moverGroup, replacerGroup);
                break;
            case SCENARIO_INSIDE_TUPLET_TO_ROOT:
                // Copy tuplet definition from "replacer" to "mover", then swap "mover" and "replacer" as usual.
                passTupletOwnership(targetCluster, sourceCluster);
                moverGroup.push(sourceCluster);
                replacerGroup.push(targetCluster);
                swapClusters(moverGroup, replacerGroup);
                break;
            case SCENARIO_INSIDE_TUPLET_FROM_ROOT:
                // Copy tuplet definition from "mover" to "replacer", then swap "mover" and "replacer" as usual.
                passTupletOwnership(sourceCluster, targetCluster);
                moverGroup.push(sourceCluster);
                replacerGroup.push(targetCluster);
                swapClusters(moverGroup, replacerGroup);
                break;
        }
    }

    /**
     * Attempts to retrieve as much as possible of the information needed by the `swapClusters` function, based on
     * a given `mover` Cluster and a `step` describing its motion.
     *
     * @param   mover
     *          The Cluster being moved (a DataElement instance).
     *
     * @param   step
     *          Direction and amount of the "nudge" operation, i.e., `1` would mean "nudge right by one step",
     *          whereas `-2` would mean "nudge left by two steps".
     *
     * @return  An instance of the internal SwapInfo class that contains information ready to be passed along to the
     *          `swapClusters()` function.
     */
    public static function getSwapInfo(mover:DataElement, step:int):SwapInfo {

        // If there is no mover and/or no amount, there is no nudge, so we can exit already.
        if (!mover || !step) {
            return null;
        }

        // If replacer was found within the mover's Voice, then this is a "constrained nudge", and the mover's Voice is
        // also the replacer's Voice (because "nudging" happens within the same Measure/Voice), so we just return it and
        // exit.
        var isLeftNudge:Boolean = (step < 0);
        var moverIndex:int = mover.index;
        var moverVoice:DataElement = mover.dataParent;
        var replacer:DataElement = moverVoice.getDataChildAt(moverIndex + step);
        if (replacer) {
            return (isLeftNudge ?
                    new SwapInfo(mover, replacer, moverVoice) :
                    new SwapInfo(replacer, mover, moverVoice));
        }
        // If replacer could not be found by looking in the mover's voice, then we are "nudging" in "unconstrained"
        // mode, and we will need to do some advanced searching by climbing the hierarchy instead.
        var score:DataElement;
        var replacerVoice:DataElement;
        var replacerMeasure:DataElement;
        var replacerPart:DataElement;
        var replacerSection:DataElement;
        var moverSection:DataElement;
        var moverSectionIndex:int;
        var moverVoiceIndex:int = moverVoice.index;
        var moverMeasure:DataElement = moverVoice.dataParent;
        var moverMeasureIndex:int = moverMeasure.index;
        var moverPart:DataElement = moverMeasure.dataParent;
        var moverPartIndex:int = moverPart.index;

        // It might be enough to look at the closest sibling Measure, but if we are already at the start or end of the
        // current Section, it will be not. In this case, we need to go higher, and look at the closest sibling Section,
        // if any (because we might be in the first or last Section as well).
        if (isLeftNudge) {
            if (moverMeasureIndex > 0) { // not first Measure
                replacerMeasure = moverPart.getDataChildAt(moverMeasureIndex - 1);
                replacerVoice = replacerMeasure.getDataChildAt(moverVoiceIndex);
                replacer = replacerVoice.numDataChildren ?
                        replacerVoice.getDataChildAt(replacerVoice.numDataChildren - 1) : null;
            } else { // first Measure
                moverSection = moverPart.dataParent;
                moverSectionIndex = moverSection.index;
                if (moverSectionIndex > 0) { // must not be first Section (return `null` otherwise)
                    score = moverSection.dataParent;
                    replacerSection = score.getDataChildAt(moverSectionIndex - 1);
                    replacerPart = replacerSection.getDataChildAt(moverPartIndex);
                    replacerMeasure = replacerPart.getDataChildAt(replacerPart.numDataChildren - 1); // last Measure inside previous Section
                    replacerVoice = replacerMeasure.getDataChildAt(moverVoiceIndex);
                    replacer = replacerVoice.numDataChildren ?
                            replacerVoice.getDataChildAt(replacerVoice.numDataChildren - 1) : null;
                }
            }
        } else {
            // i.e., right "nudge"
            if (moverMeasureIndex < moverPart.numDataChildren - 1) { // not last Measure
                replacerMeasure = moverPart.getDataChildAt(moverMeasureIndex + 1);
                replacerVoice = replacerMeasure.getDataChildAt(moverVoiceIndex);
                replacer = replacerVoice.numDataChildren ?
                        replacerVoice.getDataChildAt(0) : null;
            } else { // last Measure
                moverSection = moverPart.dataParent;
                moverSectionIndex = moverSection.index;
                score = moverSection.dataParent;
                if (moverSectionIndex < score.numDataChildren - 1) { // must not be last Section (`return `null` otherwise)
                    replacerSection = score.getDataChildAt(moverSectionIndex + 1);
                    replacerPart = replacerSection.getDataChildAt(moverPartIndex);
                    replacerMeasure = replacerPart.getDataChildAt(0); // first Measure inside next Section
                    replacerVoice = replacerMeasure.getDataChildAt(moverVoiceIndex);
                    replacer = replacerVoice.numDataChildren ?
                            replacerVoice.getDataChildAt(0) : null;
                }
            }
        }
        return (isLeftNudge ?
                new SwapInfo(mover, replacer, replacerVoice) :
                replacer ?
                        new SwapInfo(replacer, mover, replacerVoice) :
                        mover ? new SwapInfo(mover, replacer, replacerVoice) :
                                new SwapInfo(null, null, null));
    }

    /**
     * Given "mover" and "replacer" Clusters, this function identifies all the Clusters impacted by the nudge operation
     * as well as the exact nudge scenario to be followed.
     *
     * @param   mover
     *          The Cluster being moved (a DataElement instance).
     *
     * @param   replacer
     *          The Cluster the "mover" is moved onto (i.e., the one replacing the "mover").
     *
     * @param   replacerVoice
     *          The Voice container to hold "mover" once the nudging is done. Optional, if given, it will be
     *          passed along and become throughout the returned NudgeAnalysisResult instance.
     *
     * @return  A matching scenario, as one of the int constants `SCENARIO_...` defined by this class..
     */
    public static function analyzeNudge(mover:DataElement,
                                        replacer:DataElement,
                                        replacerVoice:DataElement = null):int {


        // Case: "replacer" is missing (not found).
        if (mover && !replacer && replacerVoice) {
            return SCENARIO_NUDGE_EMPTY;
        }

        // Case: both "mover" and "replacer" are found and none of them is part of a tuplet.
        if (mover && replacer && !isTupletCluster(mover) && !isTupletCluster(replacer)) {
            return SCENARIO_NUDGE_REGULAR;
        }

        // Case: both "mover" and "replacer" are found; "mover" IS NOT part of a tuplet, and "replacer" IS part of
        // a tuplet.
        if (mover && replacer && !isTupletCluster(mover) && isTupletCluster(replacer)) {
            return SCENARIO_REGULAR_OVER_TUPLET;
        }

        // Case: both "mover" and "replacer" are found; "mover" IS part of a tuplet, and "replacer" IS NOT part of a
        // tuplet.
        if (mover && replacer && isTupletCluster(mover) && !isTupletCluster(replacer)) {
            return SCENARIO_TUPLET_OVER_REGULAR;
        }

        // Case: both "mover" and "replacer" are found, and each is part of a different tuplet.
        if (mover && replacer && isTupletCluster(mover) && isTupletCluster(replacer) &&
                !insideSameTuplet(mover, replacer)) {
            return SCENARIO_TUPLET_OVER_TUPLET;
        }

        // Case: both "mover" and "replacer" are found, they both are part of the same tuplet, and none of them is the
        // tuplet root.
        if (mover && replacer && insideSameTuplet(mover, replacer) && !isTupletRoot(mover) &&
                !isTupletRoot(replacer)) {
            return SCENARIO_INSIDE_TUPLET_REGULAR;
        }

        // Case: both "mover" and "replacer" are found, and they both are part of the same tuplet; "replacer" is the
        // tuplet root.
        if (mover && replacer && insideSameTuplet(mover, replacer) && isTupletRoot(replacer)) {
            return SCENARIO_INSIDE_TUPLET_TO_ROOT;
        }

        // Case: both "mover" and "replacer" are found, and they both are part of the same tuplet; "mover" is the tuplet
        // root.
        if (mover && replacer && insideSameTuplet(mover, replacer) && isTupletRoot(mover)) {
            return SCENARIO_INSIDE_TUPLET_FROM_ROOT;
        }

        // If we reach here, no valid scenario was identified.
        return SCENARIO_INVALID_NUDGE;
    }

    /**
     * Determines whether given `cluster` is part of a tuplet (either the "root" of the tuplet, i.e., the Cluster that
     * starts it), or one of the subsequent notes of that tuplet.
     *
     * @param   cluster
     *          A Cluster to check.
     *
     * @return  Returns `true` if `cluster` is part of a tuplet, `false` otherwise.
     */
    public static function isTupletCluster(cluster:DataElement):Boolean {
        return (cluster &&
                (cluster.getContent(DataFields.TUPLET_ROOT_ID) as String) != DataFields.VALUE_NOT_SET ||
                (cluster.getContent(DataFields.STARTS_TUPLET) as Boolean));
    }

    /**
     * Determines whether the given `cluster` is the "root" of a tuplet, i.e., the Cluster that starts it and carries
     * the tuplet definition.
     *
     * @param   cluster
     *          A Cluster to check.
     *
     * @return  Returns `true` if `cluster` is the "root" of a tuplet, `false` otherwise.
     */
    public static function isTupletRoot(cluster:DataElement):Boolean {
        if (cluster) {
            var startsTuplet:Boolean = (cluster.getContent(DataFields.STARTS_TUPLET) as Boolean);
            return (startsTuplet && startsTuplet != DataFields.VALUE_NOT_SET);
        }
        return false;
    }

    /**
     * Given a DataElement instance representing a Cluster that might be inside of a tuplet, returns a Vector of
     * DataElement instances representing all members of that tuplet (provided that `testCluster` was indeed a member
     * of any tuplet).
     *
     * @param   testCluster
     *          A DataElement representing a Cluster that might be (anywhere) inside a tuplet.
     *
     * @return  A Vector of DataElement instances representing, in order, all the members of the tuplet the
     *          `testCluster` is part of (including `testCluster` itself). Returns an empty Vector if given
     *          `testCluster` was null or not actually part of any tuplet.
     */
    public static function getTupletClusters(testCluster:DataElement):Vector.<DataElement> {
        var tupletMembers:Vector.<DataElement> = new Vector.<DataElement>;
        var isTupletRoot:Boolean = (testCluster && testCluster.getContent(DataFields.STARTS_TUPLET) as Boolean);

        // Case (a): given `testCluster` is the root of the tuplet.
        if (isTupletRoot) {
            return getTupletByRoot(testCluster);
        }

        // Case (b): given `testCluster` is anything but the root of the tuplet.
        var tupletRootId:String = testCluster ? testCluster.getContent(DataFields.TUPLET_ROOT_ID) as String : null;
        if (tupletRootId) {
            var tupletRoot:DataElement = testCluster.getElementByRoute(tupletRootId);
            if (tupletRoot) {
                return getTupletByRoot(tupletRoot);
            }
        }

        // Case (c): `testCluster` is null or unrelated to any tuplet.
        return tupletMembers;
    }

    /**
     * Given a DataElement instance representing a Cluster that is the root of a tuplet (i.e., the Cluster _defining_
     * the tuplet), returns a Vector of DataElement instances with all tuplet members in their natural order (including
     * the given `tupletRootCluster`).
     *
     * @param   tupletRoot
     *          A DataElement representing a Cluster that is the root of a tuplet.
     *
     * @return  A Vector of DataElement instances representing, in order, all the members of the tuplet (including given
     *          `tupletRoot`). Returns an empty Vector if given `tupletRoot` is null or not the root of any tuplet.
     */
    public static function getTupletByRoot(tupletRoot:DataElement):Vector.<DataElement> {
        var tupletMembers:Vector.<DataElement> = new Vector.<DataElement>;
        if (tupletRoot) {
            var tupletRootId:String = tupletRoot.route;
            var clusterIndex:int = tupletRoot.index;
            var clusterParent:DataElement = tupletRoot.dataParent;
            if (clusterParent) {
                var searchIndex:int = clusterIndex;
                do {
                    searchIndex++;
                    var searchCluster:DataElement = clusterParent.getDataChildAt(searchIndex) as DataElement;
                    if (!searchCluster) {
                        break;
                    }
                    var rootOfSearchCluster:String = (searchCluster.getContent(DataFields.TUPLET_ROOT_ID) as String);
                    if (rootOfSearchCluster != tupletRootId) {
                        break;
                    }
                    tupletMembers.push(searchCluster);
                } while (true);
                if (tupletMembers.length) {
                    tupletMembers.unshift(tupletRoot);
                }
            }
        }
        return tupletMembers;
    }

    /**
     * Given two clusters, `clusterA` and `clusterB`, establishes whether they are both part of the same tuplet.
     *
     * Note: this function also returns `false` if either of the two is unrelated to any tuplet. An additional check is
     * needed in order to detect if `clusterA` and `clusterB` are part of different tuplets (e.g., use the
     * `isTupletCluster()` function).
     *
     * @param   clusterA
     *          One of the Clusters to test for being part of the same tuplet.
     *
     * @param   clusterB
     *          The other of the Clusters to test for being part of the same tuplet.
     *
     * @return  Returns `true` if both operands are non-null, and part of the same tuplet. Returns `false` in any other
     *          conceivable situation.
     */
    public static function insideSameTuplet(clusterA:DataElement, clusterB:DataElement):Boolean {
        var tupletA:Vector.<DataElement> = getTupletClusters(clusterA);
        var tupletB:Vector.<DataElement> = getTupletClusters(clusterB);
        return (tupletA && tupletB && tupletA.length && tupletB.length && tupletA[0] === tupletB[0]);
    }

    /**
     * Passes tuplet definition data from given `from` Cluster (a DataElement instance) to given `to` Cluster (also a
     * DataElement instance).
     *
     * @param   $from
     *          Tuplet Cluster to move tuplet definition from.
     *
     * @param   $to
     *          Tuplet Cluster to move tuplet definition from.
     *
     * Note: this is a low-level function, and does nothing to check whether `from` and `to` are non-null, part of the
     * same tuplet (and part of any tuplet at all), and if `from` is, indeed, the current root of the tuplet. All this
     * checks must be performed BEFORE actually reaching this function.
     */
    public static function passTupletOwnership($from:DataElement, $to:DataElement):void {
        var tupletClusters:Vector.<DataElement> = getTupletClusters($from);
        var cluster:DataElement;
        for (var i:int = 0; i < tupletClusters.length; i++) {
            cluster = tupletClusters[i];
            if (cluster === $to) {
                cluster.setContent(DataFields.STARTS_TUPLET, true);
                cluster.setContent(DataFields.TUPLET_ROOT_ID, DataFields.VALUE_NOT_SET);
            } else {
                if (cluster == $from) {
                    cluster.setContent(DataFields.STARTS_TUPLET, false);
                }
                cluster.setContent(DataFields.TUPLET_ROOT_ID, $to.route);
            }
        }
    }


    /**
     * Switches places of two group of Clusters (DataElement instances), respecting the relative order of the group
     * elements.
     *
     * @param   sourceGroup
     *          One of the two groups to swap.
     *
     * @param   targetGroup
     *          The other one of the two groups to swap.
     *
     * @param   targetVoice
     *          Optional. Only needed if `targetGroup` is empty (otherwise, the `targetVoice` is inferred from the
     *          first element in the `targetGroup`.
     *
     * Notes: (1) The function treats the groups as being contiguous, and as belonging to the same Voice / Measure. If
     *        they are NOT contiguous, the interstices (i.e., the `null` elements) are not transferred; also, the parent
     *        Voice of the group is considered to be the Voice of the first Cluster in the group. Parent Voices of
     *        subsequent clusters (if different) are ignored.
     *
     *        (2) In order to produce expected results, `sourceGroup` must lie to the right of `targetGroup` in the
     *        Score. If the `targetGroup` is empty (and `targetVoice` is used instead) this restriction doesn't apply.
     */
    public static function swapClusters(sourceGroup:Vector.<DataElement>,
                                        targetGroup:Vector.<DataElement>,
                                        targetVoice:DataElement = null):void {

        // In order to continue, we need at least one non-orphaned Cluster at the first index of `sourceGroup` and
        // either (1) at least one non-orphaned Cluster at the first index of `targetGroup` or (2) the `targetVoice`
        // argument pointing to a valid Voice element.
        if (!sourceGroup.length || (!targetGroup.length && !targetVoice)) {
            return;
        }
        var firstSrcCluster:DataElement = sourceGroup[0];
        var firstTargetCluster:DataElement = targetGroup.length ? targetGroup[0] : null;
        if (!firstSrcCluster || (!firstTargetCluster && !targetVoice)) {
            return;
        }
        var sourceVoice:DataElement = firstSrcCluster.dataParent;
        if (firstTargetCluster && firstTargetCluster.dataParent) {
            targetVoice = firstTargetCluster.dataParent;
        }
        if (!sourceVoice || !targetVoice) {
            return;
        }

        // Perform the swap
        var firstReplacerIndex:int = firstTargetCluster ? firstTargetCluster.index : 0;
        var i:int;
        var moverCluster:DataElement;
        var replacerCluster:DataElement;
        for (i = 0; i < sourceGroup.length; i++) {
            moverCluster = sourceGroup[i];
            if (moverCluster) {
                sourceVoice.removeDataChild(moverCluster);
            }
        }

        for (i = 0; i < targetGroup.length; i++) {
            replacerCluster = targetGroup[i] as DataElement;
            if (replacerCluster) {
                targetVoice.removeDataChild(replacerCluster);
            }
        }
        var newMoverIndex:int = firstReplacerIndex;
        var newReplacerIndex:int = (sourceVoice === targetVoice) ?
                (newMoverIndex + sourceGroup.length) : 0;
        for (i = sourceGroup.length - 1; i >= 0; i--) {
            moverCluster = sourceGroup[i] as DataElement;
            if (moverCluster) {
                targetVoice.addDataChildAt(moverCluster, Math.min(targetVoice.numDataChildren, newMoverIndex));
            }
        }
        for (i = targetGroup.length - 1; i >= 0; i--) {
            replacerCluster = targetGroup[i] as DataElement;
            if (replacerCluster) {
                sourceVoice.addDataChildAt(replacerCluster, newReplacerIndex);
            }
        }
    }

}
}

import ro.ciacob.desktop.data.DataElement;

/**
 * Internal class storing information in the format expected by the `swapClusters()` function.
 */
class SwapInfo {

    private var _source:DataElement;
    private var _target:DataElement;
    private var _targetVoice:DataElement;

    /**
     * The Cluster to be used as "source" inside the `swapClusters()` function.
     * @param   source
     *
     * @param   target
     *          The Cluster to be used as "target" inside the `swapClusters()` function. Can be null.
     *
     * @param   targetVoice
     *          The Voice needed by the `swapClusters()` function in case `target` is null.
     */
    public function SwapInfo(source:DataElement, target:DataElement, targetVoice:DataElement) {
        _source = source;
        _target = target;
        _targetVoice = targetVoice;
    }

    public function get source():DataElement {
        return _source;
    }

    public function get target():DataElement {
        return _target;
    }

    public function get targetVoice():DataElement {
        return _targetVoice;
    }
}
