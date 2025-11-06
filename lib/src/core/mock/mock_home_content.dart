import '../models/movi_media.dart';
import '../models/movi_person.dart';

class HomeHeroData {
  const HomeHeroData({
    required this.media,
    required this.backgroundImage,
    required this.logoImage,
    required this.duration,
    required this.synopsis,
  });

  final MoviMovie media;
  final String backgroundImage;
  final String logoImage;
  final String duration;
  final String synopsis;
}

class MockHomeContent {
  const MockHomeContent._();

  static final HomeHeroData hero = HomeHeroData(
    media: MoviMovie(
      id: 'hero-movie',
      title: 'Galactic Horizon',
      poster:
          'https://images.unsplash.com/photo-1524985069026-dd778a71c7b4?auto=format&fit=crop&w=1200&q=80',
      year: '2024',
      rating: '9.2',
    ),
    backgroundImage:
        'https://images.unsplash.com/photo-1517602302552-471fe67acf66?auto=format&fit=crop&w=1600&q=80',
    logoImage:
        'https://image.tmdb.org/t/p/original/qvvZE6tuhapSynJAJVZLqE7YO7u.png',
    duration: '2h 18m',
    synopsis:
        'Alors qu’une archéologue découvre une porte stellaire oubliée, un équipage hétéroclite doit empêcher une menace cosmique de ravager la galaxie.',
  );

  static final List<MoviMovie> knownMovies = [
    MoviMovie(
      id: 'movie-a',
      title: 'Neon Horizon',
      poster:
          'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=600&q=80',
      year: '2022',
      rating: '8.4',
    ),
    MoviMovie(
      id: 'movie-b',
      title: 'Midnight Echoes',
      poster:
          'https://images.unsplash.com/photo-1497032628192-86f99bcd76bc?auto=format&fit=crop&w=600&q=80',
      year: '2021',
      rating: '7.9',
    ),
    MoviMovie(
      id: 'movie-c',
      title: 'Fragments of Tomorrow',
      poster:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=600&q=80',
      year: '2020',
      rating: '8.7',
    ),
    MoviMovie(
      id: 'movie-d',
      title: 'Silent Resonance',
      poster:
          'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?auto=format&fit=crop&w=600&q=80',
      year: '2019',
      rating: '8.1',
    ),
  ];

  static final List<MoviPerson> featuredPeople = [
    MoviPerson(
      id: 'person-a',
      name: 'Elena Drake',
      role: 'Capitaine Adiya',
      poster:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=600&q=80',
    ),
    MoviPerson(
      id: 'person-b',
      name: 'Jasper Holt',
      role: 'Ingénieur Lys',
      poster:
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=600&q=80',
    ),
    MoviPerson(
      id: 'person-c',
      name: 'Maya Chen',
      role: 'Docteure Sora',
      poster:
          'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=600&q=80',
    ),
    MoviPerson(
      id: 'person-d',
      name: 'Noah Karim',
      role: 'Pilote Idris',
      poster:
          'https://images.unsplash.com/photo-1520813792240-56fc4a3765a7?auto=format&fit=crop&w=600&q=80',
    ),
  ];
}

