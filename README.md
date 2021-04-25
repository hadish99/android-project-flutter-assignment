HW3 - Dry questions

1. In order to control the Snapping Sheet, we use the SnappingSheetController class.
    it gives us ability to control the parent widget (the sheet) in multiple ways,
     such as controlling the snapping position etc. also we can extract information from the
     sheet, like it's current position or if currently snapping etc. 

2. In order to edit the snap positions of the bottom sheet, we use the snappingPositions parameter.
    this parameter takes in a list of SnappingPosition.factor or SnappingPosition.pixels. these are 
    used to specify the location using a factor or pixels 

3. Material design applications typically react to touches with ink splash effects, so the InkWell
    is more proper, as it implements this effect and can be used in place of GestureDetector for
    handling taps.
   If GestureDetector has a child, it defers to that child for its sizing behavior. and If it 
    does not have a child, it grows to fit the parent instead. while in the other hand, 
    an InkWell's splashes will not properly update to conform to changes if the size of its
    underlying Material, where the splashes are rendered, changes during animation.
    so we have to avoid using InkWells within Material widgets that are changing size.