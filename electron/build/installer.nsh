!macro customInit
  # For data bundle with installer
  #IfFileExists $INSTDIR\data +3 +1 
  #CreateDirectory $INSTDIR\data
  #CopyFiles $EXEDIR\data\* $INSTDIR\data
!macroend
