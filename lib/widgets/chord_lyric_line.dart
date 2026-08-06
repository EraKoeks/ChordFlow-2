// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class ChordLyricLine extends StatelessWidget {
//   const ChordLyricLine({
//     super.key,
//     required this.line,
//     required this.fontSize,
//   });
//
//   final String line;
//   final double fontSize;
//
//   @override
//   Widget build(BuildContext context) {
//     final parts = _ChordLineParser.parse(line);
//
//     if (parts.isEmpty) {
//       return const SizedBox.shrink();
//     }
//
//     final hasChords = parts.any(
//           (part) => part.chord.isNotEmpty,
//     );
//
//     if (!hasChords) {
//       return Padding(
//         padding: const EdgeInsets.only(bottom: 12),
//         child: Text(
//           line,
//           style: TextStyle(
//             fontSize: fontSize,
//             height: 1.45,
//           ),
//         ),
//       );
//     }
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 18),
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           return Wrap(
//             spacing: 0,
//             runSpacing: fontSize * 0.45,
//             crossAxisAlignment: WrapCrossAlignment.end,
//             children: parts.map((part) {
//               return _ChordLyricPartWidget(
//                 part: part,
//                 fontSize: fontSize,
//                 maximumWidth: constraints.maxWidth,
//               );
//             }).toList(),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class _ChordLyricPartWidget extends StatelessWidget {
//   const _ChordLyricPartWidget({
//     required this.part,
//     required this.fontSize,
//     required this.maximumWidth,
//   });
//
//   final ChordLyricPart part;
//   final double fontSize;
//   final double maximumWidth;
//
//   @override
//   Widget build(BuildContext context) {
//     final chordColor =
//         Theme.of(context).colorScheme.primary;
//
//     final chordStyle = GoogleFonts.robotoMono(
//       fontSize: fontSize * 0.78,
//       fontWeight: FontWeight.w700,
//       height: 1.1,
//       color: chordColor,
//     );
//
//     final lyricStyle = TextStyle(
//       fontSize: fontSize,
//       height: 1.35,
//     );
//
//     final textDirection =
//     Directionality.of(context);
//
//     final textScaler =
//     MediaQuery.textScalerOf(context);
//
//     final chordWidth = _measureText(
//       text: part.chord,
//       style: chordStyle,
//       textDirection: textDirection,
//       textScaler: textScaler,
//     );
//
//     final lyricWidth = _measureText(
//       text: part.lyric.isEmpty ? ' ' : part.lyric,
//       style: lyricStyle,
//       textDirection: textDirection,
//       textScaler: textScaler,
//     );
//
//     final desiredWidth =
//     chordWidth > lyricWidth ? chordWidth : lyricWidth;
//
//     final safeWidth = desiredWidth
//         .clamp(1.0, maximumWidth)
//         .toDouble();
//
//     return SizedBox(
//       width: safeWidth,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             height: fontSize * 0.95,
//             child: part.chord.isEmpty
//                 ? const SizedBox.shrink()
//                 : Text(
//               part.chord,
//               maxLines: 1,
//               overflow: TextOverflow.visible,
//               style: chordStyle,
//             ),
//           ),
//           Text(
//             part.lyric.isEmpty ? ' ' : part.lyric,
//             style: lyricStyle,
//           ),
//         ],
//       ),
//     );
//   }
//
//   double _measureText({
//     required String text,
//     required TextStyle style,
//     required TextDirection textDirection,
//     required TextScaler textScaler,
//   }) {
//     if (text.isEmpty) {
//       return 0;
//     }
//
//     final painter = TextPainter(
//       text: TextSpan(
//         text: text,
//         style: style,
//       ),
//       textDirection: textDirection,
//       textScaler: textScaler,
//       maxLines: 1,
//     );
//
//     painter.layout();
//
//     final width = painter.width;
//     painter.dispose();
//
//     return width;
//   }
// }
//
// class ChordLyricPart {
//   const ChordLyricPart({
//     required this.chord,
//     required this.lyric,
//   });
//
//   final String chord;
//   final String lyric;
// }
//
// class _ChordLineParser {
//   static final RegExp _chordPattern =
//   RegExp(r'\[([^\]]+)\]');
//
//   static List<ChordLyricPart> parse(
//       String line,
//       ) {
//     if (line.isEmpty) {
//       return const [];
//     }
//
//     final matches =
//     _chordPattern.allMatches(line).toList();
//
//     if (matches.isEmpty) {
//       return [
//         ChordLyricPart(
//           chord: '',
//           lyric: line,
//         ),
//       ];
//     }
//
//     final parts = <ChordLyricPart>[];
//     var currentPosition = 0;
//
//     for (var index = 0;
//     index < matches.length;
//     index++) {
//       final match = matches[index];
//
//       if (match.start > currentPosition) {
//         final textBeforeChord = line.substring(
//           currentPosition,
//           match.start,
//         );
//
//         if (textBeforeChord.isNotEmpty) {
//           parts.add(
//             ChordLyricPart(
//               chord: '',
//               lyric: textBeforeChord,
//             ),
//           );
//         }
//       }
//
//       final chord = match.group(1)?.trim() ?? '';
//
//       final lyricStart = match.end;
//       final lyricEnd = index + 1 < matches.length
//           ? matches[index + 1].start
//           : line.length;
//
//       final lyric = line.substring(
//         lyricStart,
//         lyricEnd,
//       );
//
//       parts.add(
//         ChordLyricPart(
//           chord: chord,
//           lyric: lyric,
//         ),
//       );
//
//       currentPosition = lyricEnd;
//     }
//
//     return parts;
//   }
// }