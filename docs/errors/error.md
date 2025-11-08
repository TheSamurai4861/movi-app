(base) PS D:\Home\TheSamurai\DEV\FLUTTER\movi> dart analyze
Analyzing movi...

  error • lib\src\core\config\env\environment_loader.dart:25:48 • Arguments
          of a constant creation must be constant expressions. Try making   
          the argument a valid constant, or use 'new' to call the
          constructor. • const_with_non_constant_argument
  error • lib\src\core\config\providers\overrides.dart:8:6 • The name       
          'ProviderOverride' isn't a type, so it can't be used as a type    
          argument. Try correcting the name to an existing type, or defining
          a type named 'ProviderOverride'. • non_type_as_type_argument      
  error • lib\src\core\config\providers\overrides.dart:16:1 • Undefined     
          class 'ProviderOverride'. Try changing the name to the name of an 
          existing class, or creating a class with the name
          'ProviderOverride'. • undefined_class
  error • lib\src\core\config\providers\overrides.dart:20:1 • Undefined     
          class 'ProviderOverride'. Try changing the name to the name of an 
          existing class, or creating a class with the name
          'ProviderOverride'. • undefined_class
warning • lib\src\core\config\config_module.dart:6:8 • Unused import:       
          'models/network_endpoints.dart'. Try removing the import
          directive. • unused_import
warning • lib\src\core\config\services\platform_selector.dart:25:7 • This   
          default clause is covered by the previous cases. Try removing the 
          default clause, or restructuring the preceding patterns. •        
          unreachable_switch_default
   info • lib\src\core\theme\app_theme.dart:2:8 • The import of
          'package:flutter/widgets.dart' is unnecessary because all of the  
          used elements are also provided by the import of
          'package:flutter/material.dart'. Try removing the import
          directive. • unnecessary_import
   info • lib\src\core\widgets\movi_bottom_nav_bar.dart:71:46 •
          'withOpacity' is deprecated and shouldn't be used. Use
          .withValues() to avoid precision loss. Try replacing the use of   
          the deprecated member with the replacement. •
          deprecated_member_use
   info • lib\src\core\widgets\movi_marquee_text.dart:2:8 • The import of   
          'dart:ui' is unnecessary because all of the used elements are also
          provided by the import of 'package:flutter/material.dart'. Try    
          removing the import directive. • unnecessary_import
   info • lib\src\core\widgets\movi_primary_button.dart:95:49 •
          'withOpacity' is deprecated and shouldn't be used. Use
          .withValues() to avoid precision loss. Try replacing the use of   
          the deprecated member with the replacement. •
          deprecated_member_use
   info • lib\src\features\movie\presentation\pages\movie_detail_page.dart:29:60
          • 'surfaceVariant' is deprecated and shouldn't be used. Use       
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use
   info • lib\src\features\movie\presentation\pages\movie_detail_page.dart:105:68
          • 'surfaceVariant' is deprecated and shouldn't be used. Use       
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use
   info • lib\src\features\movie\presentation\pages\movie_detail_page.dart:131:62
          • 'surfaceVariant' is deprecated and shouldn't be used. Use       
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use
   info • lib\src\features\person\presentation\pages\person_detail_page.dart:20:68
          • 'surfaceVariant' is deprecated and shouldn't be used. Use       
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use
   info • lib\src\features\person\presentation\pages\person_detail_page.dart:75:68
          • 'surfaceVariant' is deprecated and shouldn't be used. Use       
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use
   info • lib\src\features\playlist\presentation\pages\playlist_detail_page.dart:24:60
          • 'surfaceVariant' is deprecated and shouldn't be used. Use       
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use
   info • lib\src\features\playlist\presentation\pages\playlist_detail_page.dart:83:62
          • 'surfaceVariant' is deprecated and shouldn't be used. Use       
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use
   info • lib\src\features\saga\presentation\pages\saga_detail_page.dart:30:56
          • 'surfaceVariant' is deprecated and shouldn't be used. Use       
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use
   info • lib\src\features\saga\presentation\pages\saga_detail_page.dart:59:59
          • 'surfaceVariant' is deprecated and shouldn't be used. Use       
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use
   info • lib\src\features\saga\presentation\pages\saga_detail_page.dart:114:46
          • 'surfaceVariant' is deprecated and shouldn't be used. Use       
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use
   info • lib\src\features\tv\presentation\pages\tv_detail_page.dart:24:60 •
          'surfaceVariant' is deprecated and shouldn't be used. Use
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use
   info • lib\src\features\tv\presentation\pages\tv_detail_page.dart:84:62 •
          'surfaceVariant' is deprecated and shouldn't be used. Use
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use
   info • lib\src\features\tv\presentation\pages\tv_detail_page.dart:108:70 
          • 'surfaceVariant' is deprecated and shouldn't be used. Use       
          surfaceContainerHighest instead. This feature was deprecated after
          v3.18.0-0.1.pre. Try replacing the use of the deprecated member   
          with the replacement. • deprecated_member_use

23 issues found.