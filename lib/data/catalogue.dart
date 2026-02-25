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
  ),
  Book(
    id: 'pride-and-prejudice',
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    year: 1813,
    blurb: "It is a truth universally acknowledged… Austen's sharp wit and devastating social observation make this the definitive comedy of manners — and one of the greatest love stories ever written.",
    price: 'FREE',
    isFree: true,
    hasChunks: false,
    cover: 'pride-and-prejudice',
    sections: ['Free Books', 'New'],
  ),
  Book(
    id: 'jane-eyre',
    title: 'Jane Eyre',
    author: 'Charlotte Brontë',
    year: 1847,
    blurb: "An orphaned governess finds independence, love, and terrifying secrets at Thornfield Hall. A fierce, deeply personal story of identity and self-respect that shook Victorian society.",
    price: 'FREE',
    isFree: true,
    hasChunks: false,
    cover: 'jane-eyre',
    sections: ['Free Books', 'Trending'],
  ),
  Book(
    id: 'don-quixote',
    title: 'Don Quixote',
    author: 'Miguel de Cervantes',
    year: 1605,
    blurb: "The world's first novel. A man driven mad by chivalric romances tilts at windmills, rescues damsels, and inadvertently invents modern fiction — while making us question reality itself.",
    price: 'FREE',
    isFree: true,
    hasChunks: false,
    cover: 'don-quixote',
    sections: ['Free Books', 'New'],
  ),
  Book(
    id: 'great-gatsby',
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    year: 1925,
    blurb: "Green light, old sport. Jazz Age excess and lost illusions on Long Island Sound. The definitive portrait of the American Dream — and its gorgeous, inevitable collapse.",
    price: 'FREE',
    isFree: true,
    hasChunks: false,
    cover: 'great-gatsby',
    sections: ['New', 'Trending'],
  ),
  Book(
    id: 'frankenstein',
    title: 'Frankenstein',
    author: 'Mary Shelley',
    year: 1818,
    blurb: "The modern Prometheus. A young scientist creates life and cannot live with what he has made. The founding text of science fiction, and still its most haunting moral question.",
    price: 'FREE',
    isFree: true,
    hasChunks: false,
    cover: 'frankenstein',
    sections: ['Free Books', 'Trending'],
  ),
];

Book? getBookById(String id) {
  final matches = catalogue.where((b) => b.id == id);
  return matches.isEmpty ? null : matches.first;
}

const Map<String, List<Color>> coverGradients = {
  'moby-dick':           [Color(0xFF1A3A5C), Color(0xFF2E7D9A)],
  'pride-and-prejudice': [Color(0xFF8B5E6E), Color(0xFF5E7B6A)],
  'jane-eyre':           [Color(0xFF3D2B4E), Color(0xFF7A6070)],
  'don-quixote':         [Color(0xFF8B4513), Color(0xFFC4956A)],
  'great-gatsby':        [Color(0xFFB8952A), Color(0xFF2C4A3E)],
  'frankenstein':        [Color(0xFF1A3322), Color(0xFF4A5568)],
};
