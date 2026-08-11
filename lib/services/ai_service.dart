import 'package:firebase_ai/firebase_ai.dart';

import '../models/song.dart';

class AiService {
  AiService._();

  static final GenerativeModel _model =
  FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.6-flash',
  );

  static Future<String> askAi({
    required Song song,
    required String task,
  }) async {
    final prompt = '''
Je bent ChordFlow AI, een praktische assistent voor muzikanten.

Voer deze taak uit:
$task

Gebruik de gegevens van het lied hieronder.

Titel: ${song.title}
Artiest: ${song.artist}
Originele toonsoort: ${song.originalKey ?? 'Onbekend'}
Genre: ${song.genre}
Tags: ${song.tags.join(', ')}

ChordPro / songtekst:
${song.content}

Regels:
- Antwoord in het Nederlands.
- Houd het antwoord duidelijk en praktisch.
- Gebruik korte kopjes en opsommingen als dat helpt.
- Geef geen verzonnen feiten over het lied.
- Leg muziektheorie eenvoudig uit.
''';

    final response = await _model.generateContent([
      Content.text(prompt),
    ]);

    final text = response.text?.trim();

    if (text == null || text.isEmpty) {
      throw Exception(
        'Gemini gaf geen antwoord terug.',
      );
    }

    return text;
  }

  static ChatSession startSongChat(
      Song song,
      ) {
    final songContext = '''
Je bent ChordFlow AI, een praktische assistent voor muzikanten.

Dit gesprek gaat over het volgende lied:

Titel: ${song.title}
Artiest: ${song.artist}
Originele toonsoort: ${song.originalKey ?? 'Onbekend'}
Genre: ${song.genre}
Tags: ${song.tags.join(', ')}

ChordPro / songtekst:
${song.content}

Regels voor het hele gesprek:
- Antwoord in het Nederlands.
- Houd uitleg praktisch en duidelijk.
- Geef geen verzonnen feiten.
- Gebruik de eerdere berichten in het gesprek.
- Leg muziektheorie eenvoudig uit.
- Als informatie ontbreekt, zeg dat duidelijk.
''';

    return _model.startChat(
      history: [
        Content.text(songContext),
        Content.model([
          const TextPart(
            'Begrepen. Ik help je met dit lied en onthoud de context van dit gesprek.',
          ),
        ]),
      ],
    );
  }

  static Future<String> summarizeSong(
      Song song,
      ) {
    return askAi(
      song: song,
      task: '''
Vat het lied kort samen.

Geef:
1. De muzikale sfeer.
2. De belangrijkste boodschap of het thema.
3. Wat opvalt aan de akkoorden of structuur.
4. Eén praktische tip voor repetitie of optreden.
''',
    );
  }

  static Future<String> suggestBetterKey(
      Song song,
      ) {
    return askAi(
      song: song,
      task: '''
Geef advies over een betere toonsoort.

Geef:
1. De huidige toonsoort.
2. Eén of twee aanbevolen toonsoorten.
3. Waarom die mogelijk prettiger zijn.
4. Een gitaar- of capo-tip indien relevant.
5. Vermeld dat de beste zangtoonsoort afhangt van het persoonlijke stembereik.
''',
    );
  }

  static Future<String> vocalRangeAdvice(
      Song song,
      ) {
    return askAi(
      song: song,
      task: '''
Geef praktisch zangbereikadvies voor dit lied.

Leg uit:
1. Of de huidige toonsoort waarschijnlijk hoog, gemiddeld of laag aanvoelt.
2. Welke lagere en hogere alternatieven logisch zijn.
3. Hoe een zanger zelf kan testen welke toonsoort prettig is.
4. Vermeld dat je zonder de exacte stemomvang geen definitieve zangtoonsoort kunt bepalen.
''',
    );
  }

  static Future<String> capoAdvice(
      Song song,
      ) {
    return askAi(
      song: song,
      task: '''
Geef capo-advies voor gitaar.

Geef:
1. Een of twee eenvoudige capo-posities.
2. Welke akkoordvormen de gitarist dan kan spelen.
3. Waarom die positie handig kan zijn.
4. Houd rekening met de huidige toonsoort van het lied.
''',
    );
  }

  static Future<String> chordSuggestions(
      Song song,
      ) {
    return askAi(
      song: song,
      task: '''
Analyseer de bestaande akkoorden en geef akkoordsuggesties.

Geef:
1. Wat de belangrijkste akkoordprogressie lijkt te zijn.
2. Mogelijke alternatieve akkoorden.
3. Eventuele sus-, add9- of slash-chords die muzikaal passen.
4. Houd de suggesties speelbaar en praktisch.
''',
    );
  }

  static Future<String> generateIntro(
      Song song,
      ) {
    return askAi(
      song: song,
      task: '''
Maak een eenvoudig muzikaal intro voor dit lied.

Geef:
1. Een korte akkoordprogressie van ongeveer 2 tot 4 maten.
2. Een speelidee voor piano of gitaar.
3. Een duidelijke overgang naar het begin van het lied.
''',
    );
  }

  static Future<String> generateOutro(
      Song song,
      ) {
    return askAi(
      song: song,
      task: '''
Maak een passend outro voor dit lied.

Geef:
1. Een korte akkoordprogressie.
2. Een eenvoudig eindidee.
3. Indien passend een optie voor een rustig einde en een krachtig einde.
''',
    );
  }
}
