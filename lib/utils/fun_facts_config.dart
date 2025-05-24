// Fun Facts API Configuration
// Easy configuration for different fun facts APIs

class FunFactsConfig {
  // Available Fun Facts APIs
  static const Map<String, Map<String, dynamic>> availableAPIs = {
    'useless_facts': {
      'name': 'Useless Facts API',
      'url': 'https://uselessfacts.jsph.pl/random.json?language=en',
      'method': 'GET',
      'headers': {'Accept': 'application/json'},
      'responseKey': 'text',
      'requiresKey': false,
      'description': 'Random interesting facts, completely free'
    },
    'numbers_api': {
      'name': 'Numbers API',
      'url': 'http://numbersapi.com/random/trivia',
      'method': 'GET',
      'headers': {'Accept': 'text/plain'},
      'responseKey': null, // Plain text response
      'requiresKey': false,
      'description': 'Interesting trivia about numbers'
    },
    'cat_facts': {
      'name': 'Cat Facts API',
      'url': 'https://catfact.ninja/fact',
      'method': 'GET',
      'headers': {'Accept': 'application/json'},
      'responseKey': 'fact',
      'requiresKey': false,
      'description': 'Fun facts about cats'
    },
    'dog_facts': {
      'name': 'Dog Facts API',
      'url': 'https://dog-api.kinduff.com/api/facts',
      'method': 'GET',
      'headers': {'Accept': 'application/json'},
      'responseKey': 'facts',
      'requiresKey': false,
      'description': 'Fun facts about dogs (returns array)'
    },
    'rest_countries': {
      'name': 'REST Countries API',
      'url':
          'https://restcountries.com/v3.1/all?fields=name,capital,flag,population,region',
      'method': 'GET',
      'headers': {'Accept': 'application/json'},
      'responseKey': null, // Custom processing needed
      'requiresKey': false,
      'description': 'Information about countries with flag emojis'
    },
    'jokes_api': {
      'name': 'JokeAPI (Safe)',
      'url':
          'https://v2.jokeapi.dev/joke/Programming,Miscellaneous,Pun?blacklistFlags=nsfw,religious,political,racist,sexist,explicit&type=single',
      'method': 'GET',
      'headers': {'Accept': 'application/json'},
      'responseKey': 'joke',
      'requiresKey': false,
      'description': 'Clean, kid-friendly jokes'
    },
    'advice_slip': {
      'name': 'Advice Slip API',
      'url': 'https://api.adviceslip.com/advice',
      'method': 'GET',
      'headers': {'Accept': 'application/json'},
      'responseKey': 'slip.advice',
      'requiresKey': false,
      'description': 'Random advice (may need filtering for kids)'
    }
  };

  // APIs that require API keys (user needs to get their own)
  static const Map<String, Map<String, dynamic>> premiumAPIs = {
    'openweather': {
      'name': 'OpenWeatherMap API',
      'url': 'https://api.openweathermap.org/data/2.5/weather',
      'method': 'GET',
      'requiresKey': true,
      'keyParam': 'appid',
      'description': 'Weather data with city information'
    },
    'unsplash': {
      'name': 'Unsplash API',
      'url': 'https://api.unsplash.com/photos/random',
      'method': 'GET',
      'requiresKey': true,
      'keyParam': 'client_id',
      'description': 'Beautiful city and nature photos'
    },
    'pixabay': {
      'name': 'Pixabay API',
      'url': 'https://pixabay.com/api/',
      'method': 'GET',
      'requiresKey': true,
      'keyParam': 'key',
      'description': 'Free images including cities and educational content'
    },
    'ninja_facts': {
      'name': 'API Ninjas Facts',
      'url': 'https://api.api-ninjas.com/v1/facts',
      'method': 'GET',
      'requiresKey': true,
      'keyParam': 'X-Api-Key', // Header
      'description': 'Various interesting facts'
    }
  };

  // Kid-friendly backup facts
  static const List<String> backupFacts = [
    "Did you know? A group of flamingos is called a 'flamboyance'! 🦩",
    "Did you know? Octopuses have three hearts! 🐙",
    "Did you know? Bananas are berries, but strawberries aren't! 🍌",
    "Did you know? A single cloud can weigh more than a million pounds! ☁️",
    "Did you know? Honey never spoils - archaeologists have found edible honey that's thousands of years old! 🍯",
    "Did you know? Dolphins have names for each other! 🐬",
    "Did you know? A shrimp's heart is in its head! 🦐",
    "Did you know? Butterflies taste with their feet! 🦋",
    "Did you know? Elephants can't jump! 🐘",
    "Did you know? A day on Venus is longer than its year! 🪐",
    "Did you know? Wombat poop is cube-shaped! 🐨",
    "Did you know? Seahorses are the only animals where the male gives birth! 🌊",
    "Did you know? A group of pandas is called an 'embarrassment'! 🐼",
    "Did you know? Penguins have a gland above their eyes that filters salt from seawater! 🐧",
    "Did you know? The longest word in English has 189,819 letters! 📚",
    "Did you know? Your nose can remember 50,000 different scents! 👃",
    "Did you know? Blue whales' hearts are as big as a small car! 🐋",
    "Did you know? Sloths only poop once a week! 🦥",
    "Did you know? A baby octopus is about the size of a flea when it's born! 🐙",
    "Did you know? Koalas have fingerprints just like humans! 🐨"
  ];

  // Kid-friendly city facts
  static const List<String> backupCityFacts = [
    "Did you know? 🗼 The Eiffel Tower in Paris can be 15 cm taller in summer due to metal expansion!",
    "Did you know? 🏺 Rome has more fountains than any other city in the world - over 2,000!",
    "Did you know? 🌉 San Francisco's Golden Gate Bridge is painted continuously to prevent rust!",
    "Did you know? 🗽 New York City has over 8 million people from all around the world!",
    "Did you know? 🏔️ La Paz, Bolivia is the highest capital city in the world at 3,500 meters above sea level!",
    "Did you know? 🌸 Tokyo has the busiest pedestrian crossing in the world - Shibuya Crossing!",
    "Did you know? 🏰 London has 32 boroughs and the Thames flows through it for 215 miles!",
    "Did you know? 🕌 Istanbul is the only city that sits on two continents - Europe and Asia!",
    "Did you know? 🎭 Venice has 417 bridges connecting its 118 small islands!",
    "Did you know? 🏛️ Athens is one of the world's oldest cities, with recorded history spanning 3,400 years!",
    "Did you know? 🌵 Phoenix, Arizona, is the hottest major city in the United States!",
    "Did you know? ❄️ Reykjavik, Iceland, is the world's northernmost capital city!",
    "Did you know? 🏖️ Miami Beach was built on a man-made island!",
    "Did you know? 🏔️ Denver is called the 'Mile High City' because it's exactly 5,280 feet above sea level!",
    "Did you know? 🎪 Las Vegas has more hotel rooms than any other city in the world!"
  ];

  // Instructions for users who want to add their own API
  static const String userAPIInstructions = '''
To add your own Fun Facts API:

1. Choose an API from the available free options:
   - Useless Facts API (already implemented)
   - Numbers API  
   - Cat Facts API
   - Dog Facts API
   - REST Countries API
   - JokeAPI (Safe mode)

2. For APIs requiring keys, get your free API key from:
   - OpenWeatherMap: https://openweathermap.org/api
   - Unsplash: https://unsplash.com/developers
   - Pixabay: https://pixabay.com/api/docs/
   - API Ninjas: https://api.api-ninjas.com/

3. Update the configuration and provide your API key in the app settings.

4. Test the API to ensure it returns kid-friendly content!
''';
}
