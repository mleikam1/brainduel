import 'dart:convert';

/// Local starter content. Replace later with Firebase Storage downloads.
class StorageContentService {
  Future<String> downloadTextFile(String path) async {
    // In this starter MVP, `path` is ignored. We return demo JSON.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return jsonEncode(_demoContent[path] ?? _demoContent['categories']!);
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
  };
}
