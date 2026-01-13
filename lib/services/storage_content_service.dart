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
    // Category registry used by the client to render Home/Discover and map
    // categoryId -> packId for local/demo sessions. Keep IDs in sync with
    // backend topicId values (Firestore topics + questions).
    'categories': {
      'version': 2,
      'categories': [
        {'id': 'sports', 'title': 'Sports', 'icon': '🏈', 'enabled': true},
        {'id': 'history', 'title': 'History', 'icon': '🏛️', 'enabled': true},
        {'id': 'science', 'title': 'Science', 'icon': '🧪', 'enabled': true},
        {'id': 'geography', 'title': 'Geography', 'icon': '🌍', 'enabled': true},
        {'id': 'movies', 'title': 'Movies', 'icon': '🎬', 'enabled': true},
        {'id': 'music', 'title': 'Music', 'icon': '🎵', 'enabled': true},
        {'id': 'entertainment', 'title': 'Entertainment', 'icon': '🎭', 'enabled': true},
        {'id': 'food', 'title': 'Food', 'icon': '🍔', 'enabled': true},
        {'id': 'animals', 'title': 'Animals', 'icon': '🐾', 'enabled': true},
      ],
      'packMap': {
        'sports': 'pack_sports',
        'history': 'pack_history',
        'science': 'pack_science',
        'geography': 'pack_geography',
        'movies': 'pack_movies',
        'music': 'pack_music',
        'entertainment': 'pack_entertainment',
        'food': 'pack_food',
        'animals': 'pack_animals',
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
        {
          'id': 'sports_q3',
          'question': 'How many players are on the field for one soccer team?',
          'answers': [
            {'id': 'a', 'text': '11', 'correct': true},
            {'id': 'b', 'text': '9'},
            {'id': 'c', 'text': '10'},
            {'id': 'd', 'text': '12'},
          ],
          'explanation': 'Soccer fields 11 players per team.'
        },
        {
          'id': 'sports_q4',
          'question': 'How often are the Summer Olympic Games held?',
          'answers': [
            {'id': 'a', 'text': 'Every 4 years', 'correct': true},
            {'id': 'b', 'text': 'Every 2 years'},
            {'id': 'c', 'text': 'Every 6 years'},
            {'id': 'd', 'text': 'Every 8 years'},
          ],
          'explanation': 'The Olympics are held every four years.'
        },
        {
          'id': 'sports_q5',
          'question': 'Which Grand Slam tennis tournament is played on clay courts?',
          'answers': [
            {'id': 'a', 'text': 'French Open', 'correct': true},
            {'id': 'b', 'text': 'Wimbledon'},
            {'id': 'c', 'text': 'US Open'},
            {'id': 'd', 'text': 'Australian Open'},
          ],
          'explanation': 'The French Open is played on clay.'
        },
        {
          'id': 'sports_q6',
          'question': 'In baseball, how many strikes result in an out?',
          'answers': [
            {'id': 'a', 'text': '3', 'correct': true},
            {'id': 'b', 'text': '2'},
            {'id': 'c', 'text': '4'},
            {'id': 'd', 'text': '5'},
          ],
          'explanation': 'Three strikes result in an out.'
        },
        {
          'id': 'sports_q7',
          'question': 'What trophy is awarded to the Super Bowl champion?',
          'answers': [
            {'id': 'a', 'text': 'Vince Lombardi Trophy', 'correct': true},
            {'id': 'b', 'text': 'Heisman Trophy'},
            {'id': 'c', 'text': 'Stanley Cup'},
            {'id': 'd', 'text': 'Commissioner’s Trophy'},
          ],
          'explanation': 'The Super Bowl winner receives the Vince Lombardi Trophy.'
        },
        {
          'id': 'sports_q8',
          'question': 'What does NHL stand for?',
          'answers': [
            {'id': 'a', 'text': 'National Hockey League', 'correct': true},
            {'id': 'b', 'text': 'National Hoops League'},
            {'id': 'c', 'text': 'Northern Hockey League'},
            {'id': 'd', 'text': 'National Handball League'},
          ],
          'explanation': 'NHL stands for National Hockey League.'
        },
        {
          'id': 'sports_q9',
          'question': 'A full marathon is approximately how many miles?',
          'answers': [
            {'id': 'a', 'text': '26.2 miles', 'correct': true},
            {'id': 'b', 'text': '13.1 miles'},
            {'id': 'c', 'text': '24 miles'},
            {'id': 'd', 'text': '30 miles'},
          ],
          'explanation': 'A marathon is 26.2 miles (42.195 km).'
        },
        {
          'id': 'sports_q10',
          'question': 'In golf, a score of one under par on a hole is called a?',
          'answers': [
            {'id': 'a', 'text': 'Birdie', 'correct': true},
            {'id': 'b', 'text': 'Eagle'},
            {'id': 'c', 'text': 'Bogey'},
            {'id': 'd', 'text': 'Par'},
          ],
          'explanation': 'One under par is a birdie.'
        },
        {
          'id': 'sports_q11',
          'question': 'How many hits per side are allowed in volleyball before sending the ball over?',
          'answers': [
            {'id': 'a', 'text': '3', 'correct': true},
            {'id': 'b', 'text': '2'},
            {'id': 'c', 'text': '4'},
            {'id': 'd', 'text': '5'},
          ],
          'explanation': 'Each team has up to three hits.'
        },
        {
          'id': 'sports_q12',
          'question': 'In cricket, how many runs are scored for hitting the ball over the boundary on the full?',
          'answers': [
            {'id': 'a', 'text': '6', 'correct': true},
            {'id': 'b', 'text': '4'},
            {'id': 'c', 'text': '2'},
            {'id': 'd', 'text': '8'},
          ],
          'explanation': 'A ball hit over the boundary without bouncing scores six.'
        },
        {
          'id': 'sports_q13',
          'question': 'Which NBA team has won the most championships?',
          'answers': [
            {'id': 'a', 'text': 'Boston Celtics', 'correct': true},
            {'id': 'b', 'text': 'Chicago Bulls'},
            {'id': 'c', 'text': 'Miami Heat'},
            {'id': 'd', 'text': 'Golden State Warriors'},
          ],
          'explanation': 'The Celtics have the most NBA titles.'
        },
        {
          'id': 'sports_q14',
          'question': 'Which sport uses the scoring terms “love” and “deuce”?',
          'answers': [
            {'id': 'a', 'text': 'Tennis', 'correct': true},
            {'id': 'b', 'text': 'Badminton'},
            {'id': 'c', 'text': 'Squash'},
            {'id': 'd', 'text': 'Table tennis'},
          ],
          'explanation': 'Tennis uses “love” and “deuce.”'
        },
        {
          'id': 'sports_q15',
          'question': 'How many points is a touchdown worth in American football?',
          'answers': [
            {'id': 'a', 'text': '6', 'correct': true},
            {'id': 'b', 'text': '3'},
            {'id': 'c', 'text': '7'},
            {'id': 'd', 'text': '1'},
          ],
          'explanation': 'A touchdown is worth six points.'
        },
        {
          'id': 'sports_q16',
          'question': 'How many Olympic rings are in the symbol?',
          'answers': [
            {'id': 'a', 'text': '5', 'correct': true},
            {'id': 'b', 'text': '4'},
            {'id': 'c', 'text': '6'},
            {'id': 'd', 'text': '7'},
          ],
          'explanation': 'There are five interlocking Olympic rings.'
        },
        {
          'id': 'sports_q17',
          'question': 'Formula 1 races are commonly called what?',
          'answers': [
            {'id': 'a', 'text': 'Grand Prix', 'correct': true},
            {'id': 'b', 'text': 'Majors'},
            {'id': 'c', 'text': 'Derbies'},
            {'id': 'd', 'text': 'Cups'},
          ],
          'explanation': 'F1 races are Grand Prix events.'
        },
        {
          'id': 'sports_q18',
          'question': 'Which sport features the positions pitcher, catcher, and shortstop?',
          'answers': [
            {'id': 'a', 'text': 'Baseball', 'correct': true},
            {'id': 'b', 'text': 'Cricket'},
            {'id': 'c', 'text': 'Hockey'},
            {'id': 'd', 'text': 'Rugby'},
          ],
          'explanation': 'Those positions are in baseball.'
        },
        {
          'id': 'sports_q19',
          'question': 'How many bases are there on a standard baseball field?',
          'answers': [
            {'id': 'a', 'text': '4', 'correct': true},
            {'id': 'b', 'text': '3'},
            {'id': 'c', 'text': '5'},
            {'id': 'd', 'text': '6'},
          ],
          'explanation': 'Baseball has four bases.'
        },
        {
          'id': 'sports_q20',
          'question': 'Which stroke is part of the individual medley?',
          'answers': [
            {'id': 'a', 'text': 'Butterfly', 'correct': true},
            {'id': 'b', 'text': 'Dog paddle'},
            {'id': 'c', 'text': 'Sidestroke'},
            {'id': 'd', 'text': 'Trudgen'},
          ],
          'explanation': 'Butterfly is one of the four medley strokes.'
        },
      ]
    },
    'pack_geography': {
      'categoryId': 'geography',
      'version': 1,
      'questions': [
        {
          'id': 'geography_q1',
          'question': 'What is the capital city of France?',
          'answers': [
            {'id': 'a', 'text': 'Paris', 'correct': true},
            {'id': 'b', 'text': 'Lyon'},
            {'id': 'c', 'text': 'Marseille'},
            {'id': 'd', 'text': 'Nice'},
          ],
          'explanation': ''
        },
        {
          'id': 'geography_q2',
          'question': 'Which is the largest ocean on Earth?',
          'answers': [
            {'id': 'a', 'text': 'Atlantic Ocean'},
            {'id': 'b', 'text': 'Indian Ocean'},
            {'id': 'c', 'text': 'Pacific Ocean', 'correct': true},
            {'id': 'd', 'text': 'Arctic Ocean'},
          ],
          'explanation': ''
        },
        {
          'id': 'geography_q3',
          'question': 'Which continent is Brazil located in?',
          'answers': [
            {'id': 'a', 'text': 'Europe'},
            {'id': 'b', 'text': 'Asia'},
            {'id': 'c', 'text': 'South America', 'correct': true},
            {'id': 'd', 'text': 'Africa'},
          ],
          'explanation': ''
        },
        {
          'id': 'geography_q4',
          'question': 'Mount Everest lies on the border of Nepal and which country?',
          'answers': [
            {'id': 'a', 'text': 'India'},
            {'id': 'b', 'text': 'China', 'correct': true},
            {'id': 'c', 'text': 'Bhutan'},
            {'id': 'd', 'text': 'Myanmar'},
          ],
          'explanation': ''
        },
        {
          'id': 'geography_q5',
          'question': 'The Sahara Desert is primarily in which continent?',
          'answers': [
            {'id': 'a', 'text': 'Asia'},
            {'id': 'b', 'text': 'Africa', 'correct': true},
            {'id': 'c', 'text': 'Australia'},
            {'id': 'd', 'text': 'South America'},
          ],
          'explanation': ''
        },
        {
          'id': 'geography_q6',
          'question': 'Which country is also a continent?',
          'answers': [
            {'id': 'a', 'text': 'Greenland'},
            {'id': 'b', 'text': 'Australia', 'correct': true},
            {'id': 'c', 'text': 'Iceland'},
            {'id': 'd', 'text': 'Madagascar'},
          ],
          'explanation': ''
        },
        {
          'id': 'geography_q7',
          'question': 'What is the capital city of Japan?',
          'answers': [
            {'id': 'a', 'text': 'Osaka'},
            {'id': 'b', 'text': 'Kyoto'},
            {'id': 'c', 'text': 'Tokyo', 'correct': true},
            {'id': 'd', 'text': 'Nagoya'},
          ],
          'explanation': ''
        },
        {
          'id': 'geography_q8',
          'question': 'Which U.S. state is nicknamed the Sunshine State?',
          'answers': [
            {'id': 'a', 'text': 'California'},
            {'id': 'b', 'text': 'Florida', 'correct': true},
            {'id': 'c', 'text': 'Arizona'},
            {'id': 'd', 'text': 'Texas'},
          ],
          'explanation': ''
        },
        {
          'id': 'geography_q9',
          'question': 'Which country has the city of Cairo as its capital?',
          'answers': [
            {'id': 'a', 'text': 'Egypt', 'correct': true},
            {'id': 'b', 'text': 'Morocco'},
            {'id': 'c', 'text': 'Algeria'},
            {'id': 'd', 'text': 'Tunisia'},
          ],
          'explanation': ''
        },
        {
          'id': 'geography_q10',
          'question': 'What is the capital city of Canada?',
          'answers': [
            {'id': 'a', 'text': 'Toronto'},
            {'id': 'b', 'text': 'Vancouver'},
            {'id': 'c', 'text': 'Ottawa', 'correct': true},
            {'id': 'd', 'text': 'Montreal'},
          ],
          'explanation': ''
        },
      ]
    },
    'pack_movies': {
      'categoryId': 'movies',
      'version': 1,
      'questions': [
        {
          'id': 'movies_q1',
          'question': "Who directed the movie 'Jaws'?",
          'answers': [
            {'id': 'a', 'text': 'Steven Spielberg', 'correct': true},
            {'id': 'b', 'text': 'George Lucas'},
            {'id': 'c', 'text': 'James Cameron'},
            {'id': 'd', 'text': 'Ridley Scott'},
          ],
          'explanation': ''
        },
        {
          'id': 'movies_q2',
          'question': 'Which movie features the character Darth Vader?',
          'answers': [
            {'id': 'a', 'text': 'Star Wars', 'correct': true},
            {'id': 'b', 'text': 'Star Trek'},
            {'id': 'c', 'text': 'Dune'},
            {'id': 'd', 'text': 'Guardians of the Galaxy'},
          ],
          'explanation': ''
        },
        {
          'id': 'movies_q3',
          'question': "In 'The Wizard of Oz', what color are Dorothy's slippers?",
          'answers': [
            {'id': 'a', 'text': 'Silver'},
            {'id': 'b', 'text': 'Ruby', 'correct': true},
            {'id': 'c', 'text': 'Blue'},
            {'id': 'd', 'text': 'Gold'},
          ],
          'explanation': ''
        },
        {
          'id': 'movies_q4',
          'question': "Which film features the line 'Here's looking at you, kid'?",
          'answers': [
            {'id': 'a', 'text': 'Casablanca', 'correct': true},
            {'id': 'b', 'text': 'Gone with the Wind'},
            {'id': 'c', 'text': 'Citizen Kane'},
            {'id': 'd', 'text': 'The Maltese Falcon'},
          ],
          'explanation': ''
        },
        {
          'id': 'movies_q5',
          'question': "Who played Jack Dawson in 'Titanic'?",
          'answers': [
            {'id': 'a', 'text': 'Brad Pitt'},
            {'id': 'b', 'text': 'Leonardo DiCaprio', 'correct': true},
            {'id': 'c', 'text': 'Matt Damon'},
            {'id': 'd', 'text': 'Johnny Depp'},
          ],
          'explanation': ''
        },
        {
          'id': 'movies_q6',
          'question': 'Which animated movie features the character Simba?',
          'answers': [
            {'id': 'a', 'text': 'The Lion King', 'correct': true},
            {'id': 'b', 'text': 'Finding Nemo'},
            {'id': 'c', 'text': 'Toy Story'},
            {'id': 'd', 'text': 'Shrek'},
          ],
          'explanation': ''
        },
        {
          'id': 'movies_q7',
          'question': 'Which movie is set in a dinosaur theme park on Isla Nublar?',
          'answers': [
            {'id': 'a', 'text': 'Jurassic Park', 'correct': true},
            {'id': 'b', 'text': 'King Kong'},
            {'id': 'c', 'text': 'The Lost World'},
            {'id': 'd', 'text': 'Godzilla'},
          ],
          'explanation': ''
        },
        {
          'id': 'movies_q8',
          'question': 'Which superhero is known as the Dark Knight?',
          'answers': [
            {'id': 'a', 'text': 'Batman', 'correct': true},
            {'id': 'b', 'text': 'Superman'},
            {'id': 'c', 'text': 'Spider-Man'},
            {'id': 'd', 'text': 'Iron Man'},
          ],
          'explanation': ''
        },
        {
          'id': 'movies_q9',
          'question': 'Which film series follows a young wizard named Harry Potter?',
          'answers': [
            {'id': 'a', 'text': 'Harry Potter', 'correct': true},
            {'id': 'b', 'text': 'The Chronicles of Narnia'},
            {'id': 'c', 'text': 'Percy Jackson'},
            {'id': 'd', 'text': 'The Golden Compass'},
          ],
          'explanation': ''
        },
        {
          'id': 'movies_q10',
          'question': "In the movie 'Frozen', what is the name of the snowman?",
          'answers': [
            {'id': 'a', 'text': 'Sven'},
            {'id': 'b', 'text': 'Olaf', 'correct': true},
            {'id': 'c', 'text': 'Kristoff'},
            {'id': 'd', 'text': 'Hans'},
          ],
          'explanation': ''
        },
      ]
    },
    'pack_music': {
      'categoryId': 'music',
      'version': 1,
      'questions': [
        {
          'id': 'music_q1',
          'question': 'How many strings does a standard guitar have?',
          'answers': [
            {'id': 'a', 'text': '4'},
            {'id': 'b', 'text': '5'},
            {'id': 'c', 'text': '6', 'correct': true},
            {'id': 'd', 'text': '7'},
          ],
          'explanation': ''
        },
        {
          'id': 'music_q2',
          'question': "Who is known as the 'King of Pop'?",
          'answers': [
            {'id': 'a', 'text': 'Elvis Presley'},
            {'id': 'b', 'text': 'Michael Jackson', 'correct': true},
            {'id': 'c', 'text': 'Prince'},
            {'id': 'd', 'text': 'Justin Timberlake'},
          ],
          'explanation': ''
        },
        {
          'id': 'music_q3',
          'question': 'Which instrument has keys, pedals, and strings and is played sitting down?',
          'answers': [
            {'id': 'a', 'text': 'Piano', 'correct': true},
            {'id': 'b', 'text': 'Violin'},
            {'id': 'c', 'text': 'Clarinet'},
            {'id': 'd', 'text': 'Trumpet'},
          ],
          'explanation': ''
        },
        {
          'id': 'music_q4',
          'question': 'Which genre is strongly associated with New Orleans and improvisation?',
          'answers': [
            {'id': 'a', 'text': 'Jazz', 'correct': true},
            {'id': 'b', 'text': 'Classical'},
            {'id': 'c', 'text': 'Country'},
            {'id': 'd', 'text': 'Reggae'},
          ],
          'explanation': ''
        },
        {
          'id': 'music_q5',
          'question': "Which band sang the song 'Hey Jude'?",
          'answers': [
            {'id': 'a', 'text': 'The Beatles', 'correct': true},
            {'id': 'b', 'text': 'The Rolling Stones'},
            {'id': 'c', 'text': 'The Who'},
            {'id': 'd', 'text': 'The Kinks'},
          ],
          'explanation': ''
        },
        {
          'id': 'music_q6',
          'question': "Which singer released the song 'Rolling in the Deep'?",
          'answers': [
            {'id': 'a', 'text': 'Adele', 'correct': true},
            {'id': 'b', 'text': 'Beyoncé'},
            {'id': 'c', 'text': 'Rihanna'},
            {'id': 'd', 'text': 'Sia'},
          ],
          'explanation': ''
        },
        {
          'id': 'music_q7',
          'question': 'Which musical symbol indicates silence?',
          'answers': [
            {'id': 'a', 'text': 'Rest', 'correct': true},
            {'id': 'b', 'text': 'Clef'},
            {'id': 'c', 'text': 'Sharp'},
            {'id': 'd', 'text': 'Fermata'},
          ],
          'explanation': ''
        },
        {
          'id': 'music_q8',
          'question': 'Which brass instrument is played using a slide?',
          'answers': [
            {'id': 'a', 'text': 'Trumpet'},
            {'id': 'b', 'text': 'Trombone', 'correct': true},
            {'id': 'c', 'text': 'French horn'},
            {'id': 'd', 'text': 'Tuba'},
          ],
          'explanation': ''
        },
        {
          'id': 'music_q9',
          'question': "Which artist sang the hit song 'Firework'?",
          'answers': [
            {'id': 'a', 'text': 'Katy Perry', 'correct': true},
            {'id': 'b', 'text': 'Taylor Swift'},
            {'id': 'c', 'text': 'Lady Gaga'},
            {'id': 'd', 'text': 'Pink'},
          ],
          'explanation': ''
        },
        {
          'id': 'music_q10',
          'question': 'What is the highest female singing voice type?',
          'answers': [
            {'id': 'a', 'text': 'Alto'},
            {'id': 'b', 'text': 'Mezzo-soprano'},
            {'id': 'c', 'text': 'Soprano', 'correct': true},
            {'id': 'd', 'text': 'Contralto'},
          ],
          'explanation': ''
        },
      ]
    },
    'pack_entertainment': {
      'categoryId': 'entertainment',
      'version': 1,
      'questions': [
        {
          'id': 'entertainment_q1',
          'question': "What is the name of the coffee shop in the TV show 'Friends'?",
          'answers': [
            {'id': 'a', 'text': 'Central Perk', 'correct': true},
            {'id': 'b', 'text': "Monk's Café"},
            {'id': 'c', 'text': 'The Max'},
            {'id': 'd', 'text': 'Cafe Nervosa'},
          ],
          'explanation': ''
        },
        {
          'id': 'entertainment_q2',
          'question': 'Which TV series features the character Walter White?',
          'answers': [
            {'id': 'a', 'text': 'Breaking Bad', 'correct': true},
            {'id': 'b', 'text': 'The Wire'},
            {'id': 'c', 'text': 'Better Call Saul'},
            {'id': 'd', 'text': 'Dexter'},
          ],
          'explanation': ''
        },
        {
          'id': 'entertainment_q3',
          'question': "What is the name of the wizarding school in 'Harry Potter'?",
          'answers': [
            {'id': 'a', 'text': 'Hogwarts', 'correct': true},
            {'id': 'b', 'text': 'Durmstrang'},
            {'id': 'c', 'text': 'Beauxbatons'},
            {'id': 'd', 'text': 'Ilvermorny'},
          ],
          'explanation': ''
        },
        {
          'id': 'entertainment_q4',
          'question': "Which streaming service is known for the series 'Stranger Things'?",
          'answers': [
            {'id': 'a', 'text': 'Netflix', 'correct': true},
            {'id': 'b', 'text': 'Hulu'},
            {'id': 'c', 'text': 'Amazon Prime Video'},
            {'id': 'd', 'text': 'Max'},
          ],
          'explanation': ''
        },
        {
          'id': 'entertainment_q5',
          'question': "Who created 'The Simpsons'?",
          'answers': [
            {'id': 'a', 'text': 'Matt Groening', 'correct': true},
            {'id': 'b', 'text': 'Seth MacFarlane'},
            {'id': 'c', 'text': 'Trey Parker'},
            {'id': 'd', 'text': 'Mike Judge'},
          ],
          'explanation': ''
        },
        {
          'id': 'entertainment_q6',
          'question': "What is the name of Mickey Mouse's dog?",
          'answers': [
            {'id': 'a', 'text': 'Pluto', 'correct': true},
            {'id': 'b', 'text': 'Goofy'},
            {'id': 'c', 'text': 'Donald'},
            {'id': 'd', 'text': 'Daisy'},
          ],
          'explanation': ''
        },
        {
          'id': 'entertainment_q7',
          'question': 'Which video game series features a plumber named Mario?',
          'answers': [
            {'id': 'a', 'text': 'Super Mario', 'correct': true},
            {'id': 'b', 'text': 'Sonic the Hedgehog'},
            {'id': 'c', 'text': 'Crash Bandicoot'},
            {'id': 'd', 'text': 'Mega Man'},
          ],
          'explanation': ''
        },
        {
          'id': 'entertainment_q8',
          'question': 'Which award honors excellence in television in the United States?',
          'answers': [
            {'id': 'a', 'text': 'Emmy Award', 'correct': true},
            {'id': 'b', 'text': 'Grammy Award'},
            {'id': 'c', 'text': 'Tony Award'},
            {'id': 'd', 'text': 'Academy Award'},
          ],
          'explanation': ''
        },
        {
          'id': 'entertainment_q9',
          'question': 'Which Disney movie features the character Elsa?',
          'answers': [
            {'id': 'a', 'text': 'Frozen', 'correct': true},
            {'id': 'b', 'text': 'Moana'},
            {'id': 'c', 'text': 'Tangled'},
            {'id': 'd', 'text': 'Brave'},
          ],
          'explanation': ''
        },
        {
          'id': 'entertainment_q10',
          'question':
              'What is the name of the Marvel superhero team that includes Iron Man and Captain America?',
          'answers': [
            {'id': 'a', 'text': 'Avengers', 'correct': true},
            {'id': 'b', 'text': 'X-Men'},
            {'id': 'c', 'text': 'Fantastic Four'},
            {'id': 'd', 'text': 'Guardians of the Galaxy'},
          ],
          'explanation': ''
        },
      ]
    },
    'pack_food': {
      'categoryId': 'food',
      'version': 1,
      'questions': [
        {
          'id': 'food_q1',
          'question': 'What is the main ingredient in guacamole?',
          'answers': [
            {'id': 'a', 'text': 'Avocado', 'correct': true},
            {'id': 'b', 'text': 'Tomato'},
            {'id': 'c', 'text': 'Cucumber'},
            {'id': 'd', 'text': 'Zucchini'},
          ],
          'explanation': ''
        },
        {
          'id': 'food_q2',
          'question': 'Sushi originated in which country?',
          'answers': [
            {'id': 'a', 'text': 'China'},
            {'id': 'b', 'text': 'Japan', 'correct': true},
            {'id': 'c', 'text': 'Thailand'},
            {'id': 'd', 'text': 'Vietnam'},
          ],
          'explanation': ''
        },
        {
          'id': 'food_q3',
          'question': 'Which cuisine is most associated with pasta?',
          'answers': [
            {'id': 'a', 'text': 'Italian', 'correct': true},
            {'id': 'b', 'text': 'Greek'},
            {'id': 'c', 'text': 'French'},
            {'id': 'd', 'text': 'Mexican'},
          ],
          'explanation': ''
        },
        {
          'id': 'food_q4',
          'question': 'Which spice is made from dried flower buds?',
          'answers': [
            {'id': 'a', 'text': 'Cumin'},
            {'id': 'b', 'text': 'Clove', 'correct': true},
            {'id': 'c', 'text': 'Paprika'},
            {'id': 'd', 'text': 'Turmeric'},
          ],
          'explanation': ''
        },
        {
          'id': 'food_q5',
          'question': 'Which grain is most commonly used to make bread?',
          'answers': [
            {'id': 'a', 'text': 'Wheat', 'correct': true},
            {'id': 'b', 'text': 'Rice'},
            {'id': 'c', 'text': 'Corn'},
            {'id': 'd', 'text': 'Quinoa'},
          ],
          'explanation': ''
        },
        {
          'id': 'food_q6',
          'question': 'Tofu is primarily made from which ingredient?',
          'answers': [
            {'id': 'a', 'text': 'Soybeans', 'correct': true},
            {'id': 'b', 'text': 'Chickpeas'},
            {'id': 'c', 'text': 'Lentils'},
            {'id': 'd', 'text': 'Peanuts'},
          ],
          'explanation': ''
        },
        {
          'id': 'food_q7',
          'question': 'Which fruit includes the variety Granny Smith?',
          'answers': [
            {'id': 'a', 'text': 'Apple', 'correct': true},
            {'id': 'b', 'text': 'Pear'},
            {'id': 'c', 'text': 'Peach'},
            {'id': 'd', 'text': 'Plum'},
          ],
          'explanation': ''
        },
        {
          'id': 'food_q8',
          'question': 'Paella is a traditional dish from which country?',
          'answers': [
            {'id': 'a', 'text': 'Spain', 'correct': true},
            {'id': 'b', 'text': 'Portugal'},
            {'id': 'c', 'text': 'Italy'},
            {'id': 'd', 'text': 'Greece'},
          ],
          'explanation': ''
        },
        {
          'id': 'food_q9',
          'question': 'What is the name of the flatbread used for tacos?',
          'answers': [
            {'id': 'a', 'text': 'Tortilla', 'correct': true},
            {'id': 'b', 'text': 'Naan'},
            {'id': 'c', 'text': 'Pita'},
            {'id': 'd', 'text': 'Lavash'},
          ],
          'explanation': ''
        },
        {
          'id': 'food_q10',
          'question': 'Which dairy product is made by curdling milk?',
          'answers': [
            {'id': 'a', 'text': 'Cheese', 'correct': true},
            {'id': 'b', 'text': 'Butter'},
            {'id': 'c', 'text': 'Ice cream'},
            {'id': 'd', 'text': 'Yogurt'},
          ],
          'explanation': ''
        },
      ]
    },
    'pack_animals': {
      'categoryId': 'animals',
      'version': 1,
      'questions': [
        {
          'id': 'animals_q1',
          'question': 'Which animal is known as the largest land mammal?',
          'answers': [
            {'id': 'a', 'text': 'Elephant', 'correct': true},
            {'id': 'b', 'text': 'Giraffe'},
            {'id': 'c', 'text': 'Hippopotamus'},
            {'id': 'd', 'text': 'Rhinoceros'},
          ],
          'explanation': ''
        },
        {
          'id': 'animals_q2',
          'question': 'What do you call a baby cat?',
          'answers': [
            {'id': 'a', 'text': 'Pup'},
            {'id': 'b', 'text': 'Cub'},
            {'id': 'c', 'text': 'Kitten', 'correct': true},
            {'id': 'd', 'text': 'Foal'},
          ],
          'explanation': ''
        },
        {
          'id': 'animals_q3',
          'question': 'Which bird is famous for its ability to mimic human speech?',
          'answers': [
            {'id': 'a', 'text': 'Parrot', 'correct': true},
            {'id': 'b', 'text': 'Eagle'},
            {'id': 'c', 'text': 'Penguin'},
            {'id': 'd', 'text': 'Owl'},
          ],
          'explanation': ''
        },
        {
          'id': 'animals_q4',
          'question': 'Which animal is the fastest land mammal?',
          'answers': [
            {'id': 'a', 'text': 'Cheetah', 'correct': true},
            {'id': 'b', 'text': 'Lion'},
            {'id': 'c', 'text': 'Horse'},
            {'id': 'd', 'text': 'Gazelle'},
          ],
          'explanation': ''
        },
        {
          'id': 'animals_q5',
          'question': 'Which animal is known for changing its color to blend with surroundings?',
          'answers': [
            {'id': 'a', 'text': 'Chameleon', 'correct': true},
            {'id': 'b', 'text': 'Iguana'},
            {'id': 'c', 'text': 'Gecko'},
            {'id': 'd', 'text': 'Salamander'},
          ],
          'explanation': ''
        },
        {
          'id': 'animals_q6',
          'question': 'What do pandas mainly eat?',
          'answers': [
            {'id': 'a', 'text': 'Bamboo', 'correct': true},
            {'id': 'b', 'text': 'Fish'},
            {'id': 'c', 'text': 'Insects'},
            {'id': 'd', 'text': 'Fruit'},
          ],
          'explanation': ''
        },
        {
          'id': 'animals_q7',
          'question': 'Which animal is known for its black-and-white stripes?',
          'answers': [
            {'id': 'a', 'text': 'Zebra', 'correct': true},
            {'id': 'b', 'text': 'Skunk'},
            {'id': 'c', 'text': 'Badger'},
            {'id': 'd', 'text': 'Okapi'},
          ],
          'explanation': ''
        },
        {
          'id': 'animals_q8',
          'question': 'Which sea creature has eight arms?',
          'answers': [
            {'id': 'a', 'text': 'Octopus', 'correct': true},
            {'id': 'b', 'text': 'Squid'},
            {'id': 'c', 'text': 'Crab'},
            {'id': 'd', 'text': 'Starfish'},
          ],
          'explanation': ''
        },
        {
          'id': 'animals_q9',
          'question': 'What is the largest species of shark?',
          'answers': [
            {'id': 'a', 'text': 'Great white shark'},
            {'id': 'b', 'text': 'Whale shark', 'correct': true},
            {'id': 'c', 'text': 'Tiger shark'},
            {'id': 'd', 'text': 'Hammerhead shark'},
          ],
          'explanation': ''
        },
        {
          'id': 'animals_q10',
          'question': 'Which animal is known for building dams?',
          'answers': [
            {'id': 'a', 'text': 'Beaver', 'correct': true},
            {'id': 'b', 'text': 'Otter'},
            {'id': 'c', 'text': 'Badger'},
            {'id': 'd', 'text': 'Marmot'},
          ],
          'explanation': ''
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
        {
          'id': 'history_q3',
          'question': 'Who was the first President of the United States?',
          'answers': [
            {'id': 'a', 'text': 'George Washington', 'correct': true},
            {'id': 'b', 'text': 'Thomas Jefferson'},
            {'id': 'c', 'text': 'John Adams'},
            {'id': 'd', 'text': 'James Madison'},
          ],
          'explanation': 'George Washington was the first U.S. President.'
        },
        {
          'id': 'history_q4',
          'question': 'The Great Wall is located in which country?',
          'answers': [
            {'id': 'a', 'text': 'China', 'correct': true},
            {'id': 'b', 'text': 'India'},
            {'id': 'c', 'text': 'Japan'},
            {'id': 'd', 'text': 'Mongolia'},
          ],
          'explanation': 'The Great Wall is in China.'
        },
        {
          'id': 'history_q5',
          'question': 'Which war was fought between the North and South regions in the United States?',
          'answers': [
            {'id': 'a', 'text': 'American Civil War', 'correct': true},
            {'id': 'b', 'text': 'Revolutionary War'},
            {'id': 'c', 'text': 'World War I'},
            {'id': 'd', 'text': 'War of 1812'},
          ],
          'explanation': 'The American Civil War was fought between North and South.'
        },
        {
          'id': 'history_q6',
          'question': 'Who was known as the Maid of Orléans?',
          'answers': [
            {'id': 'a', 'text': 'Joan of Arc', 'correct': true},
            {'id': 'b', 'text': 'Catherine de Medici'},
            {'id': 'c', 'text': 'Cleopatra'},
            {'id': 'd', 'text': 'Eleanor of Aquitaine'},
          ],
          'explanation': 'Joan of Arc was called the Maid of Orléans.'
        },
        {
          'id': 'history_q7',
          'question': 'The ancient city of Rome was built on how many hills?',
          'answers': [
            {'id': 'a', 'text': 'Seven', 'correct': true},
            {'id': 'b', 'text': 'Five'},
            {'id': 'c', 'text': 'Three'},
            {'id': 'd', 'text': 'Nine'},
          ],
          'explanation': 'Rome is famous for its seven hills.'
        },
        {
          'id': 'history_q8',
          'question': 'Which empire was ruled by Genghis Khan?',
          'answers': [
            {'id': 'a', 'text': 'Mongol Empire', 'correct': true},
            {'id': 'b', 'text': 'Ottoman Empire'},
            {'id': 'c', 'text': 'Roman Empire'},
            {'id': 'd', 'text': 'British Empire'},
          ],
          'explanation': 'Genghis Khan founded the Mongol Empire.'
        },
        {
          'id': 'history_q9',
          'question': 'What year did World War II end?',
          'answers': [
            {'id': 'a', 'text': '1945', 'correct': true},
            {'id': 'b', 'text': '1939'},
            {'id': 'c', 'text': '1942'},
            {'id': 'd', 'text': '1950'},
          ],
          'explanation': 'World War II ended in 1945.'
        },
        {
          'id': 'history_q10',
          'question': 'Which civilization built Machu Picchu?',
          'answers': [
            {'id': 'a', 'text': 'The Inca', 'correct': true},
            {'id': 'b', 'text': 'The Maya'},
            {'id': 'c', 'text': 'The Aztecs'},
            {'id': 'd', 'text': 'The Olmec'},
          ],
          'explanation': 'Machu Picchu was built by the Inca.'
        },
        {
          'id': 'history_q11',
          'question': 'The Cold War was primarily between which two countries?',
          'answers': [
            {'id': 'a', 'text': 'United States and Soviet Union', 'correct': true},
            {'id': 'b', 'text': 'United States and Germany'},
            {'id': 'c', 'text': 'China and Japan'},
            {'id': 'd', 'text': 'France and Britain'},
          ],
          'explanation': 'The U.S. and Soviet Union were the main rivals.'
        },
        {
          'id': 'history_q12',
          'question': 'Who wrote the Declaration of Independence?',
          'answers': [
            {'id': 'a', 'text': 'Thomas Jefferson', 'correct': true},
            {'id': 'b', 'text': 'Benjamin Franklin'},
            {'id': 'c', 'text': 'Alexander Hamilton'},
            {'id': 'd', 'text': 'John Hancock'},
          ],
          'explanation': 'Thomas Jefferson was the principal author.'
        },
        {
          'id': 'history_q13',
          'question': 'Which ancient civilization is known for cuneiform writing?',
          'answers': [
            {'id': 'a', 'text': 'Sumerians', 'correct': true},
            {'id': 'b', 'text': 'Romans'},
            {'id': 'c', 'text': 'Greeks'},
            {'id': 'd', 'text': 'Phoenicians'},
          ],
          'explanation': 'Cuneiform originated in Sumer.'
        },
        {
          'id': 'history_q14',
          'question': 'The Berlin Wall fell in which year?',
          'answers': [
            {'id': 'a', 'text': '1989', 'correct': true},
            {'id': 'b', 'text': '1979'},
            {'id': 'c', 'text': '1999'},
            {'id': 'd', 'text': '1991'},
          ],
          'explanation': 'The Berlin Wall fell in 1989.'
        },
        {
          'id': 'history_q15',
          'question': 'Which ship carried the Pilgrims to North America in 1620?',
          'answers': [
            {'id': 'a', 'text': 'Mayflower', 'correct': true},
            {'id': 'b', 'text': 'Santa Maria'},
            {'id': 'c', 'text': 'Endeavour'},
            {'id': 'd', 'text': 'Beagle'},
          ],
          'explanation': 'The Pilgrims sailed on the Mayflower.'
        },
        {
          'id': 'history_q16',
          'question': 'Who was the leader of India’s nonviolent independence movement?',
          'answers': [
            {'id': 'a', 'text': 'Mahatma Gandhi', 'correct': true},
            {'id': 'b', 'text': 'Jawaharlal Nehru'},
            {'id': 'c', 'text': 'Subhas Chandra Bose'},
            {'id': 'd', 'text': 'Indira Gandhi'},
          ],
          'explanation': 'Mahatma Gandhi led the nonviolent movement.'
        },
        {
          'id': 'history_q17',
          'question': 'What was the name of the ship on which Charles Darwin sailed?',
          'answers': [
            {'id': 'a', 'text': 'HMS Beagle', 'correct': true},
            {'id': 'b', 'text': 'HMS Victory'},
            {'id': 'c', 'text': 'HMS Endeavour'},
            {'id': 'd', 'text': 'HMS Bounty'},
          ],
          'explanation': 'Darwin sailed on the HMS Beagle.'
        },
        {
          'id': 'history_q18',
          'question': 'Which treaty ended World War I?',
          'answers': [
            {'id': 'a', 'text': 'Treaty of Versailles', 'correct': true},
            {'id': 'b', 'text': 'Treaty of Paris'},
            {'id': 'c', 'text': 'Treaty of Tordesillas'},
            {'id': 'd', 'text': 'Treaty of Utrecht'},
          ],
          'explanation': 'The Treaty of Versailles ended WWI.'
        },
        {
          'id': 'history_q19',
          'question': 'Which civilization built the city of Petra?',
          'answers': [
            {'id': 'a', 'text': 'Nabataeans', 'correct': true},
            {'id': 'b', 'text': 'Romans'},
            {'id': 'c', 'text': 'Persians'},
            {'id': 'd', 'text': 'Egyptians'},
          ],
          'explanation': 'Petra was built by the Nabataeans.'
        },
        {
          'id': 'history_q20',
          'question': 'Who was the British Prime Minister during most of World War II?',
          'answers': [
            {'id': 'a', 'text': 'Winston Churchill', 'correct': true},
            {'id': 'b', 'text': 'Neville Chamberlain'},
            {'id': 'c', 'text': 'Clement Attlee'},
            {'id': 'd', 'text': 'Margaret Thatcher'},
          ],
          'explanation': 'Winston Churchill led Britain during most of WWII.'
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
        {
          'id': 'science_q3',
          'question': 'What gas do plants absorb from the atmosphere?',
          'answers': [
            {'id': 'a', 'text': 'Carbon dioxide', 'correct': true},
            {'id': 'b', 'text': 'Oxygen'},
            {'id': 'c', 'text': 'Nitrogen'},
            {'id': 'd', 'text': 'Helium'},
          ],
          'explanation': 'Plants absorb carbon dioxide for photosynthesis.'
        },
        {
          'id': 'science_q4',
          'question': 'What is the powerhouse of the cell?',
          'answers': [
            {'id': 'a', 'text': 'Mitochondria', 'correct': true},
            {'id': 'b', 'text': 'Nucleus'},
            {'id': 'c', 'text': 'Ribosome'},
            {'id': 'd', 'text': 'Chloroplast'},
          ],
          'explanation': 'Mitochondria produce cellular energy.'
        },
        {
          'id': 'science_q5',
          'question': 'Which planet is known as the Red Planet?',
          'answers': [
            {'id': 'a', 'text': 'Mars', 'correct': true},
            {'id': 'b', 'text': 'Jupiter'},
            {'id': 'c', 'text': 'Venus'},
            {'id': 'd', 'text': 'Mercury'},
          ],
          'explanation': 'Mars is called the Red Planet.'
        },
        {
          'id': 'science_q6',
          'question': 'What force keeps planets in orbit around the sun?',
          'answers': [
            {'id': 'a', 'text': 'Gravity', 'correct': true},
            {'id': 'b', 'text': 'Magnetism'},
            {'id': 'c', 'text': 'Friction'},
            {'id': 'd', 'text': 'Radiation'},
          ],
          'explanation': 'Gravity keeps planets in orbit.'
        },
        {
          'id': 'science_q7',
          'question': 'Which element has the chemical symbol “O”?',
          'answers': [
            {'id': 'a', 'text': 'Oxygen', 'correct': true},
            {'id': 'b', 'text': 'Gold'},
            {'id': 'c', 'text': 'Osmium'},
            {'id': 'd', 'text': 'Oganesson'},
          ],
          'explanation': 'O is the symbol for oxygen.'
        },
        {
          'id': 'science_q8',
          'question': 'What is the boiling point of water at sea level (in °C)?',
          'answers': [
            {'id': 'a', 'text': '100', 'correct': true},
            {'id': 'b', 'text': '90'},
            {'id': 'c', 'text': '80'},
            {'id': 'd', 'text': '110'},
          ],
          'explanation': 'Water boils at 100°C at sea level.'
        },
        {
          'id': 'science_q9',
          'question': 'Which organ pumps blood through the human body?',
          'answers': [
            {'id': 'a', 'text': 'Heart', 'correct': true},
            {'id': 'b', 'text': 'Lungs'},
            {'id': 'c', 'text': 'Liver'},
            {'id': 'd', 'text': 'Kidneys'},
          ],
          'explanation': 'The heart pumps blood.'
        },
        {
          'id': 'science_q10',
          'question': 'What is the primary gas in Earth’s atmosphere?',
          'answers': [
            {'id': 'a', 'text': 'Nitrogen', 'correct': true},
            {'id': 'b', 'text': 'Oxygen'},
            {'id': 'c', 'text': 'Carbon dioxide'},
            {'id': 'd', 'text': 'Hydrogen'},
          ],
          'explanation': 'Nitrogen makes up about 78% of the atmosphere.'
        },
        {
          'id': 'science_q11',
          'question': 'What part of the atom has a negative charge?',
          'answers': [
            {'id': 'a', 'text': 'Electron', 'correct': true},
            {'id': 'b', 'text': 'Proton'},
            {'id': 'c', 'text': 'Neutron'},
            {'id': 'd', 'text': 'Nucleus'},
          ],
          'explanation': 'Electrons carry a negative charge.'
        },
        {
          'id': 'science_q12',
          'question': 'What is the process by which plants make food?',
          'answers': [
            {'id': 'a', 'text': 'Photosynthesis', 'correct': true},
            {'id': 'b', 'text': 'Respiration'},
            {'id': 'c', 'text': 'Fermentation'},
            {'id': 'd', 'text': 'Transpiration'},
          ],
          'explanation': 'Plants use photosynthesis to make food.'
        },
        {
          'id': 'science_q13',
          'question': 'Which planet is the largest in our solar system?',
          'answers': [
            {'id': 'a', 'text': 'Jupiter', 'correct': true},
            {'id': 'b', 'text': 'Saturn'},
            {'id': 'c', 'text': 'Neptune'},
            {'id': 'd', 'text': 'Earth'},
          ],
          'explanation': 'Jupiter is the largest planet.'
        },
        {
          'id': 'science_q14',
          'question': 'Which blood type is known as the universal donor?',
          'answers': [
            {'id': 'a', 'text': 'O negative', 'correct': true},
            {'id': 'b', 'text': 'AB positive'},
            {'id': 'c', 'text': 'A positive'},
            {'id': 'd', 'text': 'B negative'},
          ],
          'explanation': 'O negative is considered the universal donor.'
        },
        {
          'id': 'science_q15',
          'question': 'What is the hardest natural substance on Earth?',
          'answers': [
            {'id': 'a', 'text': 'Diamond', 'correct': true},
            {'id': 'b', 'text': 'Quartz'},
            {'id': 'c', 'text': 'Granite'},
            {'id': 'd', 'text': 'Steel'},
          ],
          'explanation': 'Diamond is the hardest natural substance.'
        },
        {
          'id': 'science_q16',
          'question': 'Which vitamin is produced when skin is exposed to sunlight?',
          'answers': [
            {'id': 'a', 'text': 'Vitamin D', 'correct': true},
            {'id': 'b', 'text': 'Vitamin C'},
            {'id': 'c', 'text': 'Vitamin A'},
            {'id': 'd', 'text': 'Vitamin B12'},
          ],
          'explanation': 'Sunlight triggers vitamin D production.'
        },
        {
          'id': 'science_q17',
          'question': 'What is the basic unit of life?',
          'answers': [
            {'id': 'a', 'text': 'Cell', 'correct': true},
            {'id': 'b', 'text': 'Tissue'},
            {'id': 'c', 'text': 'Organ'},
            {'id': 'd', 'text': 'Organism'},
          ],
          'explanation': 'The cell is the basic unit of life.'
        },
        {
          'id': 'science_q18',
          'question': 'What kind of energy does a moving object have?',
          'answers': [
            {'id': 'a', 'text': 'Kinetic energy', 'correct': true},
            {'id': 'b', 'text': 'Potential energy'},
            {'id': 'c', 'text': 'Thermal energy'},
            {'id': 'd', 'text': 'Chemical energy'},
          ],
          'explanation': 'Energy of motion is kinetic energy.'
        },
        {
          'id': 'science_q19',
          'question': 'Which layer of Earth is liquid?',
          'answers': [
            {'id': 'a', 'text': 'Outer core', 'correct': true},
            {'id': 'b', 'text': 'Inner core'},
            {'id': 'c', 'text': 'Mantle'},
            {'id': 'd', 'text': 'Crust'},
          ],
          'explanation': 'The outer core is liquid.'
        },
        {
          'id': 'science_q20',
          'question': 'What is the closest star to Earth?',
          'answers': [
            {'id': 'a', 'text': 'The Sun', 'correct': true},
            {'id': 'b', 'text': 'Proxima Centauri'},
            {'id': 'c', 'text': 'Sirius'},
            {'id': 'd', 'text': 'Vega'},
          ],
          'explanation': 'The Sun is the closest star to Earth.'
        },
      ]
    },
    'challenge_featured_global_01': {
      'id': 'featured_global_01',
      'title': 'Featured Duel: World Wonders',
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
    'challenge_featured_speed_02': {
      'id': 'featured_speed_02',
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
    'challenge_featured_tech_14': {
      'id': 'featured_tech_14',
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
    'challenge_featured_sports_11': {
      'id': 'featured_sports_11',
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
    'challenge_featured_pop_09': {
      'id': 'featured_pop_09',
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
