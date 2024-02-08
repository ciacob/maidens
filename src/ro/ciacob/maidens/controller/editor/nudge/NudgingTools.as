package ro.ciacob.maidens.controller.editor.nudge {
import ro.ciacob.maidens.model.ModelUtils;
import ro.ciacob.maidens.model.ProjectData;
import ro.ciacob.maidens.model.constants.DataFields;

public class NudgingTools {
    public function NudgingTools() {
    }

    public static function nudgeElement(element:ProjectData, step:int, constrainToParent:Boolean):ProjectData {
        if (ModelUtils.isPart(element)) {
            return nudgePartElement(element, step);
        }
        if (ModelUtils.isMeasure(element)) {
            return nudgeMeasureElement(element, step, constrainToParent);
        }
        if (ModelUtils.isVoice(element)) {
            return nudgeVoiceElement(element, step, constrainToParent);
        }
        if (ModelUtils.isCluster(element)) {
            ClusterNudgingTools.nudgeCluster(element, step);
            return element;
            //return nudgeCluster(element, step, constrainToParent);
        }
        return nudgeOrdinaryElement(element, step);
    }

    public static function nudgeMeasureElement(measureToNudge:ProjectData, step:int, constrainToParent:Boolean):ProjectData {
        // TODO: implement argument constrainToParent
        var currentPart:ProjectData = ProjectData(measureToNudge.dataParent);
        var currentSection:ProjectData = ProjectData(currentPart.dataParent);
        var allPartsInCurrentSection:Array = ModelUtils.getChildrenOfType(currentSection, DataFields.PART);
        var indexToNudge:int = measureToNudge.index;
        var currentReplacement:ProjectData = null;
        for (var i:int = 0; i < allPartsInCurrentSection.length; i++) {
            var somePart:ProjectData = ProjectData(allPartsInCurrentSection[i]);
            var someMeasure:ProjectData = ProjectData(somePart.getDataChildAt(indexToNudge));
            var someReplacement:ProjectData = nudgeOrdinaryElement(someMeasure, step);
            if (somePart == currentPart) {
                currentReplacement = someReplacement;
            }
        }
        return currentReplacement;
    }

    /**
     * When moving parts up or down in the score, care must be taken to treat stacks like a single unit,
     * e.g., treat a bunch of Violins that we meet along the way as a single Violin, and skip all of them
     * at once (because according to music theory, instruments of same type must stick together in the score).
     */
    public static function nudgePartElement(partToNudge:ProjectData, step:int):ProjectData {
        var offset:int = step;
        var isFirstOfStack:Boolean = true;
        do {
            var swapPart:ProjectData = partToNudge.dataParent.getDataChildAt(partToNudge.index + offset) as ProjectData;
            isFirstOfStack = swapPart.getContent(DataFields.PART_ORDINAL_INDEX) == 0;
            if (!isFirstOfStack) {
                offset += step;
            }
        } while (!isFirstOfStack);
        return nudgeOrdinaryElement(partToNudge, offset);
    }

    /**
     * Nudges a Voice element. Update the Voice's index and assigned staff as side effects
     */
    public static function nudgeVoiceElement(currentVoice:ProjectData, step:int, constrainToParent:Boolean):ProjectData {
        // TODO: implement argument "constrainToParent".
        var parentMeasure:ProjectData = currentVoice.dataParent as ProjectData;
        var exchangeIndex:int = currentVoice.index + step;
        var exchangeVoice:ProjectData = parentMeasure.getDataChildAt(exchangeIndex) as ProjectData;
        if (!exchangeVoice) {
            return currentVoice;
        }
        var currentSlot:Array = [currentVoice.getContent(DataFields.VOICE_INDEX), currentVoice.getContent(DataFields.STAFF_INDEX)];
        var exchangeSlot:Array = [exchangeVoice.getContent(DataFields.VOICE_INDEX), exchangeVoice.getContent(DataFields.STAFF_INDEX)];
        exchangeVoice.setContent(DataFields.VOICE_INDEX, currentSlot[0]);
        exchangeVoice.setContent(DataFields.STAFF_INDEX, currentSlot[1]);
        currentVoice.setContent(DataFields.VOICE_INDEX, exchangeSlot[0]);
        currentVoice.setContent(DataFields.STAFF_INDEX, exchangeSlot[1]);
        return nudgeOrdinaryElement(currentVoice, step);
    }


    /**
     * TODO: document
     * @param element
     * @param step
     * @return
     */
    public static function nudgeOrdinaryElement(element:ProjectData, step:int):ProjectData {
        element.enforceIndex(element.index + step, true, true);
        element.dataParent.resetIntrinsicMeta();
        return element;
    }
}
}
