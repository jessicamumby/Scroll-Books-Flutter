import 'package:flutter/material.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final int year;
  final String blurb;
  final String price;
  final bool isFree;
  final bool hasChunks;
  final String cover;
  final List<String> sections;
  final List<String> genres;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.year,
    required this.blurb,
    required this.price,
    required this.isFree,
    required this.hasChunks,
    required this.cover,
    required this.sections,
    required this.genres,
  });
}

const List<Book> catalogue = [
  Book(
    id: 'moby-dick',
    title: 'Moby Dick',
    author: 'Herman Melville',
    year: 1851,
    blurb: "Call me Ishmael. An obsessive sea captain pursues a great white whale across the world's oceans in this monumental American epic of obsession, fate, and the sublime terror of nature.",
    price: 'FREE',
    isFree: true,
    hasChunks: true,
    cover: 'moby-dick',
    sections: ['Free Books', 'Trending'],
    genres: ['Adventure', 'Gothic'],
  ),
  Book(
    id: 'pride-and-prejudice',
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    year: 1813,
    blurb: "It is a truth universally acknowledged… Austen's sharp wit and devastating social observation make this the definitive comedy of manners — and one of the greatest love stories ever written.",
    price: 'FREE',
    isFree: true,
    hasChunks: true,
    cover: 'pride-and-prejudice',
    sections: ['Free Books', 'New'],
    genres: ['Romance'],
  ),
  Book(
    id: 'great-gatsby',
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    year: 1925,
    blurb: "Green light, old sport. Jazz Age excess and lost illusions on Long Island Sound. The definitive portrait of the American Dream — and its gorgeous, inevitable collapse.",
    price: 'FREE',
    isFree: true,
    hasChunks: true,
    cover: 'great-gatsby',
    sections: ['New', 'Trending'],
    genres: ['Satire'],
  ),
  Book(
    id: 'frankenstein',
    title: 'Frankenstein',
    author: 'Mary Shelley',
    year: 1818,
    blurb: "The modern Prometheus. A young scientist creates life and cannot live with what he has made. The founding text of science fiction, and still its most haunting moral question.",
    price: 'FREE',
    isFree: true,
    hasChunks: true,
    cover: 'frankenstein',
    sections: ['Free Books', 'Trending'],
    genres: ['Gothic', 'Sci-Fi'],
  ),
  Book(
    id: 'romeo-and-juliet',
    title: 'Romeo & Juliet',
    author: 'William Shakespeare',
    year: 1597,
    blurb: "Star-crossed lovers. Two young people from warring Veronese families fall desperately in love, setting in motion an unstoppable tragedy. Shakespeare's most celebrated romance — and his most heartbreaking.",
    price: 'FREE',
    isFree: true,
    hasChunks: true,
    cover: 'romeo-and-juliet',
    sections: ['Free Books', 'Trending'],
    genres: ['Romance', 'Tragedy'],
  ),
  Book(
    id: 'wuthering-heights',
    title: 'Wuthering Heights',
    author: 'Emily Brontë',
    year: 1847,
    blurb: "Wild and elemental. An orphan raised on the Yorkshire moors returns as a brooding, vengeful figure, his obsessive love for Cathy undiminished by time or cruelty. Emily Brontë's haunting tale of passion on the windswept moors.",
    price: 'FREE',
    isFree: true,
    hasChunks: true,
    cover: 'wuthering-heights',
    sections: ['Free Books', 'New'],
    genres: ['Gothic', 'Romance'],
  ),
];

Book? getBookById(String id) {
  final matches = catalogue.where((b) => b.id == id);
  return matches.isEmpty ? null : matches.first;
}

const Map<String, List<Color>> coverGradients = {
  'moby-dick':           [Color(0xFF1A3A5C), Color(0xFF2E7D9A)],
  'pride-and-prejudice': [Color(0xFF8B5E6E), Color(0xFF5E7B6A)],
  'great-gatsby':        [Color(0xFFB8952A), Color(0xFF2C4A3E)],
  'frankenstein':        [Color(0xFF1A3322), Color(0xFF4A5568)],
  'romeo-and-juliet':    [Color(0xFF8B1A2A), Color(0xFFC47080)],
  'wuthering-heights':   [Color(0xFF2D1F3D), Color(0xFF5C4A6E)],
};
