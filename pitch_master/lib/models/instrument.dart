class Instrument {
  final String name;
  final List<String> strings;

  const Instrument({required this.name, required this.strings});
}

// Strumenti predefiniti
const List<Instrument> defaultInstruments = [
  Instrument(
    name: 'Chitarra',
    strings: ['Mi2', 'La2', 'Re3', 'Sol3', 'Si3', 'Mi4'],
  ),
  Instrument(
    name: 'Basso',
    strings: ['Mi1', 'La1', 'Re2', 'Sol2'],
  ),
  Instrument(
    name: 'Ukulele',
    strings: ['Sol4', 'Do4', 'Mi4', 'La4'],
  ),
];

// Frequenze in Hz per ogni nota
const Map<String, double> noteFrequencies = {
  'Mi1': 41.20,
  'La1': 55.00,
  'Re2': 73.42,
  'Sol2': 98.00,
  'Mi2': 82.41,
  'La2': 110.00,
  'Re3': 146.83,
  'Sol3': 196.00,
  'Si3': 246.94,
  'Mi4': 329.63,
  'Sol4': 392.00,
  'Do4': 261.63,
  'La4': 440.00,
};
