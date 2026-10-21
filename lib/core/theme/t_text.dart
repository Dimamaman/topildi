import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

extension TInter on TextStyle {
  /// Same style in the real Inter face for [weight]. google_fonts ties each
  /// theme style to one weight file, so `copyWith(fontWeight:)` alone gives a
  /// synthesized weight; this loads the matching file instead.
  TextStyle inter(FontWeight weight) => GoogleFonts.inter(textStyle: copyWith(fontWeight: weight));
}
