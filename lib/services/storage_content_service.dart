import 'dart:convert';

/// Local starter content. Replace later with Firebase Storage downloads.
class StorageContentService {
  Future<String> downloadTextFile(String path) async {
    // In this starter MVP, `path` is ignored. We return demo JSON.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return jsonEncode(_demoContent[path] ?? _demoContent['categories']!);
  }

  List<String> listChallengeIds() {
    final ids = _demoContent.keys
        .where((key) => key.startsWith('challenge_'))
        .map((key) => key.replaceFirst('challenge_', ''))
        .toList();
    ids.sort();
    return ids;
  }

  static final Map<String, Object> _demoContent = {
    'categories': {
      'version': 1,
      'categories': [
        {'id': 'sports', 'title': 'Sports', 'icon': '🏈', 'enabled': true},
        {'id': 'history', 'title': 'History', 'icon': '🏛️', 'enabled': true},
        {'id': 'science', 'title': 'Science', 'icon': '🧪', 'enabled': true},
      ],
      'packMap': {
        'sports': 'pack_sports',
        'history': 'pack_history',
        'science': 'pack_science',
      }
    },
    'pack_sports': {
      'categoryId': 'sports',
      'version': 1,
      'questions': [
        {
          'id': 'sports_q1',
          'question': 'Which country won the 2018 FIFA World Cup?',
          'answers': [
            {'id': 'a', 'text': 'France', 'correct': true},
            {'id': 'b', 'text': 'Brazil'},
            {'id': 'c', 'text': 'Germany'},
            {'id': 'd', 'text': 'Argentina'},
          ],
          'explanation': 'France defeated Croatia 4–2 in the final.'
        },
        {
          'id': 'sports_q2',
          'question': 'In basketball, how many points is a free throw worth?',
          'answers': [
            {'id': 'a', 'text': '1', 'correct': true},
            {'id': 'b', 'text': '2'},
            {'id': 'c', 'text': '3'},
            {'id': 'd', 'text': '5'},
          ],
          'explanation': 'A free throw is worth one point.'
        },
      ]
    },
    'pack_history': {
      'categoryId': 'history',
      'version': 1,
      'questions': [
        {
          'id': 'history_q1',
          'question': 'Which ancient civilization built the pyramids at Giza?',
          'answers': [
            {'id': 'a', 'text': 'The Egyptians', 'correct': true},
            {'id': 'b', 'text': 'The Romans'},
            {'id': 'c', 'text': 'The Vikings'},
            {'id': 'd', 'text': 'The Aztecs'},
          ],
          'explanation': 'The Great Pyramids were built in Ancient Egypt.'
        },
        {
          'id': 'history_q2',
          'question': 'The Renaissance began in which country?',
          'answers': [
            {'id': 'a', 'text': 'Italy', 'correct': true},
            {'id': 'b', 'text': 'France'},
            {'id': 'c', 'text': 'England'},
            {'id': 'd', 'text': 'Spain'},
          ],
          'explanation': 'It began in Italy, especially Florence.'
        },
      ]
    },
    'pack_science': {
      'categoryId': 'science',
      'version': 1,
      'questions': [
        {
          'id': 'science_q1',
          'question': 'What is the chemical symbol for water?',
          'answers': [
            {'id': 'a', 'text': 'H₂O', 'correct': true},
            {'id': 'b', 'text': 'O₂'},
            {'id': 'c', 'text': 'CO₂'},
            {'id': 'd', 'text': 'NaCl'},
          ],
          'explanation': 'Water is composed of two hydrogen atoms and one oxygen atom.'
        },
        {
          'id': 'science_q2',
          'question': 'How many planets are in our solar system?',
          'answers': [
            {'id': 'a', 'text': '8', 'correct': true},
            {'id': 'b', 'text': '7'},
            {'id': 'c', 'text': '9'},
            {'id': 'd', 'text': '10'},
          ],
          'explanation': 'There are 8 planets (Pluto is classified as a dwarf planet).'
        },
      ]
    },
    'challenge_daily_global_01': {
      'id': 'daily_global_01',
      'title': 'Daily Duel: World Wonders',
      'topic': 'World Wonders',
      'difficulty': 'Medium',
      'rules': [
        'Answer every question in order.',
        'One attempt per challenger.',
        'No hints and no skips.',
      ],
      'taunt': 'Legends are built one wonder at a time.',
      'expiresAt': '2024-11-03T18:00:00Z',
      'questions': [
        {
          'id': 'dw_q1',
          'prompt': 'Which ancient city is home to the Colosseum?',
          'choices': [
            {'id': 'a', 'text': 'Rome'},
            {'id': 'b', 'text': 'Athens'},
            {'id': 'c', 'text': 'Cairo'},
            {'id': 'd', 'text': 'Cusco'},
          ],
        },
        {
          'id': 'dw_q2',
          'prompt': 'Machu Picchu is located in which country?',
          'choices': [
            {'id': 'a', 'text': 'Peru'},
            {'id': 'b', 'text': 'Chile'},
            {'id': 'c', 'text': 'Mexico'},
            {'id': 'd', 'text': 'Brazil'},
          ],
        },
        {
          'id': 'dw_q3',
          'prompt': 'The Great Wall stretches across which country?',
          'choices': [
            {'id': 'a', 'text': 'China'},
            {'id': 'b', 'text': 'India'},
            {'id': 'c', 'text': 'Japan'},
            {'id': 'd', 'text': 'Mongolia'},
          ],
        },
      ],
    },
    'challenge_daily_speed_02': {
      'id': 'daily_speed_02',
      'title': 'Quickfire Cosmos',
      'topic': 'Space & Stars',
      'difficulty': 'Hard',
      'rules': [
        'Quick answers win the duel.',
        'No pauses once started.',
        'One attempt per challenger.',
      ],
      'taunt': 'The universe waits for no one.',
      'expiresAt': '2024-11-03T22:00:00Z',
      'questions': [
        {
          'id': 'qs_q1',
          'prompt': 'What do we call a star that has collapsed into a super-dense core?',
          'choices': [
            {'id': 'a', 'text': 'Neutron star'},
            {'id': 'b', 'text': 'Red giant'},
            {'id': 'c', 'text': 'White dwarf'},
            {'id': 'd', 'text': 'Protostar'},
          ],
        },
        {
          'id': 'qs_q2',
          'prompt': 'Which planet is known for its prominent ring system?',
          'choices': [
            {'id': 'a', 'text': 'Saturn'},
            {'id': 'b', 'text': 'Mars'},
            {'id': 'c', 'text': 'Venus'},
            {'id': 'd', 'text': 'Mercury'},
          ],
        },
        {
          'id': 'qs_q3',
          'prompt': 'The Milky Way is classified as which type of galaxy?',
          'choices': [
            {'id': 'a', 'text': 'Spiral'},
            {'id': 'b', 'text': 'Elliptical'},
            {'id': 'c', 'text': 'Irregular'},
            {'id': 'd', 'text': 'Ring'},
          ],
        },
      ],
    },
    'challenge_public_tech_14': {
      'id': 'public_tech_14',
      'title': 'Tech Titans Throwdown',
      'topic': 'Technology',
      'difficulty': 'Medium',
      'rules': [
        'Stay sharp — no second chances.',
        'One attempt per challenger.',
        'All questions are pre-seeded.',
      ],
      'taunt': 'Only the bold ship on day one.',
      'expiresAt': '2024-11-05T04:00:00Z',
      'questions': [
        {
          'id': 'tt_q1',
          'prompt': 'What does “GPU” stand for?',
          'choices': [
            {'id': 'a', 'text': 'Graphics Processing Unit'},
            {'id': 'b', 'text': 'General Processing Utility'},
            {'id': 'c', 'text': 'Graphical Performance Unit'},
            {'id': 'd', 'text': 'Global Processing Unit'},
          ],
        },
        {
          'id': 'tt_q2',
          'prompt': 'Which company created the Android operating system?',
          'choices': [
            {'id': 'a', 'text': 'Google'},
            {'id': 'b', 'text': 'Apple'},
            {'id': 'c', 'text': 'Microsoft'},
            {'id': 'd', 'text': 'IBM'},
          ],
        },
        {
          'id': 'tt_q3',
          'prompt': 'Moore’s Law is primarily about the growth of what?',
          'choices': [
            {'id': 'a', 'text': 'Transistor counts'},
            {'id': 'b', 'text': 'Battery capacity'},
            {'id': 'c', 'text': 'Internet speed'},
            {'id': 'd', 'text': 'Storage prices'},
          ],
        },
      ],
    },
    'challenge_public_sports_11': {
      'id': 'public_sports_11',
      'title': 'Championship Sprint',
      'topic': 'Sports',
      'difficulty': 'Medium',
      'rules': [
        'No rewinds — lock in your pick.',
        'One attempt per challenger.',
        'All questions are fixed.',
      ],
      'taunt': 'Only champions close out the sprint.',
      'expiresAt': '2024-11-05T04:00:00Z',
      'questions': [
        {
          'id': 'cs_q1',
          'prompt': 'How many players are on a standard soccer team on the field?',
          'choices': [
            {'id': 'a', 'text': '11'},
            {'id': 'b', 'text': '9'},
            {'id': 'c', 'text': '7'},
            {'id': 'd', 'text': '12'},
          ],
        },
        {
          'id': 'cs_q2',
          'prompt': 'Which event is known as the “100-meter dash”?',
          'choices': [
            {'id': 'a', 'text': 'Sprinting'},
            {'id': 'b', 'text': 'Marathon'},
            {'id': 'c', 'text': 'Hurdles'},
            {'id': 'd', 'text': 'Relay'},
          ],
        },
        {
          'id': 'cs_q3',
          'prompt': 'In tennis, what is the term for a score of zero?',
          'choices': [
            {'id': 'a', 'text': 'Love'},
            {'id': 'b', 'text': 'Nil'},
            {'id': 'c', 'text': 'Blank'},
            {'id': 'd', 'text': 'Duck'},
          ],
        },
      ],
    },
    'challenge_public_pop_09': {
      'id': 'public_pop_09',
      'title': 'Pop Culture Pulse',
      'topic': 'Pop Culture',
      'difficulty': 'Easy',
      'rules': [
        'No skips.',
        'One attempt per challenger.',
        'Keep it fair and fast.',
      ],
      'taunt': 'Let’s see if you live on the timeline.',
      'expiresAt': '2024-11-05T04:00:00Z',
      'questions': [
        {
          'id': 'pc_q1',
          'prompt': 'Which movie franchise features a character named “Darth Vader”?',
          'choices': [
            {'id': 'a', 'text': 'Star Wars'},
            {'id': 'b', 'text': 'Star Trek'},
            {'id': 'c', 'text': 'The Matrix'},
            {'id': 'd', 'text': 'Avatar'},
          ],
        },
        {
          'id': 'pc_q2',
          'prompt': 'Which platform is known for short-form viral videos?',
          'choices': [
            {'id': 'a', 'text': 'TikTok'},
            {'id': 'b', 'text': 'LinkedIn'},
            {'id': 'c', 'text': 'Pinterest'},
            {'id': 'd', 'text': 'Slack'},
          ],
        },
        {
          'id': 'pc_q3',
          'prompt': 'Which genre best describes a superhero film?',
          'choices': [
            {'id': 'a', 'text': 'Action'},
            {'id': 'b', 'text': 'Documentary'},
            {'id': 'c', 'text': 'Romantic comedy'},
            {'id': 'd', 'text': 'Western'},
          ],
        },
      ],
    },
  };
}
